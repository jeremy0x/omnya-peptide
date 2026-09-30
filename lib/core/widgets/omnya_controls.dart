import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/omnya_colors.dart';
import '../theme/omnya_typography.dart';

/// Bottom sheet with the app's handle, padding and keyboard inset.
Future<T?> showOmnyaSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _OmnyaSheet(child: builder(ctx)),
  );
}

class _OmnyaSheet extends StatelessWidget {
  final Widget child;
  const _OmnyaSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // A Material surface (not a coloured box) so list rows and ink inside behave.
    return Material(
      color: OmnyaColors.cream,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(OmnyaRadius.sheet))),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: OmnyaColors.taupe.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round 44pt header button.
class OmnyaIconButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Widget? child;

  const OmnyaIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed, this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: OmnyaColors.cream,
            shape: BoxShape.circle,
            border: Border.all(color: OmnyaColors.line),
          ),
          child: child ?? HugeIcon(icon: icon, color: OmnyaColors.plum, size: 20),
        ),
      ),
    );
  }
}

/// Label above the input, helper or error below it.
class OmnyaField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? suffix;
  final String? error;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const OmnyaField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.suffix,
    this.error,
    this.keyboardType,
    this.maxLength,
    this.capitalization = TextCapitalization.none,
    this.onChanged,
    this.autofocus = false,
  });

  const OmnyaField.number({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.suffix,
    this.error,
    this.onChanged,
    this.autofocus = false,
  }) : keyboardType = const TextInputType.numberWithOptions(decimal: true),
       maxLength = null,
       capitalization = TextCapitalization.none;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(OmnyaRadius.control),
      borderSide: BorderSide(color: error == null ? OmnyaColors.line : OmnyaColors.error),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OmnyaTypography.label(color: OmnyaColors.charcoalMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          textCapitalization: capitalization,
          autofocus: autofocus,
          onChanged: onChanged,
          // Number pads have no Done key, so a tap elsewhere closes the keyboard.
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          style: OmnyaTypography.bodyLarge(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: OmnyaTypography.bodyLarge(color: OmnyaColors.charcoalLight),
            suffixText: suffix,
            suffixStyle: OmnyaTypography.bodyMedium(),
            counterText: '',
            isDense: true,
            filled: true,
            fillColor: OmnyaColors.sand,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: error == null ? OmnyaColors.plum : OmnyaColors.error, width: 1.5),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error!, style: OmnyaTypography.bodySmall(color: OmnyaColors.error)),
        ],
      ],
    );
  }
}

/// Parses "2", "2.5" or "2,5". Null for empty or invalid input.
double? parseNumber(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

/// A problem worth reading, said once, next to the thing it is about.
class OmnyaInlineError extends StatelessWidget {
  final String message;
  const OmnyaInlineError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: HugeIcon(icon: HugeIcons.strokeRoundedAlertCircle, color: OmnyaColors.error, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: OmnyaTypography.bodySmall(color: OmnyaColors.error)),
          ),
        ],
      ),
    );
  }
}
