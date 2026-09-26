import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/omnya_theme.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/api_service.dart';
import 'data/repositories/protocol_repository.dart';
import 'ui/navigation/main_shell.dart';
import 'ui/onboarding/onboarding_quiz_view.dart';
import 'ui/splash/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep system UI transparent for liquid glass feel
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase directly for mobile client
  try {
    await Supabase.initialize(
      url: 'https://aeddscoqzqwnjwokflnz.supabase.co',
      publishableKey: 'sb_publishable_Ngbc6wpe22CGbsGD9-bXBw_rJS0rSUm',
    );

    // Sign in anonymously so the client gets a real auth.uid() for RLS
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) {
      await auth.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Supabase init note: $e');
  }

  // Initialize offline-first local storage
  final storageService = await LocalStorageService.init();
  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProtocolRepository(
            storage: storageService,
            api: apiService,
          ),
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
  bool _forceMainShell = false;

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
      context.read<ProtocolRepository>().syncWithCloud();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProtocolRepository>();
    final hasCompletedOnboarding = repo.profile != null || _forceMainShell;

    return MaterialApp(
      title: 'Omnya',
      debugShowCheckedModeBanner: false,
      theme: OmnyaTheme.lightTheme,
      darkTheme: OmnyaTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: !_splashFinished
            ? OmnyaSplashScreen(
                key: const ValueKey('splash'),
                onFinished: () {
                  setState(() => _splashFinished = true);
                },
              )
            : (hasCompletedOnboarding
                ? const MainShell(key: ValueKey('main_shell'))
                : OnboardingQuizView(
                    key: const ValueKey('onboarding_quiz'),
                    onFinished: () {
                      setState(() => _forceMainShell = true);
                    },
                  )),
      ),
    );
  }
}
