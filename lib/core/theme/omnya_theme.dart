import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'omnya_colors.dart';

/// Light only: dark mode was switched off on purpose, it read badly on devices.
abstract final class OmnyaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'InstrumentSans',
      scaffoldBackgroundColor: OmnyaColors.sand,
      primaryColor: OmnyaColors.plum,
      colorScheme: const ColorScheme.light(
        primary: OmnyaColors.plum,
        secondary: OmnyaColors.taupeDark,
        surface: OmnyaColors.cream,
        onSurface: OmnyaColors.charcoal,
        error: OmnyaColors.error,
        outline: OmnyaColors.line,
        outlineVariant: OmnyaColors.line,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      dividerTheme: const DividerThemeData(color: OmnyaColors.line, thickness: 1, space: 24),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: OmnyaColors.plum,
        selectionHandleColor: OmnyaColors.plum,
      ),
      datePickerTheme: const DatePickerThemeData(backgroundColor: OmnyaColors.cream),
      dialogTheme: const DialogThemeData(backgroundColor: OmnyaColors.cream),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}
