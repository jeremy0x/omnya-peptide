import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/compound_directory.dart';
import '../../domain/schedule.dart';
import '../repositories/protocol_repository.dart';

/// iOS-only features in ios/Runner/AppDelegate.swift. Every call runs on the phone and
/// returns null where the platform can't answer (Android, tests, no permission).
class NativeService {
  static const _channel = MethodChannel('omnya/native');

  static Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on Exception catch (e) {
      debugPrint('Native $method failed: $e');
      return null;
    }
  }

  /// Latest weight from Apple Health.
  static Future<({double lbs, DateTime at})?> latestWeight() async {
    final r = await _call<Map<Object?, Object?>>('latestWeightLbs');
    if (r == null) return null;
    return (lbs: (r['lbs']! as num).toDouble(), at: DateTime.fromMillisecondsSinceEpoch((r['at']! as num).toInt()));
  }

  /// Face fullness and skin evenness for a photo, or null when no face is found.
  static Future<({double fullness, double? evenness})?> scorePhoto(String path) async {
    final r = await _call<Map<Object?, Object?>>('scorePhoto', {'path': path});
    if (r == null) return null;
    return (fullness: (r['fullness']! as num).toDouble(), evenness: (r['evenness'] as num?)?.toDouble());
  }

  /// The photo with faces blurred, as JPEG.
  static Future<Uint8List?> blurFaces(String path) => _call<Uint8List>('blurFaces', {'path': path});

  /// Home and lock screen widget data, plus the shot-day Live Activity (null ends it).
  static Future<void> updateWidget(Map<String, Object?> data, Map<String, String>? activity) =>
      _call<void>('updateWidget', {'json': jsonEncode(data), 'activity': activity});
}

/// Writes what the widgets show and starts or ends the shot-day Live Activity.
Future<void> syncWidgets(ProtocolRepository repo) {
  final now = DateTime.now();
  final next = nextUp(repo.compounds, repo.doseLogs);
  final data = <String, Object?>{};
  Map<String, String>? activity;
  if (next != null) {
    final due = nextDueDay(next, repo.doseLogs);
    final minutes = repo.profile?.reminderMinutes ?? 9 * 60;
    final time = DateFormat('h:mm a').format(DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60)).toLowerCase();
    final day = relativeDay(due.isBefore(dayOf(now)) ? dayOf(now) : due, now);
    data['next'] = '${CompoundDirectory.shortName(next.name)}, ${nextDoseLabel(next, repo.doseLogs)}';
    data['when'] = [
      '${day[0].toUpperCase()}${day.substring(1)} $time',
      if (next.isInjected) next.nextSite.toLowerCase(),
    ].join(' · ');
    final runout = runoutDay(next, repo.doseLogs);
    if (runout != null) data['runout'] = 'Vial runs out ${DateFormat('EEE').format(runout)}';
    if (!due.isAfter(dayOf(now))) {
      activity = {
        'compound': CompoundDirectory.shortName(next.name),
        'dose': nextDoseLabel(next, repo.doseLogs),
        'site': next.isInjected ? next.nextSite : '',
      };
    }
  }
  if (repo.doseLogs.isNotEmpty) {
    final first = repo.doseLogs.map((l) => l.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);
    data['day'] = daysBetween(first, now) + 1;
  }
  return NativeService.updateWidget(data, activity);
}
