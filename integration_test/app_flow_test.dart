import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peptide_app/core/theme/omnya_theme.dart';
import 'package:peptide_app/data/services/local_storage_service.dart';
import 'package:peptide_app/data/services/api_service.dart';
import 'package:peptide_app/data/repositories/protocol_repository.dart';
import 'package:peptide_app/ui/navigation/main_shell.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-End protocol tracking, tab switching, and one-tap log', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.init();
    final api = ApiService();
    final repo = ProtocolRepository(storage: storage, api: api);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProtocolRepository>.value(value: repo),
        ],
        child: MaterialApp(
          theme: OmnyaTheme.lightTheme,
          home: const MainShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Today screen components
    expect(find.text('Next dose'), findsOneWidget);
    expect(find.text('Log it'), findsOneWidget);

    // 2. Perform 1-tap dose log
    final logButton = find.text('Log it');
    await tester.tap(logButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // 3. Navigate to Progress tab via key
    await tester.tap(find.byKey(const Key('nav_tab_progress')));
    await tester.pumpAndSettle();
    expect(find.text('Weight, with cycle band'), findsOneWidget);

    // 4. Navigate to Stack tab via key
    await tester.tap(find.byKey(const Key('nav_tab_stack')));
    await tester.pumpAndSettle();
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Retatrutide'), findsOneWidget);

    // 5. Open Reconstitution Calculator
    final calcButton = find.text('Open dilution calculator');
    await tester.tap(calcButton);
    await tester.pumpAndSettle();
    expect(find.text('Reconstitution math'), findsOneWidget);
    expect(find.text('Draw to tick mark'), findsOneWidget);
    // Syringe options exist (U-100, U-40) with no checkmarks
    expect(find.text('U-100 (100u / mL)'), findsOneWidget);

    // Close calculator modal
    final doneButton = find.text('Done');
    await tester.tap(doneButton);
    await tester.pumpAndSettle();

    // 6. Navigate to Circle tab via key
    await tester.tap(find.byKey(const Key('nav_tab_circle')));
    await tester.pumpAndSettle();
    expect(find.text('Consistency this week'), findsOneWidget);
    expect(find.textContaining('Invite-only, up to 5'), findsOneWidget);

    // 7. Navigate back to Today tab via key
    await tester.tap(find.byKey(const Key('nav_tab_today')));
    await tester.pumpAndSettle();
    expect(find.text('Next dose'), findsOneWidget);
  });
}
