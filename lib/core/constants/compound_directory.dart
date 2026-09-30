import 'package:flutter/material.dart';
import '../theme/omnya_colors.dart';

enum CompoundCategory {
  body,
  glowAndSkin,
  healAndRecover;

  String get label => switch (this) {
    CompoundCategory.body => 'body',
    CompoundCategory.glowAndSkin => 'glow & skin',
    CompoundCategory.healAndRecover => 'heal & recover',
  };

  Color get tagColor => switch (this) {
    CompoundCategory.body => OmnyaColors.tagBody,
    CompoundCategory.glowAndSkin => OmnyaColors.tagGlowSkin,
    CompoundCategory.healAndRecover => OmnyaColors.tagHealRecover,
  };
}

/// Names and nicknames from spec page 4. There are deliberately no doses or
/// schedules here: she enters both herself (App Store rule, spec page 11).
class CompoundPreset {
  final String name;
  final String nickname;
  final CompoundCategory category;

  const CompoundPreset(this.name, this.nickname, this.category);
}

abstract final class CompoundDirectory {
  static const presets = [
    CompoundPreset('Retatrutide', 'Dream bod, here we come.', CompoundCategory.body),
    CompoundPreset('GHK-Cu', 'Face card will be lethal.', CompoundCategory.glowAndSkin),
    CompoundPreset('Tirzepatide', 'The main character era.', CompoundCategory.body),
    CompoundPreset('Semaglutide', 'The main character era.', CompoundCategory.body),
    CompoundPreset('Glow blend', 'Lit from within.', CompoundCategory.glowAndSkin),
    CompoundPreset('KLOW', 'Heal, glow, repeat.', CompoundCategory.glowAndSkin),
    CompoundPreset('AOD-9604', 'Snatched waist szn.', CompoundCategory.body),
    CompoundPreset('BPC-157', 'The fixer.', CompoundCategory.healAndRecover),
    CompoundPreset('TB-500', 'Bounce back fast.', CompoundCategory.healAndRecover),
    CompoundPreset('NAD+', 'Battery at 100.', CompoundCategory.healAndRecover),
    CompoundPreset('Epithalon', 'Turning the clock back.', CompoundCategory.healAndRecover),
    CompoundPreset('Sermorelin / CJC + IPA', 'Beauty sleep, but real.', CompoundCategory.glowAndSkin),
    CompoundPreset('MOTS-c', 'Energy on demand.', CompoundCategory.healAndRecover),
    CompoundPreset('Melanotan II', 'Bronzed, no sun.', CompoundCategory.glowAndSkin),
  ];

  static CompoundPreset? find(String name) {
    final key = name.trim().toLowerCase();
    for (final p in presets) {
      if (p.name.toLowerCase() == key) return p;
    }
    return null;
  }

  /// What she'd say out loud: "Reta, 2 mg".
  static String shortName(String name) =>
      const {'Retatrutide': 'Reta', 'Tirzepatide': 'Tirz', 'Semaglutide': 'Sema'}[name] ?? name;
}
