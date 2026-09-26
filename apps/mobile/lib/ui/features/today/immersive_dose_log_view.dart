import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/omnya_typography.dart';
import '../../../core/widgets/tactile_button.dart';

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
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
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
  late final AnimationController _pulseController;
  late final AnimationController _entranceController;
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    _runHapticSequence();
  }

  void _runHapticSequence() async {
    // Initial tactile engagement
    await HapticFeedback.mediumImpact();

    if (!mounted) return;
    _entranceController.forward();

    // Secondary deep pulse as confirmation orb expands
    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    await HapticFeedback.heavyImpact();

    // Tertiary subtle tick as consistency data settles
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    await HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onDone() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    return Scaffold(
      backgroundColor: const Color(0xFF140D12),
      body: Stack(
        children: [
          // 1. Ambient Background Mesh / Radial Glow
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final glow = _pulseController.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.2),
                      radius: 1.1 + 0.15 * glow,
                      colors: [
                        Color.lerp(
                          const Color(0xFF4A1E38),
                          const Color(0xFF6B2851),
                          glow,
                        )!,
                        const Color(0xFF281020),
                        const Color(0xFF140D12),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Subtle Floating Celestial Particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AuraParticlePainter(progress: _particleController.value),
                );
              },
            ),
          ),

          // 3. Foreground Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      // Top indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF4ADE80),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'PROTOCOL VERIFIED',
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            timeStr,
                            style: GoogleFonts.instrumentSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Concentric Pulsing Ritual Orb
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final glow = _pulseController.value;
                          return SizedBox(
                            width: 170,
                            height: 170,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer ripple
                                Container(
                                  width: 150 + 20 * glow,
                                  height: 150 + 20 * glow,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37).withValues(alpha: 0.22 - 0.15 * glow),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                // Mid ripple
                                Container(
                                  width: 120 + 10 * glow,
                                  height: 120 + 10 * glow,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF6B2851).withValues(alpha: 0.25 + 0.15 * glow),
                                    border: Border.all(
                                      color: const Color(0xFFE8C868).withValues(alpha: 0.35),
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                                // Core radiant button
                                Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFFFFF2B2),
                                        Color(0xFFD4AF37),
                                        Color(0xFF914168),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                                      color: Color(0xFF281020),
                                      size: 42,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Dose Logged',
                        style: OmnyaTypography.displayMedium(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your administration has been recorded and synced.',
                        style: OmnyaTypography.bodyMedium(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Ritual Summary Glass Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Compound and Dose row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.compoundName,
                                      style: OmnyaTypography.headline(color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Target: ${widget.doseMg.toStringAsFixed(1)} mg',
                                      style: OmnyaTypography.bodySmall(
                                        color: Colors.white.withValues(alpha: 0.65),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    widget.category,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFFF2B2),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Divider(color: Colors.white12, height: 1),
                            ),

                            // Injection site rotation row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedRepeat,
                                    color: Color(0xFFD4AF37),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Administered: ${widget.injectionSite}',
                                        style: OmnyaTypography.label(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          weight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Next rotation: ${widget.nextSite}',
                                        style: OmnyaTypography.bodySmall(
                                          color: const Color(0xFFD4AF37).withValues(alpha: 0.9),
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

                      const Spacer(),

                      // Prominent "Done" Button
                      TactileButton(
                        label: 'Done',
                        variant: TactileButtonVariant.primary,
                        height: 54,
                        borderRadius: 18,
                        onPressed: _onDone,
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

class _AuraParticlePainter extends CustomPainter {
  final double progress;

  _AuraParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 28; i++) {
      final baseX = rand.nextDouble() * size.width;
      final baseY = rand.nextDouble() * size.height;
      final speed = 15.0 + rand.nextDouble() * 25.0;
      final offset = (progress * speed * 4 + i * 20) % size.height;

      final y = (baseY - offset + size.height) % size.height;
      final radius = 1.0 + rand.nextDouble() * 2.2;
      final alpha = (0.2 + 0.45 * math.sin((progress * 2 * math.pi) + i)).clamp(0.05, 0.7);

      paint.color = (i % 3 == 0)
          ? const Color(0xFFD4AF37).withValues(alpha: alpha)
          : Colors.white.withValues(alpha: alpha * 0.7);

      canvas.drawCircle(Offset(baseX, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuraParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
