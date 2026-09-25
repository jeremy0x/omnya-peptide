import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/omnya_colors.dart';
import 'tactile_button.dart';

/// Clean dose logging action featuring:
/// - Smooth tactile "Log it" trigger
/// - Crisp, short champagne particle burst on tap that cleanly disappears
/// - Sleek 54px frosted pill matching the button height with zero layout shift
/// - Minimalist check indicator, clear status, and subtle "Undo" action
class DoseCelebrationAction extends StatefulWidget {
  final bool isLogged;
  final String compoundName;
  final String nextSite;
  final VoidCallback onLog;
  final VoidCallback onUndo;

  const DoseCelebrationAction({
    super.key,
    required this.isLogged,
    required this.compoundName,
    required this.nextSite,
    required this.onLog,
    required this.onUndo,
  });

  @override
  State<DoseCelebrationAction> createState() => _DoseCelebrationActionState();
}

class _DoseCelebrationActionState extends State<DoseCelebrationAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;
  List<_ConfettiParticle> _particles = const [];

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _particles = _generateParticles();
  }

  @override
  void didUpdateWidget(covariant DoseCelebrationAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isLogged && widget.isLogged) {
      _particles = _generateParticles();
      _confettiController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  List<_ConfettiParticle> _generateParticles() {
    final rand = math.Random();
    const colors = [
      Color(0xFFD4AF37), // Champagne gold
      Color(0xFFF6F1E8), // Cream
      Color(0xFFE2C9DD), // Soft lilac
      Color(0xFFB9A995), // Warm taupe
    ];

    return List.generate(18, (i) {
      final angle = rand.nextDouble() * 2 * math.pi;
      final speed = 60.0 + rand.nextDouble() * 80.0;
      final size = 2.5 + rand.nextDouble() * 3.5;
      final color = colors[rand.nextInt(colors.length)];

      return _ConfettiParticle(
        angle: angle,
        speed: speed,
        size: size,
        color: color,
      );
    });
  }

  void _triggerLog() {
    HapticFeedback.mediumImpact();
    widget.onLog();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Temporary subtle particle burst that completely clears once done
        if (_confettiController.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _confettiController.value,
                      particles: _particles,
                    ),
                  );
                },
              ),
            ),
          ),

        // Action surface: Log button OR Sleek Done pill (both exactly 54px high)
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 280),
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeOutCubic,
          crossFadeState: widget.isLogged
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: TactileButton(
            label: 'Log it',
            variant: TactileButtonVariant.secondary,
            width: double.infinity,
            onPressed: _triggerLog,
          ),
          secondChild: _buildDonePill(),
        ),
      ],
    );
  }

  Widget _buildDonePill() {
    final shortName = widget.compoundName.length > 4
        ? widget.compoundName.substring(0, 4)
        : widget.compoundName;

    return Container(
      width: double.infinity,
      height: 54, // Matches TactileButton height exactly to prevent layout shifts
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Logged $shortName',
            style: const TextStyle(
              fontFamily: 'InstrumentSans',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: OmnyaColors.cream,
              letterSpacing: -0.2,
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onUndo();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.20),
                  width: 0.8,
                ),
              ),
              child: const Text(
                'Undo',
                style: TextStyle(
                  fontFamily: 'InstrumentSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: OmnyaColors.sandMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  const _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Only paint while actively animating, never leave lingering static specks
    if (progress <= 0.0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOutCubic.transform(progress);
    final fadeOut = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final distance = p.speed * eased;
      final dx = center.dx + math.cos(p.angle) * distance;
      final dy = center.dy + math.sin(p.angle) * distance + (progress * progress * 20.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: fadeOut * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), p.size * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
