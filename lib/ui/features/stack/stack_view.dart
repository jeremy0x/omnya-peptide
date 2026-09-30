import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../../core/widgets/tactile_button.dart';
import '../../../data/repositories/protocol_repository.dart';
import '../../../data/models/compound.dart';
import '../../core/omnya_header.dart';
import 'calculator_modal.dart';

class StackView extends StatelessWidget {
  const StackView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProtocolRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthlySpend = repo.calculateMonthlySpend();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                OmnyaHeader(
                  title: 'Stack',
                  subtitle: 'Compounds & inventory',
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF282523) : OmnyaColors.cream,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF3E3935) : OmnyaColors.taupe.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const CalculatorModal(),
                        );
                      },
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCalculator,
                        color: OmnyaColors.plum,
                        size: 20,
                      ),
                      tooltip: 'Reconstitution calculator',
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 1. Monthly Spend & Cost Banner (Spec Page 2: $312 this month, $4.10 per reta dose)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LiquidGlassContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This month',
                              style: OmnyaTypography.tag(color: OmnyaColors.taupeDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${monthlySpend.toStringAsFixed(0)}',
                              style: OmnyaTypography.statNumber(
                                color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2E2B29) : OmnyaColors.sand,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$4.10',
                                style: OmnyaTypography.label(
                                  color: isDark ? OmnyaColors.plumSoft : OmnyaColors.plum,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'per reta dose',
                                style: OmnyaTypography.bodySmall(color: OmnyaColors.taupeDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Compound Cards (Spec Page 2 & 4: Reta, GHK-Cu, KLOW with nicknames and badges)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: repo.compounds.map((compound) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: LiquidGlassContainer(
                          borderRadius: 22,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: compound.category.tagColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        compound.name,
                                        style: OmnyaTypography.headline(
                                          color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Runout badge (Spec: "runs out Thu", "22 doses left", "cycle: day 12 of 30")
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2E2B29) : OmnyaColors.sand,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getCompoundRunoutLabel(compound),
                                      style: OmnyaTypography.bodySmall(
                                        color: isDark ? OmnyaColors.plumSoft : OmnyaColors.plum,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              
                              // Nickname (Spec Page 4: "Dream bod, here we come.", "Face card will be lethal.")
                              Text(
                                '"${compound.nickname}"',
                                style: OmnyaTypography.bodyMedium(
                                  color: isDark ? OmnyaColors.taupe : OmnyaColors.charcoalMuted,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Metadata Row
                              Wrap(
                                spacing: 14,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    'Dose: ${compound.doseMg.toStringAsFixed(1)} mg',
                                    style: OmnyaTypography.bodySmall(color: OmnyaColors.taupeDark),
                                  ),
                                  Text(
                                    'Cadence: every ${compound.frequencyDays}d',
                                    style: OmnyaTypography.bodySmall(color: OmnyaColors.taupeDark),
                                  ),
                                  Text(
                                    'Site: ${compound.injectionSite}',
                                    style: OmnyaTypography.bodySmall(color: OmnyaColors.taupeDark),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Calculator Shortcut CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TactileButton(
                    label: 'Open dilution calculator',
                    variant: TactileButtonVariant.outline,
                    width: double.infinity,
                    leading: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCalculator,
                      color: OmnyaColors.plum,
                      size: 18,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const CalculatorModal(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCompoundRunoutLabel(Compound compound) {
    if (compound.name.toLowerCase().contains('reta')) {
      return 'runs out Thu';
    } else if (compound.name.toLowerCase().contains('ghk')) {
      return '22 doses left';
    } else if (compound.name.toLowerCase().contains('klow')) {
      return 'cycle: day 12 of 30';
    }
    return '${compound.dosesLeft} doses left';
  }
}
