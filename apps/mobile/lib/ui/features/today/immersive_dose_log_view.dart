import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';

/// Clean, editorial full-screen dose logging ritual.
///
/// Features:
/// - Duolingo-style signature multi-beat haptic sequence on check reveal.
/// - Concentrated confetti bloom that bursts out from behind the check ("poof").
/// - Clean time display on top-right (redundant top-left text removed).
/// - Refined editorial typography with zero all-uppercase text.
/// - Exact design match to search button: clean off-white circular surface with single stroke check.
class ImmersiveDoseLogView extends StatefulWidget {
  final String compoundName;
  final double doseMg;
  final String injectionSite;
  final String nextSite;
  final String category;

  const ImmersiveDoseLogView({
    super.key,
    required this.compoundName,
    required this.doseMg,
    required this.injectionSite,
    required this.nextSite,
    required this.category,
  });

  static Future<void> show(
    BuildContext context, {
    required String compoundName,
    required double doseMg,
    required String injectionSite,
    required String nextSite,
    required String category,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ImmersiveDoseLogView(
            compoundName: compoundName,
            doseMg: doseMg,
            injectionSite: injectionSite,
            nextSite: nextSite,
            category: category,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<ImmersiveDoseLogView> createState() => _ImmersiveDoseLogViewState();
}

class _ImmersiveDoseLogViewState extends State<ImmersiveDoseLogView>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _entranceController;
  late final AnimationController _confettiController;

  late final Animation<double> _checkOpacity;
  late final Animation<double> _checkScale;
  late final Animation<Offset> _checkSlide;

  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardSlide;

  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;

  late final List<_ConfettiParticle> _confettiParticles;

  @override
  void initState() {
    super.initState();

    // 1. Serene ambient breathing background (slow 5.5s cycle)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat(reverse: true);

    // 2. Choreographed entrance animation (1100ms total staggered entrance)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // 3. Single-shot confetti poof from behind check (850ms)
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _confettiParticles = _generateConfetti();

    // Stagger 1: Checkmark circle (0.0 -> 0.55)
    final checkCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(checkCurve);
    _checkScale = Tween<double>(begin: 0.80, end: 1.0).animate(checkCurve);
    _checkSlide = Tween<Offset>(
      begin: const Offset(0, 18),
      end: Offset.zero,
    ).animate(checkCurve);

    // Stagger 2: Headline & subtitle (0.20 -> 0.70)
    final textCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.20, 0.70, curve: Curves.easeOutCubic),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(textCurve);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 22),
      end: Offset.zero,
    ).animate(textCurve);

