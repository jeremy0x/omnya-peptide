import 'package:flutter/material.dart';
import '../theme/omnya_colors.dart';

enum CompoundCategory {
  body,
  glowAndSkin,
  healAndRecover;

  String get label {
    switch (this) {
      case CompoundCategory.body:
        return 'body';
      case CompoundCategory.glowAndSkin:
        return 'glow & skin';
      case CompoundCategory.healAndRecover:
        return 'heal & recover';
    }
  }

  Color get tagColor {
    switch (this) {
      case CompoundCategory.body:
        return OmnyaColors.tagBody;
      case CompoundCategory.glowAndSkin:
        return OmnyaColors.tagGlowSkin;
      case CompoundCategory.healAndRecover:
        return OmnyaColors.tagHealRecover;
    }
  }
}

class CompoundPreset {
  final String id;
  final String name;
  final String nickname;
  final CompoundCategory category;
  final double defaultDoseMg;
  final int defaultCadenceDays;
  final String defaultRoute;

  const CompoundPreset({
    required this.id,
    required this.name,
    required this.nickname,
    required this.category,
    required this.defaultDoseMg,
    required this.defaultCadenceDays,
    this.defaultRoute = 'Subcutaneous',
  });
}

abstract final class CompoundDirectory {
  static const List<CompoundPreset> presets = [
    CompoundPreset(
      id: 'reta',
      name: 'Retatrutide',
      nickname: 'Dream bod, here we come.',
      category: CompoundCategory.body,
      defaultDoseMg: 2.0,
      defaultCadenceDays: 7,
    ),
    CompoundPreset(
      id: 'ghk_cu',
      name: 'GHK-Cu',
      nickname: 'Face card will be lethal.',
      category: CompoundCategory.glowAndSkin,
      defaultDoseMg: 1.5,
      defaultCadenceDays: 1,
    ),
    CompoundPreset(
      id: 'tirz',
      name: 'Tirzepatide / Semaglutide',
      nickname: 'The main character era.',
      category: CompoundCategory.body,
      defaultDoseMg: 2.5,
      defaultCadenceDays: 7,
    ),
    CompoundPreset(
      id: 'glow_blend',
      name: 'Glow Blend',
      nickname: 'Lit from within.',
      category: CompoundCategory.glowAndSkin,
      defaultDoseMg: 2.0,
      defaultCadenceDays: 3,
    ),
    CompoundPreset(
      id: 'klow',
      name: 'KLOW',
      nickname: 'Heal, glow, repeat.',
      category: CompoundCategory.glowAndSkin,
      defaultDoseMg: 1.0,
      defaultCadenceDays: 1,
    ),
    CompoundPreset(
      id: 'aod',
      name: 'AOD-9604',
      nickname: 'Snatched waist szn.',
      category: CompoundCategory.body,
      defaultDoseMg: 0.5,
      defaultCadenceDays: 1,
    ),
    CompoundPreset(
      id: 'bpc157',
      name: 'BPC-157',
      nickname: 'The fixer.',
      category: CompoundCategory.healAndRecover,
      defaultDoseMg: 0.5,
      defaultCadenceDays: 1,
    ),
    CompoundPreset(
      id: 'tb500',
      name: 'TB-500',
      nickname: 'Bounce back fast.',
      category: CompoundCategory.healAndRecover,
      defaultDoseMg: 2.5,
      defaultCadenceDays: 4,
    ),
    CompoundPreset(
      id: 'nad',
      name: 'NAD+',
      nickname: 'Battery at 100.',
      category: CompoundCategory.healAndRecover,
      defaultDoseMg: 50.0,
      defaultCadenceDays: 3,
    ),
    CompoundPreset(
      id: 'epithalon',
      name: 'Epithalon',
      nickname: 'Turning the clock back.',
      category: CompoundCategory.healAndRecover,
      defaultDoseMg: 10.0,
      defaultCadenceDays: 1,
    ),
    CompoundPreset(
      id: 'sermorelin',
      name: 'Sermorelin / CJC + IPA',
      nickname: 'Beauty sleep, but real.',
      category: CompoundCategory.glowAndSkin,
      defaultDoseMg: 0.3,
      defaultCadenceDays: 1,
    ),
    CompoundPreset(
      id: 'motsc',
      name: 'MOTS-c',
      nickname: 'Energy on demand.',
      category: CompoundCategory.healAndRecover,
      defaultDoseMg: 5.0,
      defaultCadenceDays: 3,
    ),
    CompoundPreset(
      id: 'melanotan',
      name: 'Melanotan II',
      nickname: 'Bronzed, no sun.',
      category: CompoundCategory.glowAndSkin,
      defaultDoseMg: 0.25,
      defaultCadenceDays: 3,
    ),
  ];
}
