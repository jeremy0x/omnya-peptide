import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peptide_app/core/theme/omnya_theme.dart';
import 'package:peptide_app/core/widgets/omnya_logo.dart';
import 'package:peptide_app/data/services/local_storage_service.dart';
import 'package:peptide_app/data/services/api_service.dart';
import 'package:peptide_app/data/repositories/protocol_repository.dart';
import 'package:peptide_app/ui/navigation/main_shell.dart';
import 'package:peptide_app/ui/features/today/today_view.dart';
import 'package:peptide_app/ui/features/progress/progress_view.dart';
import 'package:peptide_app/ui/features/stack/stack_view.dart';
import 'package:peptide_app/ui/features/circle/circle_view.dart';
import 'package:peptide_app/ui/onboarding/paywall_view.dart';
import 'package:peptide_app/ui/features/photo_read/weekly_photo_read_view.dart';
import 'package:peptide_app/ui/onboarding/onboarding_quiz_view.dart';
import 'package:peptide_app/ui/splash/splash_view.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:peptide_app/data/models/circle_data.dart';
import 'package:peptide_app/data/models/compound.dart';
import 'package:peptide_app/data/models/dose_log.dart';
import 'package:peptide_app/data/models/daily_check_in.dart';
import 'package:peptide_app/data/models/user_profile.dart';

class MockWidgetApiService extends ApiService {
  @override
  Future<bool> pushSync({
    required String userId,
    UserProfile? profile,
    List<Compound>? compounds,
    List<DoseLog>? doseLogs,
    List<DailyCheckIn>? checkIns,
  }) async => true;

  @override
  Future<CircleModel?> fetchUserCircle(String userId) async => null;

  @override
  Future<CircleModel?> createCircle({
    required String name,
    required String ownerUserId,
    required String ownerDisplayName,
    String? preferredInviteCode,
  }) async => null;

  @override
  Future<CircleActionResult> joinCircle({
    required String userId,
    required String inviteCode,
    required String displayName,
  }) async => CircleActionResult.ok(
        CircleModel(
          id: 'test_circle',
          inviteCode: inviteCode,
          name: 'Test Circle',
          members: [
            CircleMemberModel(
              userId: userId,
              displayName: displayName,
              avatarLetter: displayName.isNotEmpty ? displayName[0] : 'Y',
              checkedInToday: true,
              weeklyDosesLogged: 1,
            ),
          ],
        ),
      );

