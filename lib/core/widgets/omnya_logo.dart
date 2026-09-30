import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/omnya_colors.dart';

/// Mathematically precise vector representation of the Omnya brand logo.
/// Consists of three harmonious overlapping circles with an off-center cutout dot.
class OmnyaLogo extends StatelessWidget {
  final double size;
  final bool monochrome;
  final Color? tintColor;

  const OmnyaLogo({
    super.key,
    this.size = 48.0,
    this.monochrome = false,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OmnyaLogoPainter(
          monochrome: monochrome,
          tintColor: tintColor,
        ),
      ),
    );
  }
}

class _OmnyaLogoPainter extends CustomPainter {
  final bool monochrome;
  final Color? tintColor;

  _OmnyaLogoPainter({
    required this.monochrome,
    this.tintColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = math.min(w, h);
    final ox = (w - s) / 2;
    final oy = (h - s) / 2;

    // Palette colors
    final plumColor = monochrome
        ? (tintColor ?? OmnyaColors.plum)
        : const Color(0xFF4B1D3F);
    final sandColor = monochrome
        ? (tintColor ?? OmnyaColors.taupe).withValues(alpha: 0.6)
        : const Color(0xFFEADFCF);
    final taupeColor = monochrome
        ? (tintColor ?? OmnyaColors.taupe).withValues(alpha: 0.8)
        : const Color(0xFFB9A995);
    final dotColor = monochrome
        ? Colors.transparent
        : const Color(0xFFF6F1E8);

    final plumPaint = Paint()
      ..color = plumColor
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final sandPaint = Paint()
      ..color = sandColor
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final taupePaint = Paint()
      ..color = taupeColor
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = dotColor
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    // 1. Plum circle (main core)
    final pc = Offset(ox + 0.557 * s, oy + 0.460 * s);
    final pr = 0.278 * s;
    canvas.drawCircle(pc, pr, plumPaint);

    // 2. Cutout dot in plum circle
    final dc = Offset(ox + 0.587 * s, oy + 0.327 * s);
    final dr = 0.039 * s;
    if (monochrome) {
      final clearPaint = Paint()..blendMode = BlendMode.clear;
      canvas.drawCircle(dc, dr, clearPaint);
    } else {
      canvas.drawCircle(dc, dr, dotPaint);
    }

    // 3. Sand circle (overlapping lower-left of plum)
    final sc = Offset(ox + 0.307 * s, oy + 0.611 * s);
    final sr = 0.209 * s;
    canvas.drawCircle(sc, sr, sandPaint);

    // 4. Taupe circle (bottom-right)
    final tc = Offset(ox + 0.824 * s, oy + 0.727 * s);
    final tr = 0.088 * s;
    canvas.drawCircle(tc, tr, taupePaint);
  }

  @override
  bool shouldRepaint(covariant _OmnyaLogoPainter oldDelegate) {
    return oldDelegate.monochrome != monochrome ||
        oldDelegate.tintColor != tintColor;
  }
}

/// Mesmerizing, smooth ambient loading indicator animating the Omnya logo circles.
/// The taupe circle orbits smoothly, the sand circle breathes, and the dot pulses.
class OmnyaLogoLoader extends StatefulWidget {
  final double size;
  final String? message;
  final bool compact;

  const OmnyaLogoLoader({
    super.key,
    this.size = 56.0,
    this.message,
    this.compact = false,
  });

  @override
  State<OmnyaLogoLoader> createState() => _OmnyaLogoLoaderState();
}

class _OmnyaLogoLoaderState extends State<OmnyaLogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final loaderWidget = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _OmnyaLogoAnimatedPainter(
            progress: _controller.value,
            isDark: isDark,
          ),
        );
      },
    );

    if (widget.compact || widget.message == null) {
      return loaderWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        loaderWidget,
        const SizedBox(height: 16),
        Text(
          widget.message!,
          style: TextStyle(
            fontFamily: 'InstrumentSans',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            color: isDark ? OmnyaColors.taupe : OmnyaColors.charcoalLight,
          ),
        ),
      ],
    );
  }
}

class _OmnyaLogoAnimatedPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0
  final bool isDark;

  _OmnyaLogoAnimatedPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = math.min(w, h);
    final ox = (w - s) / 2;
    final oy = (h - s) / 2;

    // Harmonic phases using trigonometric functions
    final t = progress * 2 * math.pi;

    // Breathing factor for sand circle (0.92 to 1.08)
    final breath = 1.0 + 0.08 * math.sin(t);

    // Subtle floating offset for plum circle
    final plumOffsetY = 0.015 * s * math.sin(t * 2);

    // Taupe orbital motion around the plum core
    // Base position is (0.824, 0.727), center of plum is (0.557, 0.460)
    final orbitRadius = 0.35 * s;
    final orbitAngle = t + 0.6;
    final taupeX = ox + 0.557 * s + orbitRadius * math.cos(orbitAngle);
    final taupeY = oy + 0.460 * s + orbitRadius * 0.75 * math.sin(orbitAngle);

    // Dot glow pulsation
    final dotPulse = 1.0 + 0.25 * math.cos(t * 2);

    final plumColor = isDark ? const Color(0xFF6B2A56) : const Color(0xFF4B1D3F);
    final sandColor = isDark ? const Color(0xFFC5B49F) : const Color(0xFFEADFCF);
    final taupeColor = isDark ? const Color(0xFF9E8A78) : const Color(0xFFB9A995);
    final dotColor = isDark ? const Color(0xFFFBF8F3) : const Color(0xFFF6F1E8);

    // 1. Plum circle
    final pc = Offset(ox + 0.557 * s, oy + 0.460 * s + plumOffsetY);
    final pr = 0.278 * s;
    canvas.drawCircle(
      pc,
      pr,
      Paint()
        ..color = plumColor
        ..isAntiAlias = true
        ..style = PaintingStyle.fill,
    );

    // 2. Cutout dot in plum circle (pulsing)
    final dc = Offset(ox + 0.587 * s, oy + 0.327 * s + plumOffsetY);
    final dr = 0.039 * s * dotPulse;
    canvas.drawCircle(
      dc,
      dr,
      Paint()
        ..color = dotColor
        ..isAntiAlias = true
        ..style = PaintingStyle.fill,
    );

    // 3. Sand circle (breathing and gently floating)
    final sc = Offset(ox + 0.307 * s, oy + 0.611 * s - plumOffsetY * 0.5);
    final sr = 0.209 * s * breath;
    canvas.drawCircle(
      sc,
      sr,
      Paint()
        ..color = sandColor.withValues(alpha: 0.95)
        ..isAntiAlias = true
        ..style = PaintingStyle.fill,
    );

    // 4. Taupe circle (orbiting)
    final tc = Offset(taupeX, taupeY);
    final tr = 0.088 * s;
    canvas.drawCircle(
      tc,
      tr,
      Paint()
        ..color = taupeColor
        ..isAntiAlias = true
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _OmnyaLogoAnimatedPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
