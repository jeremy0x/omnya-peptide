// Records an end-to-end walkthrough of the app to an MP4, against the in-memory cloud.
// Run: flutter test tool/record_flow_test.dart --dart-define=OUT=/path/to/omnya_flow.mp4
// Needs ffmpeg on the PATH. Every frame is the real widget tree rendered by the test engine.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:omnya/core/theme/omnya_colors.dart';
import 'package:omnya/core/theme/omnya_typography.dart';
import 'package:omnya/core/widgets/omnya_controls.dart';
import 'package:omnya/data/models/circle_data.dart';
import 'package:omnya/data/models/compound.dart';
import 'package:omnya/data/models/daily_check_in.dart';
import 'package:omnya/data/models/dose_log.dart';
import 'package:omnya/data/models/user_profile.dart';
import 'package:omnya/data/repositories/protocol_repository.dart';
import 'package:omnya/domain/schedule.dart';
import 'package:omnya/data/services/subscription_service.dart';
import 'package:omnya/main.dart';
import '../test/fakes.dart';

const _out = String.fromEnvironment('OUT', defaultValue: 'omnya_flow.mp4');
const _fps = 30;
const _frame = Duration(microseconds: 1000000 ~/ _fps);
const _logical = Size(390, 844);
const _scale = 2.0; // output is 780 x 1688

