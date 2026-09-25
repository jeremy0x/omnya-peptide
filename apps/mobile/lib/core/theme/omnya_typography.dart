import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'omnya_colors.dart';

abstract final class OmnyaTypography {
  // Fraunces: Serif for headlines, milestones, and big numbers
  static TextStyle displayLarge({Color color = OmnyaColors.charcoal}) =>
      GoogleFonts.fraunces(
        fontSize: 34,
        fontWeight: FontWeight.w400,
        height: 1.15,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle displayMedium({Color color = OmnyaColors.charcoal}) =>
      GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.2,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle headline({Color color = OmnyaColors.charcoal}) =>
      GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.25,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle statNumber({Color color = OmnyaColors.charcoal}) =>
      GoogleFonts.fraunces(
        fontSize: 38,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.0,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Instrument Sans: Humanist sans-serif for body, descriptions, and labels
  static TextStyle bodyLarge({Color color = OmnyaColors.charcoal}) =>
      GoogleFonts.instrumentSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: -0.1,
        color: color,
      );

  static TextStyle bodyMedium({Color color = OmnyaColors.charcoalMuted}) =>
      GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle bodySmall({Color color = OmnyaColors.charcoalLight}) =>
      GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle label({Color color = OmnyaColors.charcoal, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.instrumentSans(
        fontSize: 13,
        fontWeight: weight,
        letterSpacing: 0.2,
        color: color,
      );

  static TextStyle tag({Color color = OmnyaColors.charcoalMuted}) =>
      GoogleFonts.instrumentSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: color,
      );
}
