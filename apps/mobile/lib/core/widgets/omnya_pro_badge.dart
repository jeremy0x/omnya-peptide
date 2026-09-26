import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shiny luxury metallic PRO badge with seamless looping light sweep and clean typography.
class OmnyaProBadge extends StatefulWidget {
  final VoidCallback? onTap;

  const OmnyaProBadge({super.key, this.onTap});

  @override
  State<OmnyaProBadge> createState() => _OmnyaProBadgeState();
}

class _OmnyaProBadgeState extends State<OmnyaProBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFF8DE),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Base metallic gold gradient (constant baseline)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.0, -0.8),
                    end: Alignment(1.0, 0.8),
                    colors: [
                      Color(0xFFE8C868),
                      Color(0xFFD4AF37),
                      Color(0xFFC59B27),
                    ],
                  ),
                ),
                child: Text(
                  'PRO',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF342600),
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // 2. Sliding sheen highlight overlay (starts & ends completely offscreen for seamless 0-snap loop)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, _) {
                    final t = _shimmerController.value;
                    // Sweep from -1.8 (far left, invisible) to 1.8 (far right, invisible)
                    // Between 0.65 and 1.0, it remains fully offscreen, creating a calm luxury pause
                    final sweepProgress = (t < 0.65) ? (t / 0.65) : 1.0;
                    final slideX = -1.8 + sweepProgress * 3.6;

                    return FractionalTranslation(
                      translation: Offset(slideX, 0),
                      child: Container(
                        width: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: const Alignment(-0.6, -1.0),
                            end: const Alignment(0.6, 1.0),
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.65),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
