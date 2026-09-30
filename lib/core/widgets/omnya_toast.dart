import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/omnya_colors.dart';

enum OmnyaToastType { success, info, warning, error }

/// A short note at the top of the screen, on native glass.
class OmnyaToast {
  static void show(
    BuildContext context, {
    required String title,
    String? message,
    OmnyaToastType type = OmnyaToastType.success,
  }) {
    HapticFeedback.lightImpact();
    CNToast.show(
      context: context,
      message: message == null || message.isEmpty ? title : '$title\n$message',
      position: CNToastPosition.top,
      duration: type == OmnyaToastType.error ? CNToastDuration.long : CNToastDuration.medium,
      style: switch (type) {
        OmnyaToastType.success => CNToastStyle.success,
        OmnyaToastType.info => CNToastStyle.normal,
        OmnyaToastType.warning => CNToastStyle.warning,
        OmnyaToastType.error => CNToastStyle.error,
      },
      textColor: OmnyaColors.charcoal,
    );
  }
}