  @override
  Future<bool> updateCircleMemberProgress({
    required String circleId,
    required String userId,
    required bool checkedInToday,
    required int weeklyDosesLogged,
  }) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProtocolRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.init();
    final api = MockWidgetApiService();
    repo = ProtocolRepository(storage: storage, api: api);
    // Let the unawaited syncWithCloud() → _syncCircleInternal() futures settle
    await Future.delayed(const Duration(milliseconds: 100));
  });

  Widget buildTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProtocolRepository>.value(value: repo),
      ],
      child: MaterialApp(
        theme: OmnyaTheme.lightTheme,
        home: child,
      ),
    );
  }

  testWidgets('OmnyaLogo and OmnyaLogoLoader render smoothly without errors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              OmnyaLogo(size: 64),
              OmnyaLogo(size: 48, monochrome: true),
              OmnyaLogoLoader(size: 48, message: 'Syncing protocols...'),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(OmnyaLogo), findsNWidgets(2));
    expect(find.byType(OmnyaLogoLoader), findsOneWidget);
    expect(find.text('Syncing protocols...'), findsOneWidget);

    // Pump frames to verify animation controller progresses without exceptions
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('MainShell renders floating liquid glass pill, tab items, and adjacent glass orb', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget(const MainShell()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    // Verify all 4 tab items exist by key
    expect(find.byKey(const Key('nav_tab_today')), findsOneWidget);
    expect(find.byKey(const Key('nav_tab_progress')), findsOneWidget);
    expect(find.byKey(const Key('nav_tab_stack')), findsOneWidget);
    expect(find.byKey(const Key('nav_tab_circle')), findsOneWidget);

    // Verify adjacent search glass orb
    expect(find.bySemanticsLabel('Search peptides and protocols'), findsOneWidget);

    // Tap on Progress tab uniquely by Key
    await tester.tap(find.byKey(const Key('nav_tab_progress')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Progress screen loaded in IndexedStack
    expect(find.text('Outcomes & reads', skipOffstage: false), findsOneWidget);

    // Tap on adjacent glass orb button
    await tester.tap(find.byKey(const Key('nav_orb_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Quick Protocol Search sheet opened
    expect(find.text('Protocol Library & Quick Log'), findsOneWidget);
    expect(find.text('Retatrutide'), findsOneWidget);
    expect(find.text('GHK-Cu'), findsOneWidget);
  });

  testWidgets('TodayView renders Next Dose card and 3-tap check-in', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget(const TodayView()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Dose'), findsOneWidget);
    expect(find.text('Log it'), findsOneWidget);
    expect(find.text('Daily check-in'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
  });

  testWidgets('StackView renders compound inventory cards and monthly spend', (tester) async {
    await tester.pumpWidget(buildTestWidget(const StackView()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Stack'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Retatrutide'), findsOneWidget);
    expect(find.text('GHK-Cu'), findsOneWidget);
    expect(find.text('KLOW'), findsOneWidget);
  });

  testWidgets('CircleView renders member avatars and consistency list', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget(const CircleView()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Circle'), findsOneWidget);
    expect(find.text('Consistency this week'), findsOneWidget);
    expect(find.text('Mia'), findsWidgets);

    // Test Join Circle mobile bottom sheet
    await tester.tap(find.text('Join with code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Join Circle'), findsWidgets);
    expect(find.text('• • • • •'), findsOneWidget);
    expect(find.text('Your Name in Circle'), findsOneWidget);

    // Close join sheet
    Navigator.of(tester.element(find.text('• • • • •'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Test Invite to Circle mobile bottom sheet
    await tester.tap(find.text('Share invite link'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Invite to Circle'), findsOneWidget);
    expect(find.text('Copy Invite Code'), findsOneWidget);

    // Close invite sheet
    Navigator.of(tester.element(find.text('Invite to Circle'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('ProgressView renders before/after slider and cycle band', (tester) async {
    await tester.pumpWidget(buildTestWidget(const ProgressView()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Weight, with cycle band'), findsOneWidget);
  });

  testWidgets('PaywallView renders balanced tier cards and Pro features', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget(const PaywallView()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('Lifetime'), findsOneWidget);
    expect(find.text('BEST VALUE'), findsOneWidget);
    expect(find.text('Start 7-day free trial'), findsOneWidget);
  });

  testWidgets('WeeklyPhotoReadView renders comparison and simplified alignment camera', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget(const WeeklyPhotoReadView()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Your week in photos'), findsOneWidget);
    expect(find.text('Aug 25'), findsOneWidget);
    expect(find.text('Sep 1'), findsOneWidget);
  });

  testWidgets('OnboardingQuizView renders HugeIcon back arrow and integrated progress header on step 1', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget(OnboardingQuizView(onFinished: () {})));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('1 of 6'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('What are you here for?'), findsOneWidget);

    final hugeIcons = tester.widgetList<HugeIcon>(find.byType(HugeIcon));
    expect(hugeIcons.any((icon) => icon.icon == HugeIcons.strokeRoundedArrowLeft01), isTrue);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('OmnyaSplashScreen renders animated brand circles and completes transition', (tester) async {
    bool finished = false;
    await tester.pumpWidget(buildTestWidget(OmnyaSplashScreen(onFinished: () => finished = true)));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Omnya'), findsOneWidget);
    expect(find.text('PROTOCOL INTELLIGENCE'), findsNothing);

    // Fast-forward past splash duration
    await tester.pump(const Duration(milliseconds: 2600));
    expect(finished, isTrue);
  });
}

