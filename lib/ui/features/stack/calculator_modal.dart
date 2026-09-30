import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_copy.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';
import '../../../core/widgets/omnya_controls.dart';
import '../../../core/widgets/tactile_button.dart';
import '../../../domain/reconstitution_calculator.dart';

/// Unit math for a mixed vial. The fields start empty so the app never proposes a dose.
/// With [forCompound], returns the result for the compound being edited.
Future<ReconstitutionResult?> showCalculator(BuildContext context, {double? targetDoseMg, bool forCompound = false}) =>
    showOmnyaSheet<ReconstitutionResult>(
      context,
      builder: (_) => _Calculator(targetDoseMg: targetDoseMg, forCompound: forCompound),
    );

class _Calculator extends StatefulWidget {
  final double? targetDoseMg;
  final bool forCompound;
  const _Calculator({this.targetDoseMg, required this.forCompound});

  @override
  State<_Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<_Calculator> {
  final _vialMg = TextEditingController();
  final _water = TextEditingController();
  late final _dose = TextEditingController(
    text: widget.targetDoseMg == null ? '' : widget.targetDoseMg.toString().replaceFirst(RegExp(r'\.0$'), ''),
  );
  final _vialCost = TextEditingController();
  bool _u100 = true;

  @override
  void dispose() {
    for (final c in [_vialMg, _water, _dose, _vialCost]) {
      c.dispose();
    }
    super.dispose();
  }

  ReconstitutionResult get _result => ReconstitutionCalculator.calculate(
    vialMg: parseNumber(_vialMg.text) ?? 0,
    bacWaterMl: parseNumber(_water.text) ?? 0,
    targetDoseMg: parseNumber(_dose.text) ?? 0,
    vialCost: parseNumber(_vialCost.text.replaceAll(r'$', '')) ?? 0,
  );

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final ready = r.totalDosesPerVial > 0;
    void recalc(String _) => setState(() {});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Mixing math', style: OmnyaTypography.headline()),
        const SizedBox(height: 6),
        Text(AppCopy.calculatorDisclaimer, style: OmnyaTypography.bodySmall()),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OmnyaField.number(label: 'Powder in vial', controller: _vialMg, suffix: 'mg', onChanged: recalc),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OmnyaField.number(label: 'Water added', controller: _water, suffix: 'mL', onChanged: recalc),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OmnyaField.number(label: 'Your dose', controller: _dose, suffix: 'mg', onChanged: recalc),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OmnyaField.number(
                label: 'Vial cost (optional)',
                controller: _vialCost,
                hint: r'$',
                onChanged: recalc,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Syringe', style: OmnyaTypography.label(color: OmnyaColors.charcoalMuted)),
            const Spacer(),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: true, label: Text('U-100')),
                ButtonSegment(value: false, label: Text('U-40')),
              ],
              selected: {_u100},
              onSelectionChanged: (s) {
                HapticFeedback.selectionClick();
                setState(() => _u100 = s.first);
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: OmnyaColors.plum,
                selectedForegroundColor: OmnyaColors.cream,
                foregroundColor: OmnyaColors.charcoal,
                side: const BorderSide(color: OmnyaColors.line),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: OmnyaColors.sand, borderRadius: BorderRadius.circular(OmnyaRadius.card)),
          child: ready
              ? Column(
                  children: [
                    _Row('Draw to', '${(_u100 ? r.u100Units : r.u40Units).toStringAsFixed(1)} units', big: true),
                    const Divider(height: 24),
                    _Row('Strength', '${r.concentrationMgPerMl.toStringAsFixed(2)} mg per mL'),
                    const SizedBox(height: 6),
                    _Row('Doses in this vial', '${r.totalDosesPerVial}'),
                    if (r.costPerDose > 0) ...[
                      const SizedBox(height: 6),
                      _Row('Cost per dose', '\$${r.costPerDose.toStringAsFixed(2)}'),
                    ],
                    // A 1 mL syringe holds 100 units (U-100) or 40 units (U-40).
                    if ((_u100 ? r.u100Units : r.u40Units) > (_u100 ? 100 : 40)) ...[
                      const SizedBox(height: 12),
                      const OmnyaInlineError(
                        "That's more than a 1 mL syringe holds. Check the water and dose you entered.",
                      ),
                    ],
                  ],
                )
              : Text(
                  'Fill in the powder, water and your dose to see the syringe units.',
                  style: OmnyaTypography.bodyMedium(),
                ),
        ),
        const SizedBox(height: 20),
        widget.forCompound
            ? TactileButton(
                label: 'Use these numbers',
                width: double.infinity,
                onPressed: ready ? () => Navigator.pop(context, r) : null,
              )
            : TactileButton(
                label: 'Done',
                variant: TactileButtonVariant.secondary,
                width: double.infinity,
                onPressed: () => Navigator.pop(context),
              ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool big;
  const _Row(this.label, this.value, {this.big = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: OmnyaTypography.bodyMedium()),
        Text(
          value,
          style: big
              ? OmnyaTypography.headline(color: OmnyaColors.plum)
              : OmnyaTypography.bodyMedium(color: OmnyaColors.charcoal),
        ),
      ],
    );
  }
}
