import 'package:flutter/material.dart';
import 'omnya_colors.dart';

/// Fraunces for headlines, milestones and big numbers; Instrument Sans for
/// everything else. Both are bundled in assets/fonts, so nothing downloads at runtime.
abstract final class OmnyaTypography {
  static const _serif = 'Fraunces';
  static const _sans = 'InstrumentSans';

  static TextStyle displayLarge({Color color = OmnyaColors.charcoal}) => TextStyle(
    fontFamily: _serif,
    fontSize: 34,
    fontWeight: FontWeight.w400,
    height: 1.15,
    letterSpacing: -0.5,
    color: color,
  );

  static TextStyle displayMedium({Color color = OmnyaColors.charcoal}) => TextStyle(
    fontFamily: _serif,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: -0.3,
    color: color,
  );

  static TextStyle headline({Color color = OmnyaColors.charcoal}) => TextStyle(
    fontFamily: _serif,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: -0.2,
    color: color,
  );

  static TextStyle statNumber({Color color = OmnyaColors.charcoal}) => TextStyle(
    fontFamily: _serif,
    fontSize: 38,
    fontWeight: FontWeight.w300,
    height: 1.1,
    letterSpacing: -1.0,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle bodyLarge({Color color = OmnyaColors.charcoal}) => TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: -0.1,
    color: color,
  );

  static TextStyle bodyMedium({Color color = OmnyaColors.charcoalMuted}) =>
      TextStyle(fontFamily: _sans, fontSize: 14, fontWeight: FontWeight.w400, height: 1.45, color: color);

  static TextStyle bodySmall({Color color = OmnyaColors.charcoalLight}) => TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.1,
    color: color,
  );

  static TextStyle label({Color color = OmnyaColors.charcoal, FontWeight weight = FontWeight.w500}) =>
      TextStyle(fontFamily: _sans, fontSize: 13, fontWeight: weight, letterSpacing: 0.2, color: color);

  static TextStyle tag({Color color = OmnyaColors.charcoalMuted}) =>
      TextStyle(fontFamily: _sans, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3, color: color);
}
