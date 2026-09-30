import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:provider/provider.dart';
import 'core/theme/omnya_theme.dart';
import 'data/repositories/protocol_repository.dart';
import 'data/services/cloud_service.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/native_service.dart';
import 'data/services/reminder_service.dart';
import 'ui/core/app_lock.dart';
import 'ui/navigation/main_shell.dart';
import 'ui/onboarding/onboarding_quiz_view.dart';
import 'ui/splash/splash_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
  );

  // Both are local: nothing here waits on the network, so the app opens offline.
  await CloudService.initialize();
  final storage = await LocalStorageService.init();
  final reminders = ReminderService();
  await reminders.init();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: reminders),
        ChangeNotifierProvider(
          create: (_) {
            final repo = ProtocolRepository(storage: storage, cloud: CloudService());
            // Reminders follow the data: any change rebuilds them.
            Timer? widgets;
            void follow() {
              reminders.reschedule(repo);
              widgets?.cancel();
              widgets = Timer(const Duration(seconds: 1), () => syncWidgets(repo));
            }

            repo.addListener(follow);
            follow();
            return repo;
          },
        ),
      ],
      child: const OmnyaApp(),
    ),
  );
}

class OmnyaApp extends StatefulWidget {
  const OmnyaApp({super.key});

  @override
  State<OmnyaApp> createState() => _OmnyaAppState();
}

class _OmnyaAppState extends State<OmnyaApp> with WidgetsBindingObserver {
  bool _splashFinished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ProtocolRepository>().sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarded = context.select<ProtocolRepository, bool>((r) => r.profile != null);

    return MaterialApp(
      title: 'Omnya',
      debugShowCheckedModeBanner: false,
      theme: OmnyaTheme.lightTheme,
      themeMode: ThemeMode.light,
      // Hides the native glass tab bar while a sheet or dialog is up.
      navigatorObservers: [CNTabBarRouteObserver()],
      builder: (_, child) => AppLock(child: child!),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: !_splashFinished
            ? OmnyaSplashScreen(key: const ValueKey('splash'), onFinished: () => setState(() => _splashFinished = true))
            : onboarded
            ? const MainShell(key: ValueKey('main_shell'))
            : const OnboardingQuizView(key: ValueKey('onboarding')),
      ),
    );
  }
}
