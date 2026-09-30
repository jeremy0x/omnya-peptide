import 'package:flutter/material.dart';
import '../../core/theme/omnya_colors.dart';
import '../../core/theme/omnya_typography.dart';
import '../../core/widgets/omnya_logo.dart';

/// Animated branded splash screen displaying the harmonious Omnya logo circles in motion.
/// Matches the native launch screen 1:1 on the first frame with zero visual pop or blank screen,
/// then fluidly transitions into ambient orbital motion before seamlessly dissolving into the home experience.
class OmnyaSplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OmnyaSplashScreen({super.key, required this.onFinished});

  @override
  State<OmnyaSplashScreen> createState() => _OmnyaSplashScreenState();
}

class _OmnyaSplashScreenState extends State<OmnyaSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _textFadeAnimation;
  late final Animation<Offset> _textSlideAnimation;
  late final Animation<double> _exitFadeAnimation;
  late final Animation<double> _exitScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Text "Omnya" gently slides up and fades in
    _textFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.04, 0.36, curve: Curves.easeOut),
    );
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.04, 0.40, curve: Curves.easeOutCubic),
    ));

    // Smooth exit dissolve in the final 450ms
    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 1.0, curve: Curves.easeInOutCubic),
      ),
    );
    _exitScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onFinished();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? OmnyaColors.charcoal : OmnyaColors.sand,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final exitOpacity = _exitFadeAnimation.value;
            final exitScale = _exitScaleAnimation.value;

            return Opacity(
              opacity: exitOpacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: exitScale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Harmonic logo circles: 144pt exactly matching native LaunchImage
                    SizedBox(
                      width: 144,
                      height: 144,
                      child: OmnyaLogoLoader(
                        size: 144,
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Brand Title: "Omnya" with gentle slide & fade
                    SlideTransition(
                      position: _textSlideAnimation,
                      child: FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Text(
                          'Omnya',
                          style: OmnyaTypography.displayLarge(
                            color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

