import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'omnya_colors.dart';

abstract final class OmnyaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: OmnyaColors.sand,
      primaryColor: OmnyaColors.plum,
      colorScheme: const ColorScheme.light(
        primary: OmnyaColors.plum,
        secondary: OmnyaColors.taupeDark,
        surface: Colors.white,
        onSurface: OmnyaColors.charcoal,
        outline: Color(0x18000000),
        outlineVariant: Color(0x0E000000),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      dividerColor: const Color(0x0E000000),
      dividerTheme: const DividerThemeData(
        color: Color(0x0E000000),
        thickness: 0.75,
        space: 24,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: OmnyaColors.charcoal,
      primaryColor: OmnyaColors.plumSoft,
      colorScheme: const ColorScheme.dark(
        primary: OmnyaColors.plumSoft,
        secondary: OmnyaColors.taupe,
        surface: OmnyaColors.charcoal,
        onSurface: OmnyaColors.cream,
        outline: Color(0x22FFFFFF),
        outlineVariant: Color(0x14FFFFFF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      dividerColor: const Color(0x14FFFFFF),
      dividerTheme: const DividerThemeData(
        color: Color(0x14FFFFFF),
        thickness: 0.75,
        space: 24,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}