    // Stagger 3: Details summary card (0.38 -> 0.86)
    final cardCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.38, 0.86, curve: Curves.easeOutCubic),
    );
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(cardCurve);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 24),
      end: Offset.zero,
    ).animate(cardCurve);

    // Stagger 4: Bottom Done action (0.55 -> 1.00)
    final buttonCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 1.00, curve: Curves.easeOutCubic),
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(buttonCurve);
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(buttonCurve);

    _startChoreography();
  }

  List<_ConfettiParticle> _generateConfetti() {
    final rand = math.Random(1337);
    const colors = [
      Color(0xFFE8C868), // champagne gold
      Color(0xFFFCF9F6), // warm cream
      Color(0xFFD482AA), // soft plum rose
      Color(0xFFD4AF37), // warm bronze
      Color(0xFFE2C9DD), // soft lilac
      Color(0xFFF1E4C3), // light gold
    ];

    return List.generate(28, (i) {
      final angle = rand.nextDouble() * 2 * math.pi;
      final distance = 65.0 + rand.nextDouble() * 75.0; // radiate 65 to 140px out
      final isRibbon = rand.nextBool();
      final width = isRibbon ? (4.0 + rand.nextDouble() * 3.0) : (4.0 + rand.nextDouble() * 2.5);
      final height = isRibbon ? (8.0 + rand.nextDouble() * 5.0) : width;
      final rotation = rand.nextDouble() * 2 * math.pi;
      final spin = (rand.nextDouble() - 0.5) * 6.0;
      final color = colors[rand.nextInt(colors.length)];

      return _ConfettiParticle(
        angle: angle,
        distance: distance,
        width: width,
        height: height,
        isRibbon: isRibbon,
        initialRotation: rotation,
        spin: spin,
        color: color,
      );
    });
  }

  void _startChoreography() async {
    // Initial gentle tactile engagement
    await HapticFeedback.lightImpact();
    if (!mounted) return;

    _entranceController.forward();

    // Exactly as the checkmark settles into center (~380ms), burst confetti & play Duolingo haptics
    await Future.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;

    _confettiController.forward(from: 0.0);
    _playDuolingoCelebrationHaptic();
  }

  /// Duolingo-style signature multi-beat haptic sequence:
  /// Crisp prep tick -> energetic celebratory medium pop -> satisfying final click.
  Future<void> _playDuolingoCelebrationHaptic() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 70));
    if (!mounted) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    await HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _entranceController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onDone() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    return Scaffold(
      backgroundColor: const Color(0xFF130911),
      body: Stack(
        children: [
          // 1. Ambient Living Background (Deep rich Omnya Plum with subtle breathing depth)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) {
                final breath = _ambientController.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.25),
                      radius: 1.0 + 0.20 * breath,
                      colors: [
                        Color.lerp(
                          const Color(0xFF2E1325),
                          const Color(0xFF3B1830),
                          breath,
                        )!,
                        const Color(0xFF1F0D19),
                        const Color(0xFF130911),
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Main Content Column with Sequenced Staggered Entrance
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // Top header: Clean time on the top right (redundant top-left text removed)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          timeStr,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Item 1: Central Checkmark Icon with Confetti Poof behind it
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _checkOpacity.value,
                            child: Transform.translate(
                              offset: _checkSlide.value,
                              child: Transform.scale(
                                scale: _checkScale.value,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // Confetti burst: emerges from behind the check, then blooms out
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _confettiController,
                                builder: (context, _) {
                                  return CustomPaint(
                                    painter: _ConfettiPoofPainter(
                                      progress: _confettiController.value,
                                      particles: _confettiParticles,
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Main circular checkmark surface (matches search button)
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFCF9F6), // matching search button cream surface
                                border: Border.all(
                                  color: const Color(0x44B5A496), // matching search button border
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedTick02,
                                  color: OmnyaColors.charcoal,
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Item 2: Headline & Subtitle (Title Case & Sentence Case)
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textOpacity.value,
                            child: Transform.translate(
                              offset: _textSlide.value,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Text(
                              'Dose Logged',
                              style: OmnyaTypography.displayMedium(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your administration has been recorded and synced.',
                              style: OmnyaTypography.bodyMedium(
                                color: Colors.white.withValues(alpha: 0.68),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Item 3: Administration Details Card (Pure editorial layout, zero uppercase)
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _cardOpacity.value,
                            child: Transform.translate(
                              offset: _cardSlide.value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Compound name & Category pill
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.compoundName,
                                        style: OmnyaTypography.headline(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Target: ${widget.doseMg.toStringAsFixed(1)} mg',
                                        style: OmnyaTypography.bodySmall(
                                          color: Colors.white.withValues(
                                            alpha: 0.60,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.16),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      widget.category,
                                      style: GoogleFonts.instrumentSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.85),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  height: 1,
                                ),
                              ),

                              // Administration & Next Rotation details (No all-caps, clean sentence labels)
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Administered',
                                          style: GoogleFonts.instrumentSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(
                                              alpha: 0.48,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.injectionSite,
                                          style: OmnyaTypography.bodyMedium(
                                            color: Colors.white.withValues(
                                              alpha: 0.95,
                                            ),
                                          ).copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 32,
                                    color: Colors.white.withValues(alpha: 0.10),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Next rotation',
                                          style: GoogleFonts.instrumentSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(
                                              alpha: 0.48,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.nextSite,
                                          style: OmnyaTypography.bodyMedium(
                                            color: const Color(0xFFF1E4C3), // gentle warm gold highlight
                                          ).copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 4),

                      // Item 4: Bottom Done Action
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _buttonOpacity.value,
                            child: Transform.translate(
                              offset: _buttonSlide.value,
                              child: child,
                            ),
                          );
                        },
                        child: _RitualDoneButton(
                          onPressed: _onDone,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile Done button matching Omnya's warm minimal brand aesthetic
/// and design engineering principle: scale(0.96) on press.
class _RitualDoneButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _RitualDoneButton({required this.onPressed});

  @override
  State<_RitualDoneButton> createState() => _RitualDoneButtonState();
}

class _RitualDoneButtonState extends State<_RitualDoneButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
    );
    // make-interfaces-feel-better principle: scale(0.96) exactly
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFFCF9F6), // warm off-white cream surface
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0x44B5A496),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Done',
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: OmnyaColors.charcoal,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Festive celebration confetti particle
class _ConfettiParticle {
  final double angle;
  final double distance;
  final double width;
  final double height;
  final bool isRibbon;
  final double initialRotation;
  final double spin;
  final Color color;

  const _ConfettiParticle({
    required this.angle,
    required this.distance,
    required this.width,
    required this.height,
    required this.isRibbon,
    required this.initialRotation,
    required this.spin,
    required this.color,
  });
}

/// Custom painter for the confetti bloom that starts together behind the check
/// and bursts out in a festive "poof" with natural deceleration & rotation.
class _ConfettiPoofPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPoofPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);

    // Initial gathering behind check, then explosive expansion and deceleration
    final eased = Curves.easeOutCubic.transform(progress);
    // Smooth clean fade out in the second half of animation
    final fadeOut = (1.0 - progress * progress).clamp(0.0, 1.0);

    for (final p in particles) {
      // Behind the 76px check (radius 38), particle travels outward past 38px
      final r = (32.0 * (1.0 - eased)) + (p.distance * eased);
      final dx = center.dx + math.cos(p.angle) * r;
      // Gentle gravity / downward drift as particles float down
      final dy = center.dy + math.sin(p.angle) * r + (progress * progress * 18.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: fadeOut * 0.92)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.initialRotation + p.spin * progress);

      if (p.isRibbon) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.width,
              height: p.height,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.width * 0.5, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPoofPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
