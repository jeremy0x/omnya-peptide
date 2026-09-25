import 'dart:ui';
import 'package:flutter/material.dart';

/// Rec. 709 saturation matrix for ColorFilter.matrix.
/// s > 1 boosts saturation, s == 1 is identity, s == 0 is grayscale.
List<double> _saturationMatrix(double s) {
  const lumR = 0.2126, lumG = 0.7152, lumB = 0.0722;
  final ir = (1 - s) * lumR, ig = (1 - s) * lumG, ib = (1 - s) * lumB;
  return <double>[
    ir + s, ig,     ib,     0, 0,
    ir,     ig + s, ib,     0, 0,
    ir,     ig,     ib + s, 0, 0,
    0,      0,      0,      1, 0,
  ];
}

/// Liquid glass container featuring optical refraction, frosted backdrop blur,
/// Rec. 709 saturation pickup, top-light specular crown, and outer cast shadow.
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final double blurAmount;
  final double saturation;
  final Border? border;
  final VoidCallback? onTap;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.tintColor,
    this.blurAmount = 18.0,
    this.saturation = 1.4,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(borderRadius);

    final defaultTint = isDark
        ? const Color(0xBF25211F)
        : const Color(0xE6FFFFFF);

    // Cast shadow placed OUTSIDE ClipRRect so the glass floats above canvas
    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0x38000000)
                : const Color(0x0C000000),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: isDark
                ? const Color(0x18000000)
                : const Color(0x061F1D1C),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          // Compose blur with saturation boost so the glass picks up background tones
          filter: ImageFilter.compose(
            outer: ColorFilter.matrix(_saturationMatrix(saturation)),
            inner: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: shape,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.09 : 0.55),
                  tintColor ?? defaultTint,
                  Colors.white.withValues(alpha: isDark ? 0.02 : 0.15),
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
              border: border ??
                  Border.all(
                    color: isDark
                        ? const Color(0x1FFFFFFF)
                        : const Color(0x28000000),
                    width: 0.75,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
