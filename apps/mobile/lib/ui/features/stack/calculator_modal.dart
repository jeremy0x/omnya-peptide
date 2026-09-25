import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_copy.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';
import '../../../core/widgets/tactile_button.dart';
import '../../../domain/reconstitution_calculator.dart';

class CalculatorModal extends StatefulWidget {
  final ValueChanged<ReconstitutionResult>? onSaveToCompound;

  const CalculatorModal({super.key, this.onSaveToCompound});

  @override
  State<CalculatorModal> createState() => _CalculatorModalState();
}

class _CalculatorModalState extends State<CalculatorModal> {
  final _vialMgController = TextEditingController(text: '10');
  final _bacWaterMlController = TextEditingController(text: '2.0');
  final _targetDoseMgController = TextEditingController(text: '2.0');
  final _vialCostController = TextEditingController(text: '45.0');
  bool _useU100 = true; // true = U-100, false = U-40

  @override
  void dispose() {
    _vialMgController.dispose();
    _bacWaterMlController.dispose();
    _targetDoseMgController.dispose();
    _vialCostController.dispose();
    super.dispose();
  }

  ReconstitutionResult _result = const ReconstitutionResult(
    vialMg: 10,
    bacWaterMl: 2.0,
    targetDoseMg: 2.0,
    concentrationMgPerMl: 5.0,
    doseVolumeMl: 0.4,
    u100Units: 40.0,
    u40Units: 16.0,
    totalDosesPerVial: 5,
    costPerDose: 9.0,
  );

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  void _recalculate() {
    final vialMg = double.tryParse(_vialMgController.text) ?? 0.0;
    final bacWaterMl = double.tryParse(_bacWaterMlController.text) ?? 0.0;
    final targetDoseMg = double.tryParse(_targetDoseMgController.text) ?? 0.0;
    final vialCost = double.tryParse(_vialCostController.text) ?? 0.0;

    setState(() {
      _result = ReconstitutionCalculator.calculate(
        vialMg: vialMg,
        bacWaterMl: bacWaterMl,
        targetDoseMg: targetDoseMg,
        vialCost: vialCost,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? OmnyaColors.charcoal : OmnyaColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: OmnyaColors.taupe.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reconstitution math',
                  style: OmnyaTypography.headline(
                    color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppCopy.calculatorDisclaimer,
              style: OmnyaTypography.bodySmall(color: OmnyaColors.taupeDark),
            ),
            const SizedBox(height: 20),

            // Form Inputs Grid
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Vial quantity (mg)',
                    controller: _vialMgController,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildInputField(
                    label: 'BAC water (mL)',
                    controller: _bacWaterMlController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Target dose (mg)',
                    controller: _targetDoseMgController,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildInputField(
                    label: 'Vial cost (\$, opt)',
                    controller: _vialCostController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Syringe Type Selector
            Row(
              children: [
                Text(
                  'Syringe type: ',
                  style: OmnyaTypography.label(
                    color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                  ),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('U-100 (100u / mL)'),
                  selected: _useU100,
                  showCheckmark: false,
                  onSelected: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _useU100 = true);
                  },
                  selectedColor: OmnyaColors.plum,
                  labelStyle: TextStyle(
                    color: _useU100 ? OmnyaColors.cream : OmnyaColors.charcoal,
                    fontSize: 12,
                    fontWeight: _useU100 ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('U-40'),
                  selected: !_useU100,
                  showCheckmark: false,
                  onSelected: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _useU100 = false);
                  },
                  selectedColor: OmnyaColors.plum,
                  labelStyle: TextStyle(
                    color: !_useU100 ? OmnyaColors.cream : OmnyaColors.charcoal,
                    fontSize: 12,
                    fontWeight: !_useU100 ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Results Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF282523) : OmnyaColors.sand,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0x22FFFFFF) : OmnyaColors.sandMuted,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Draw to tick mark',
                        style: OmnyaTypography.bodyMedium(
                          color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                        ),
                      ),
                      Text(
                        '${(_useU100 ? _result.u100Units : _result.u40Units).toStringAsFixed(1)} units',
                        style: OmnyaTypography.headline(
                          color: isDark ? OmnyaColors.plumSoft : OmnyaColors.plum,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Concentration', style: OmnyaTypography.bodySmall()),
                      Text(
                        '${_result.concentrationMgPerMl.toStringAsFixed(2)} mg/mL',
                        style: OmnyaTypography.bodyMedium(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Doses per vial', style: OmnyaTypography.bodySmall()),
                      Text(
                        '${_result.totalDosesPerVial} doses',
                        style: OmnyaTypography.bodyMedium(),
                      ),
                    ],
                  ),
                  if (_result.costPerDose > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Estimated cost per dose', style: OmnyaTypography.bodySmall()),
                        Text(
                          '\$${_result.costPerDose.toStringAsFixed(2)}',
                          style: OmnyaTypography.bodyMedium(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            TactileButton(
              label: 'Done',
              variant: TactileButtonVariant.primary,
              width: double.infinity,
              onPressed: () {
                widget.onSaveToCompound?.call(_result);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OmnyaTypography.tag(color: OmnyaColors.taupeDark)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _recalculate(),
          style: OmnyaTypography.bodyLarge(
            color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: isDark ? const Color(0xFF282523) : OmnyaColors.sand,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
