import 'package:flutter/material.dart';

/// Omnya design system palette: Warm minimal.
/// Skincare brand meets a very clean fitness app. Comfortable to open in a café.
abstract final class OmnyaColors {
  // Foundational brand palette
  static const Color cream = Color(0xFFFDFBF7);
  static const Color sand = Color(0xFFF4EFEA);
  static const Color sandMuted = Color(0xFFEBE3DB);
  static const Color taupe = Color(0xFFB5A496);
  static const Color taupeDark = Color(0xFF8C7A6B);
  
  // Hero plum accents
  static const Color plum = Color(0xFF4A1E35);
  static const Color plumDeep = Color(0xFF361325);
  static const Color plumSoft = Color(0xFF7A4B64);
  static const Color plumSubtle = Color(0xFFF2EAF0);

  // Typography & Dark Mode base
  static const Color charcoal = Color(0xFF1F1D1C);
  static const Color charcoalMuted = Color(0xFF5A5552);
  static const Color charcoalLight = Color(0xFF8F8884);

  // Category Tag Colors (Spec Page 4)
  static const Color sage = Color(0xFF4E7A5D);      // Calm sage: success / synced
  static const Color tagBody = plum;           // Plum: body
  static const Color tagGlowSkin = plumSoft;    // Soft plum: glow and skin
  static const Color tagHealRecover = taupeDark;// Taupe: heal and recover

  // Glassmorphism overlays
  static const Color glassFill = Color(0x99FFFFFF);
  static const Color glassBorder = Color(0x33B5A496);
  static const Color glassHighlight = Color(0x80FFFFFF);
}
