import 'package:flutter/cupertino.dart';
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
        constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Outside the scroll view, so dragging the handle closes the sheet.
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: OmnyaColors.taupe.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                  child: child,
                ),
              ),
            ],
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

/// A number picked on an iOS-style wheel instead of typed. Tapping the field opens the wheel.
/// Values run from [min] to [max] in [step]s; [start] is where the wheel opens when empty.
class OmnyaWheelField extends StatelessWidget {
  final String label;
  final double? value;
  final double min;
  final double max;
  final double step;
  final double start;
  final String unit;
  final String hint;

  /// Overrides the default "12 unit" label, e.g. "every 3 days".
  final String Function(double)? format;
  final ValueChanged<double?> onChanged;

  const OmnyaWheelField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    double? start,
    this.unit = '',
    this.hint = 'Choose',
    this.format,
    required this.onChanged,
  }) : start = start ?? min;

  int get _count => ((max - min) / step).round() + 1;
  double _at(int i) => double.parse((min + i * step).toStringAsFixed(2));
  String _format(double v) => format != null ? format!(v) : _default(v);
  String _default(double v) =>
      '${v.toStringAsFixed(step < 1 ? 1 : 0).replaceFirst(RegExp(r'\.0$'), '')}${unit.isEmpty ? '' : ' $unit'}';

  Future<void> _open(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    var index = (((value ?? start) - min) / step).round().clamp(0, _count - 1);
    final result = await showPickerSheet(
      context,
      title: label,
      canClear: value != null,
      picker: CupertinoPicker(
        itemExtent: 40,
        scrollController: FixedExtentScrollController(initialItem: index),
        onSelectedItemChanged: (i) {
          HapticFeedback.selectionClick();
          index = i;
        },
        children: [for (var i = 0; i < _count; i++) Center(child: Text(_format(_at(i)), style: _wheelText))],
      ),
    );
    if (result == PickerResult.save) onChanged(_at(index));
    if (result == PickerResult.clear) onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OmnyaTypography.label(color: OmnyaColors.charcoalMuted)),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: '$label, ${value == null ? 'not set' : _format(value!)}',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => _open(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: OmnyaColors.sand,
                borderRadius: BorderRadius.circular(OmnyaRadius.control),
                border: Border.all(color: OmnyaColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value == null ? hint : _format(value!),
                      style: OmnyaTypography.bodyLarge(
                        color: value == null ? OmnyaColors.charcoalLight : OmnyaColors.charcoal,
                      ),
                    ),
                  ),
                  const Icon(Icons.unfold_more_rounded, size: 18, color: OmnyaColors.taupeDark),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final _wheelText = OmnyaTypography.bodyLarge(color: OmnyaColors.charcoal).copyWith(fontSize: 21);

enum PickerResult { save, clear }

/// iOS-style picker sheet, like the Clock app's: Cancel, title and Save over a wheel.
/// Null when she cancels or swipes it away.
Future<PickerResult?> showPickerSheet(
  BuildContext context, {
  required String title,
  required Widget picker,
  bool canClear = false,
}) {
  return showModalBottomSheet<PickerResult>(
    context: context,
    backgroundColor: OmnyaColors.cream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(OmnyaRadius.sheet))),
    builder: (ctx) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: OmnyaTypography.label(color: OmnyaColors.charcoalMuted)),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: OmnyaTypography.label(weight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(ctx, PickerResult.save);
                  },
                  child: Text(
                    'Save',
                    style: OmnyaTypography.label(color: OmnyaColors.plum, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: OmnyaColors.line),
          CupertinoTheme(
            data: CupertinoThemeData(textTheme: CupertinoTextThemeData(dateTimePickerTextStyle: _wheelText)),
            child: SizedBox(height: 216, child: picker),
          ),
          if (canClear)
            TextButton(
              onPressed: () => Navigator.pop(ctx, PickerResult.clear),
              child: Text('Clear', style: OmnyaTypography.label(color: OmnyaColors.charcoalMuted)),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// The iOS time wheel. Null when she cancels.
Future<TimeOfDay?> pickTime(BuildContext context, {required String title, required TimeOfDay initial}) async {
  var picked = DateTime(2000, 1, 1, initial.hour, initial.minute);
  final result = await showPickerSheet(
    context,
    title: title,
    picker: CupertinoDatePicker(
      mode: CupertinoDatePickerMode.time,
      initialDateTime: picked,
      onDateTimeChanged: (t) {
        HapticFeedback.selectionClick();
        picked = t;
      },
    ),
  );
  return result == PickerResult.save ? TimeOfDay(hour: picked.hour, minute: picked.minute) : null;
}

/// The iOS date wheel. Null when she cancels.
Future<DateTime?> pickDate(
  BuildContext context, {
  required String title,
  required DateTime initial,
  required DateTime first,
  required DateTime last,
}) async {
  var picked = initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial);
  final result = await showPickerSheet(
    context,
    title: title,
    picker: CupertinoDatePicker(
      mode: CupertinoDatePickerMode.date,
      initialDateTime: picked,
      minimumDate: first,
      maximumDate: last,
      onDateTimeChanged: (d) {
        HapticFeedback.selectionClick();
        picked = d;
      },
    ),
  );
  return result == PickerResult.save ? DateTime(picked.year, picked.month, picked.day) : null;
}
