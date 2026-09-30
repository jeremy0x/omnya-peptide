import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../core/constants/compound_directory.dart';
import '../../domain/outcomes.dart';
import '../../domain/schedule.dart';
import '../repositories/protocol_repository.dart';

class Reminder {
  final DateTime at;
  final String title;
  final String body;

  /// Where a tap opens: 'today', 'week' or 'photo'.
  final String route;
  const Reminder(this.at, this.title, this.body, this.route);
}

/// Every reminder due from [now] on, soonest first. Local only: nothing leaves the phone.
List<Reminder> plannedReminders(ProtocolRepository repo, DateTime now) {
  final profile = repo.profile;
  if (profile == null || !profile.remindersOn) return const [];
  DateTime at(DateTime day, [int? minutes]) {
    final m = minutes ?? profile.reminderMinutes;
    return DateTime(day.year, day.month, day.day, m ~/ 60, m % 60);
  }

  final today = dayOf(now);
  final out = <Reminder>[];
  final logs = repo.doseLogs;

  for (final c in repo.compounds.where((c) => c.isConfigured)) {
    final name = CompoundDirectory.shortName(c.name);
    // An overdue dose gets one nudge today (or tomorrow if the time has passed), then the schedule carries on.
    var due = nextDueDay(c, logs);
    if (due.isBefore(today)) due = at(today).isAfter(now) ? today : addDays(today, 1);
    for (var i = 0; i < 4; i++) {
      final day = addDays(due, i * c.frequencyDays);
      final dose = formatDose(c.doseOn(day), c.unit);
      out.add(
        Reminder(
          at(day),
          "$name's ready when you are",
          c.isInjected ? '$dose · ${c.nextSite.toLowerCase()}' : dose,
          'today',
        ),
      );
    }
    final runout = runoutDay(c, logs);
    if (runout != null) {
      out.add(
        Reminder(
          at(addDays(runout, -2)),
          '$name runs out ${relativeDay(runout, addDays(runout, -2))}',
          'Time to reorder if you plan to keep going.',
          'today',
        ),
      );
    }
    final expires = c.vialExpires;
    if (expires != null) {
      out.add(
        Reminder(at(expires), "$name's mixed vial expires today", 'Mix a fresh vial before your next dose.', 'today'),
      );
    }
  }

  if (logs.isNotEmpty) {
    final first = logs.map((l) => l.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);
    out.add(
      Reminder(
        at(addDays(dayOf(first), outcomeStartDay - 1)),
        'Your first result is ready',
        'See what changed in your first two weeks.',
        'progress',
      ),
    );
  }

  // Sundays: the photo in the morning, the week in the evening.
  final sunday = addDays(today, (DateTime.sunday - today.weekday) % 7);
  for (var w = 0; w < 4; w++) {
    final day = addDays(sunday, w * 7);
    if (profile.sundayPhotoPromptEnabled) {
      out.add(Reminder(at(day, 10 * 60), 'Sunday photo', 'Same spot, same light. It takes a minute.', 'photo'));
    }
    out.add(Reminder(at(day, 18 * 60), 'Your week is in', 'What changed, what\'s due, what to watch.', 'week'));
  }

  // iOS keeps at most 64 pending; the soonest matter most and all are rebuilt on every change.
  return out.where((r) => r.at.isAfter(now)).toList()..sort((a, b) => a.at.compareTo(b.at));
}

/// Schedules [plannedReminders] with the system and routes taps back into the app.
class ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  Timer? _debounce;
  bool _ready = false;

  /// Routes of tapped reminders.
  Stream<String> get taps => _taps.stream;

  static const _details = NotificationDetails(
    iOS: DarwinNotificationDetails(),
    android: AndroidNotificationDetails('reminders', 'Reminders', importance: Importance.high),
  );

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          android: AndroidInitializationSettings('ic_notification'),
        ),
        onDidReceiveNotificationResponse: (r) => _taps.add(r.payload ?? 'today'),
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if (launch?.didNotificationLaunchApp == true && payload != null) {
        // Delivered after the first frame so the app is there to open it.
        Future.delayed(const Duration(seconds: 2), () => _taps.add(payload));
      }
      _ready = true;
    } catch (e) {
      debugPrint('Reminders unavailable: $e');
    }
  }

  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true, badge: false) ??
        await android?.requestNotificationsPermission() ??
        false;
  }

  /// Rebuilds every pending reminder from the current data, a moment after the last change.
  void reschedule(ProtocolRepository repo) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () => _apply(repo));
  }

  Future<void> _apply(ProtocolRepository repo) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final planned = plannedReminders(repo, DateTime.now());
      if (planned.isEmpty) return;
      await requestPermission();
      for (final (i, r) in planned.take(60).indexed) {
        await _plugin.zonedSchedule(
          id: i,
          title: r.title,
          body: r.body,
          payload: r.route,
          scheduledDate: tz.TZDateTime.from(r.at, tz.local),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Scheduling reminders failed: $e');
    }
  }

  /// Shows one right away, so she can see reminders work.
  Future<bool> sendTest() async {
    if (!_ready || !await requestPermission()) return false;
    await _plugin.show(
      id: 999,
      title: 'Reminders are on',
      body: 'This is what a dose reminder looks like.',
      notificationDetails: _details,
      payload: 'today',
    );
    return true;
  }
}
