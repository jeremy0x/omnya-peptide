import 'package:flutter/material.dart';

/// Warm minimal palette from the product spec: cream, sand, taupe, plum, charcoal.
/// Text tokens are tuned to pass WCAG AA (4.5:1) on sand and cream.
abstract final class OmnyaColors {
  static const Color cream = Color(0xFFFDFBF7); // cards and sheets
  static const Color sand = Color(0xFFF4EFEA); // app canvas
  static const Color sandMuted = Color(0xFFEBE3DB); // inset fields, unselected chips
  static const Color taupe = Color(0xFFB5A496); // decorative only, never text
  static const Color taupeDark = Color(0xFF72635A); // secondary labels

  static const Color plum = Color(0xFF4A1E35);
  static const Color plumDeep = Color(0xFF361325);
  static const Color plumSoft = Color(0xFF7A4B64);
  static const Color plumSubtle = Color(0xFFF2EAF0);

  static const Color charcoal = Color(0xFF1F1D1C);
  static const Color charcoalMuted = Color(0xFF5A5552);
  static const Color charcoalLight = Color(0xFF6E6763);

  /// Hairline borders and dividers.
  static const Color line = Color(0x1A1F1D1C);

  /// Form errors only. Weight going up is never shown in this colour.
  static const Color error = Color(0xFF9F2F2D);

  // Category colours (spec page 4).
  static const Color tagBody = plum;
  static const Color tagGlowSkin = plumSoft;
  static const Color tagHealRecover = taupeDark;
}

/// One radius scale for the whole app.
abstract final class OmnyaRadius {
  static const double card = 20;
  static const double control = 14;
  static const double chip = 10;
  static const double sheet = 24;
}