Future<void> _loadFonts() async {
  final families = <String, List<String>>{
    'Fraunces': ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold'].map((w) => 'assets/fonts/Fraunces-$w.ttf').toList(),
    'InstrumentSans': [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ].map((w) => 'assets/fonts/InstrumentSans-$w.ttf').toList(),
  };
  final sdk = '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
  await (FontLoader(
    'packages/cupertino_icons/CupertinoIcons',
  )..addFont(rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'))).load();
  for (final (family, file) in [('Roboto', 'Roboto-Regular.ttf'), ('MaterialIcons', 'MaterialIcons-Regular.otf')]) {
    final f = File('$sdk/$file');
    if (!f.existsSync()) continue;
    final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    await loader.load();
  }
}

/// Pro is switched on partway through, as if she upgraded, so the Pro screens show.
class _DemoSubscriptions extends SubscriptionService {
  _DemoSubscriptions({required super.storage});
  bool pro = false;
  @override
  bool get isPro => pro;
  void upgrade() {
    pro = true;
    notifyListeners();
  }
}

/// Draws a finger dot where the script taps, so the viewer can follow along.
class _Touches extends StatelessWidget {
  final ValueNotifier<Offset?> touch;
  final ValueNotifier<(String, String)?> card;
  final Widget child;
  const _Touches({required this.touch, required this.card, required this.child});

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Stack(
      children: [
        child,
        IgnorePointer(
          child: ValueListenableBuilder<(String, String)?>(
            valueListenable: card,
            builder: (_, c, _) => AnimatedOpacity(
              opacity: c == null ? 0 : 1,
              duration: const Duration(milliseconds: 400),
              child: Container(
                color: OmnyaColors.plum,
                padding: const EdgeInsets.all(32),
                alignment: Alignment.centerLeft,
                child: c == null
                    ? null
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.$1, style: OmnyaTypography.displayLarge(color: OmnyaColors.cream)),
                          const SizedBox(height: 12),
                          Text(c.$2, style: OmnyaTypography.bodyLarge(color: OmnyaColors.sandMuted)),
                        ],
                      ),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: ValueListenableBuilder<Offset?>(
            valueListenable: touch,
            builder: (_, p, _) => p == null
                ? const SizedBox.shrink()
                : Stack(
                    textDirection: TextDirection.ltr,
                    children: [
                      Positioned(
                        left: p.dx - 22,
                        top: p.dy - 22,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    ),
  );
}

class Recorder {
  final WidgetTester tester;
  final GlobalKey boundary;
  final ValueNotifier<Offset?> touch;
  final card = ValueNotifier<(String, String)?>(null);
  late final Process _ffmpeg;
  int frames = 0;

  Recorder(this.tester, this.boundary, this.touch);

  /// A full-screen title card between chapters.
  Future<void> title(String heading, String line, {int ms = 2200, Future<void> Function()? behind}) async {
    card.value = (heading, line);
    await wait(450 + ms);
    if (behind != null) await behind();
    card.value = null;
  }

  Future<void> start() async {
    await tester.runAsync(() async {
      _ffmpeg = await Process.start('ffmpeg', [
        '-y',
        '-loglevel',
        'error',
        '-f',
        'rawvideo',
        '-pix_fmt',
        'rgba',
        '-s',
        '${(_logical.width * _scale).round()}x${(_logical.height * _scale).round()}',
        '-r',
        '$_fps',
        '-i',
        '-',
        '-c:v',
        'libx264',
        '-pix_fmt',
        'yuv420p',
        '-crf',
        '20',
        '-preset',
        'medium',
        '-movflags',
        '+faststart',
        _out,
      ]);
      unawaited(_ffmpeg.stderr.pipe(stderr));
    });
  }

  /// Advances the app by one frame and writes it.
  Future<void> frame() async {
    await tester.pump(_frame);
    await tester.runAsync(() async {
      final ro = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await ro.toImage(pixelRatio: _scale);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      _ffmpeg.stdin.add(bytes!.buffer.asUint8List());
      await _ffmpeg.stdin.flush();
    });
    frames++;
  }

  Future<void> wait(int ms) async {
    for (var i = 0; i < ms * _fps ~/ 1000; i++) {
      await frame();
    }
  }

  Future<void> snapshot(String name) async {
    final dir = Directory('${File(_out).parent.path}/snaps')..createSync(recursive: true);
    await tester.runAsync(() async {
      final ro = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await ro.toImage(pixelRatio: 1);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${dir.path}/${frames.toString().padLeft(5, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> tapAt(Offset p, {int after = 500}) async {
    touch.value = p;
    await wait(200);
    await tester.tapAt(p);
    await wait(120);
    touch.value = null;
    await wait(after);
  }

  Future<void> tap(Finder f, {int after = 500}) async {
    await reveal(f);
    await tapAt(tester.getCenter(f.first), after: after);
  }

  Future<void> tapText(String text, {int after = 500, bool last = false}) =>
      tap(last ? find.text(text).last : find.text(text).first, after: after);

  /// Scrolls with a visible finger drag until [f] is comfortably on screen.
  Future<void> reveal(Finder f) async {
    for (var tries = 0; tries < 8; tries++) {
      final target = f.first;
      if (target.evaluate().isEmpty) return;
      final r = tester.getRect(target);
      final top = 110.0, bottom = _logical.height - 130;
      if (r.top >= top && r.bottom <= bottom) return;
      final scrollable = find.ancestor(of: target, matching: find.byType(Scrollable));
      if (scrollable.evaluate().isEmpty) return;
      final dy = r.bottom > bottom ? -(r.bottom - bottom + 60).clamp(0, 420) : (top - r.top + 60).clamp(0, 420);
      // Already at the end it would scroll toward: it's as visible as it gets, so tap it there.
      final position = tester.state<ScrollableState>(scrollable.first).position;
      if (dy < 0 ? position.pixels >= position.maxScrollExtent : position.pixels <= position.minScrollExtent) return;
      await drag(Offset(_logical.width / 2, dy < 0 ? 620 : 260), dy.toDouble());
      // A drag that moved nothing would only repeat.
      if ((tester.getRect(target).top - r.top).abs() < 4) return;
    }
  }

  Future<void> drag(Offset from, double dy, {int ms = 450}) async {
    final steps = ms * _fps ~/ 1000;
    touch.value = from;
    final g = await tester.startGesture(from);
    await frame();
    for (var i = 1; i <= steps; i++) {
      final t = Curves.easeInOut.transform(i / steps) - Curves.easeInOut.transform((i - 1) / steps);
      await g.moveBy(Offset(0, dy * t));
      touch.value = touch.value! + Offset(0, dy * t);
      await frame();
    }
    await g.up();
    touch.value = null;
    await wait(500);
  }

  Future<void> scroll(double dy, {int ms = 600}) => drag(Offset(_logical.width / 2, dy < 0 ? 680 : 220), dy, ms: ms);

  Future<void> type(Finder field, String text) async {
    await tap(field, after: 200);
    for (var i = 1; i <= text.length; i++) {
      await tester.enterText(field, text.substring(0, i));
      await wait(70);
    }
    await wait(300);
  }

  Future<void> finish() async {
    await tester.runAsync(() async {
      await _ffmpeg.stdin.close();
      await _ffmpeg.exitCode;
    });
  }
}

void main() {
  testWidgets('record the full flow', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    tester.view.physicalSize = _logical * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);

    final repo = await tester.runAsync(() async {
      await _loadFonts();
      return makeRepo(FakeCloud());
    });
    final subs = _DemoSubscriptions(storage: repo!.storage);
    final boundary = GlobalKey();
    final touch = ValueNotifier<Offset?>(null);
    final rec = Recorder(tester, boundary, touch);
    await rec.start();

    Widget app(ProtocolRepository r) => RepaintBoundary(
      key: boundary,
      child: _Touches(
        touch: touch,
        card: rec.card,
        child: MultiProvider(
          key: ObjectKey(r),
          providers: [
            ChangeNotifierProvider.value(value: r),
            ChangeNotifierProvider<SubscriptionService>.value(value: subs),
          ],
          child: const OmnyaApp(),
        ),
      ),
    );

    final semantics = tester.ensureSemantics();
    Widget blank() => RepaintBoundary(
      key: boundary,
      child: _Touches(
        touch: touch,
        card: rec.card,
        child: const ColoredBox(color: OmnyaColors.plum),
      ),
    );
    await tester.pumpWidget(blank());
    await rec.title(
      'Omnya',
      'A first-time walkthrough: onboarding, first dose, every tab.',
      behind: () async {
        await tester.pumpWidget(app(repo));
      },
    );
    await dayOne(rec, tester);

    // Day 30: the same answers and stack, with a month of history behind them.
    final cloud = FakeCloud();
    final later = await tester.runAsync(() => seedDay30(repo, cloud));
    subs.pro = true;
    await rec.title(
      'Day 30',
      'Four weeks of doses and check-ins later, on Pro.',
      behind: () async {
        // Unmount the first app so its navigator lets go of the shared route observer.
        await tester.pumpWidget(blank());
        await tester.pumpWidget(app(later!));
      },
    );
    await dayThirty(rec, tester);
    semantics.dispose();
    await rec.finish();
    debugDefaultTargetPlatformOverride = null;
  });
}

Future<void> dayOne(Recorder rec, WidgetTester tester) async {
  // Launch
  await rec.wait(2800);

  // Onboarding: six questions
  await rec.wait(600);
  await rec.tapText('Glow', after: 250);
  await rec.tapText('Snatched', after: 400);
  await rec.tapText('Continue', after: 700);
  await rec.tapText('GHK-Cu', after: 250);
  await rec.tapText('Retatrutide', after: 400);
  await rec.tapText('Continue', after: 700);
  await rec.tapText('First month', after: 400);
  await rec.tapText('Continue', after: 700);
  await rec.tapText('Yes', after: 400);
  await rec.tapText('Continue', after: 700);
  await rec.type(find.byType(TextField), 'Glowing skin and my jeans fitting again');
  await rec.snapshot('goal');
  await rec.tapText('Continue', after: 700);
  await rec.tapText('Both', after: 400);
  await rec.tapText('Continue', after: 2200);
  await rec.snapshot('summary');
  await rec.tapText('Continue', after: 1200);

  // Paywall
  await rec.snapshot('paywall');
  await rec.scroll(-300);
  await rec.snapshot('paywall2');
  await rec.tapText('Continue', last: true, after: 1500);
  await rec.snapshot('today');

  // Set up the first compound from Today
  await rec.tapText('Add dose and schedule', after: 900);
  await rec.snapshot('editor');
  await rec.type(field('Dose'), '1.5');
  await rec.tapText('Daily', after: 400);
  await rec.snapshot('editor2');
  await rec.scroll(-700, ms: 900);
  await rec.tapText('Left abdomen', after: 400);
  await rec.scroll(-500, ms: 700);
  await rec.snapshot('vial');
  await rec.tap(find.text('Choose').last, after: 700);
  await rec.drag(const Offset(195, 700), -180, ms: 700);
  await rec.wait(500);
  await rec.snapshot('wheel');
  await rec.tapText('Save', last: true, after: 600);
  await rec.type(field('Cost per dose'), '6');
  await rec.tapText('Add date', after: 700);
  await rec.snapshot('date');
  await rec.tapText('Save', last: true, after: 600);
  await rec.scroll(-300);
  await rec.snapshot('vial2');
  await rec.tapText('Save', last: true, after: 1200);
  await rec.snapshot('today2');

  // Log the dose
  await rec.tapText('Log it', after: 1500);
  await rec.snapshot('logged');
  await rec.tapText('Done', after: 1000);

  // Daily check-in
  await rec.tap(find.bySemanticsLabel('Energy 4 of 5'), after: 250);
  await rec.tap(find.bySemanticsLabel('Appetite 2 of 5'), after: 250);
  await rec.tap(find.bySemanticsLabel('Strength 3 of 5'), after: 400);
  await rec.tap(find.text('Choose').first, after: 700);
  await rec.drag(const Offset(195, 640), 90, ms: 600);
  await rec.wait(500);
  await rec.tapText('Save', last: true, after: 600);
  await rec.tapText('Save check-in', after: 1200);
  await rec.snapshot('checked');
  await rec.scroll(-500, ms: 800);
  await rec.snapshot('today_bottom');
  await rec.scroll(600, ms: 700);

  // Progress, as a free user
  await rec.tap(find.bySemanticsLabel('Progress'), after: 1200);
  await rec.snapshot('progress_free');
  await rec.scroll(-600, ms: 900);
  await rec.snapshot('progress_free2');
  await rec.scroll(-600, ms: 900);
  await rec.snapshot('progress_free3');

  // Stack: a second compound, then the mixing calculator
  await rec.tap(find.bySemanticsLabel('Stack'), after: 1200);
  await rec.snapshot('stack');
  await rec.tapText('Tap to add your dose and schedule', after: 900);
  await rec.type(field('Dose'), '2');
  await rec.tapText('Weekly', after: 400);
  await rec.snapshot('reta');
  await rec.scroll(-700, ms: 900);
  await rec.scroll(-700, ms: 900);
  await rec.tapText('Save', last: true, after: 1200);
  await rec.snapshot('stack2');
  await rec.tapText('Mixing calculator', after: 900);
  await rec.type(field('Powder in vial'), '10');
  await rec.type(field('Water added'), '2');
  await rec.type(field('Your dose'), '2');
  await rec.type(field('Vial cost (optional)'), '180');
  await rec.wait(800);
  await rec.snapshot('calc');
  await rec.scroll(-300);
  await rec.snapshot('calc2');
  await rec.tapText('Done', last: true, after: 900);

  // Circle
  await rec.tap(find.bySemanticsLabel('Circle'), after: 1200);
  await rec.snapshot('circle');
  // Circles are Pro, so a free user lands on the plans.
  await rec.tapText('Start a circle', after: 1500);
  await rec.snapshot('circle_paywall');
  await rec.tap(find.byTooltip('Close'), after: 900);

  // Settings and the plans
  await rec.tap(find.bySemanticsLabel('Today'), after: 1000);
  await rec.tap(find.bySemanticsLabel('Settings'), after: 1000);
  await rec.snapshot('settings');
  await rec.scroll(-500, ms: 800);
  await rec.snapshot('settings2');
  await rec.tapAt(const Offset(195, 30), after: 900);
  await rec.snapshot('after_settings');
}

Finder field(String label) =>
    find.descendant(of: find.widgetWithText(OmnyaField, label), matching: find.byType(TextField));

Future<ProtocolRepository> seedDay30(ProtocolRepository first, FakeCloud cloud) async {
  final storage = first.storage;
  final today = dayOf(DateTime.now());
  DateTime at(int daysAgo, int hour, [int minute = 0]) =>
      addDays(today, -daysAgo).add(Duration(hours: hour, minutes: minute));
  final start = addDays(today, -29);

  final old = first.profile!;
  await storage.saveProfile(
    UserProfile(
      goals: old.goals,
      selectedCompounds: old.selectedCompounds,
      experienceLevel: old.experienceLevel,
      cycleStatus: old.cycleStatus,
      day90GoalText: old.day90GoalText,
      photoTrackingType: old.photoTrackingType,
      proteinTargetG: 110,
      createdAt: start,
    ),
  );

  final ghk = first.compounds.firstWhere((c) => c.name == 'GHK-Cu');
  final reta = first.compounds.firstWhere((c) => c.name == 'Retatrutide');
  final logs = <DoseLog>[];
  var site = injectionSites.first;
  for (var d = 29; d >= 1; d--) {
    if (d == 17 || d == 8) continue; // two missed days
    logs.add(
      DoseLog(
        id: 'g$d',
        compoundId: ghk.id,
        compoundName: ghk.name,
        dose: 1.5,
        unit: 'mg',
        injectionSite: site,
        timestamp: at(d, 8, 20 + d % 25),
      ),
    );
    site = siteAfter(site);
  }
  var rsite = 'Right thigh';
  for (final d in [29, 22, 15, 8, 1]) {
    logs.add(
      DoseLog(
        id: 'r$d',
        compoundId: reta.id,
        compoundName: reta.name,
        dose: 2,
        unit: 'mg',
        injectionSite: rsite,
        timestamp: at(d, 19, 10),
      ),
    );
    rsite = siteAfter(siteAfter(rsite));
  }
  logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

  await storage.saveCompounds([
    ghk.copyWith(startDate: start, nextSite: site, dosesLeft: () => 6, costPerDose: () => 6),
    reta.copyWith(
      startDate: start,
      nextSite: rsite,
      dosesLeft: () => 3,
      costPerDose: () => 36,
      vialMg: () => 10,
      bacWaterMl: () => 2,
      mixedOn: () => addDays(today, -15),
      vialDays: () => 28,
    ),
  ]);
  await storage.saveDoseLogs(logs);

  final checkIns = <DailyCheckIn>[];
  for (var d = 29; d >= 1; d--) {
    if (d == 20 || d == 11) continue;
    final progress = (29 - d) / 28;
    final water = d <= 7 && d >= 2 ? 1.4 : 0.0; // the week before her period
    final wobble = [0.3, -0.2, 0.1, -0.4, 0.2, 0.0, -0.1][d % 7];
    checkIns.add(
      DailyCheckIn(
        id: 'c$d',
        date: at(d, 7, 45),
        energyLevel: (3 + progress * 1.6 + (d % 3 == 0 ? -1 : 0)).round().clamp(1, 5),
        appetiteLevel: (4 - progress * 2.2 + (d % 4 == 0 ? 1 : 0)).round().clamp(1, 5),
        weightLbs: double.parse((168.4 - progress * 6.8 + water + wobble).toStringAsFixed(1)),
        waistIn: d % 7 == 1 ? double.parse((30.6 - progress * 1.3).toStringAsFixed(1)) : null,
        sleepHours: 6.5 + (d % 4) * 0.5,
        proteinG: 85 + (progress * 25).round() + d % 9,
        strength: d % 7 == 2 ? (2 + progress * 2).round() : null,
        notes: d == 5 ? 'Skin looks brighter, fewer breakouts' : '',
        periodStarted: d == 27 || d == 1,
      ),
    );
  }
  checkIns.sort((a, b) => b.date.compareTo(a.date));
  await storage.saveCheckIns(checkIns);
  await storage.markMilestone('firstDose');

  final week = weekStartOf(DateTime.now());
  final circle = Circle(
    code: 'K7M2Q',
    name: "Maya's circle",
    ownerId: 'me',
    members: [
      CircleMember(
        userId: 'me',
        displayName: 'Maya',
        lastLoggedAt: at(1, 8, 30),
        weekStart: week,
        dosesThisWeek: 6,
        dosesPlannedThisWeek: 8,
      ),
      CircleMember(
        userId: 'ada',
        displayName: 'Ada',
        lastLoggedAt: at(0, 7, 5),
        weekStart: week,
        dosesThisWeek: 5,
        dosesPlannedThisWeek: 5,
      ),
      CircleMember(
        userId: 'jo',
        displayName: 'Jo',
        lastLoggedAt: at(2, 21, 0),
        weekStart: week,
        dosesThisWeek: 2,
        dosesPlannedThisWeek: 3,
      ),
      CircleMember(
        userId: 'priya',
        displayName: 'Priya',
        lastLoggedAt: at(0, 6, 40),
        weekStart: week,
        dosesThisWeek: 7,
        dosesPlannedThisWeek: 7,
      ),
    ],
  );
  cloud.circle = circle;
  await storage.saveCircle(circle);
  return ProtocolRepository(storage: storage, cloud: cloud);
}

Future<void> dayThirty(Recorder rec, WidgetTester tester) async {
  await rec.wait(2800);
  await rec.snapshot('d30_today');
  await rec.tapText('Log it', after: 2500);
  await rec.snapshot('d30_milestone');
  await rec.tapText('Done', after: 1200);
  await rec.snapshot('d30_today2');
  await rec.tap(find.bySemanticsLabel('Energy 5 of 5'), after: 250);
  await rec.tap(find.bySemanticsLabel('Appetite 2 of 5'), after: 400);
  await rec.tapText('Add waist, sleep, protein or notes', after: 700);
  await rec.snapshot('d30_more');
  await rec.scroll(-400, ms: 700);
  await rec.snapshot('d30_more2');
  await rec.tapText('Save check-in', after: 1200);
  await rec.snapshot('d30_saved');
  await rec.scroll(-500, ms: 800);
  await rec.snapshot('d30_today4');
  await rec.scroll(1400, ms: 800);

  await rec.tap(find.bySemanticsLabel('Progress'), after: 1500);
  await rec.snapshot('d30_progress');
  for (var i = 0; i < 4; i++) {
    await rec.scroll(-450, ms: 900);
    await rec.wait(700);
    await rec.snapshot('d30_progress_$i');
  }
  await rec.tapText('Your week', after: 1500);
  await rec.snapshot('d30_week');
  await rec.wait(1500);
  await rec.tapAt(tester.getCenter(find.byType(OmnyaIconButton).last), after: 1000);

  await rec.tap(find.bySemanticsLabel('Stack'), after: 1500);
  await rec.snapshot('d30_stack');
  await rec.tapText('Retatrutide', after: 1000);
  await rec.scroll(-500, ms: 800);
  await rec.snapshot('d30_reta');
  await rec.tapAt(const Offset(195, 30), after: 900);

  await rec.tap(find.bySemanticsLabel('Circle'), after: 1800);
  await rec.snapshot('d30_circle');
  await rec.tapText('Invite a friend', last: true, after: 1800);
  await rec.snapshot('d30_invite');
  await rec.tapAt(const Offset(195, 120), after: 900);

  await rec.tap(find.bySemanticsLabel('Log a dose'), after: 1200);
  await rec.snapshot('d30_quick');
  await rec.tapAt(const Offset(195, 120), after: 800);
  await rec.tap(find.bySemanticsLabel('Today'), after: 1500);
  await rec.title('Omnya', 'Log what goes in. See what comes out.', ms: 2500);
}
