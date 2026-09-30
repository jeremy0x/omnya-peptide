import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/omnya_colors.dart';
import '../../core/theme/omnya_typography.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/tactile_button.dart';
import '../../core/widgets/omnya_pro_badge.dart';
import '../../core/widgets/omnya_toast.dart';
import '../../data/repositories/protocol_repository.dart';

class PaywallView extends StatefulWidget {
  final VoidCallback? onCompleted;

  const PaywallView({super.key, this.onCompleted});

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  int _selectedTier = 1; // 0 = monthly, 1 = yearly (recommended), 2 = lifetime

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProtocolRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
            size: 22,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onCompleted?.call();
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onCompleted?.call();
              Navigator.pop(context);
            },
            child: Text(
              'Skip for now',
              style: OmnyaTypography.bodySmall(color: OmnyaColors.taupeDark),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                Text(
                  'Free users log.\nPro users learn.',
                  style: OmnyaTypography.displayLarge(
                    color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock the outcome engine, facial reads, and cycle-aware intelligence.',
                  style: OmnyaTypography.bodyLarge(
                    color: isDark ? OmnyaColors.taupe : OmnyaColors.charcoalMuted,
                  ),
                ),
                const SizedBox(height: 24),

                // Pricing Tiers (Spec Page 8: $9.99, $49.99, $99)
                Row(
                  children: [
                    Expanded(
                      child: _buildTierCard(
                        title: 'Monthly',
                        price: '\$9.99',
                        period: 'per month',
                        index: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTierCard(
                        title: 'Yearly',
                        price: '\$49.99',
                        period: '7-day trial',
                        index: 1,
                        isHero: true,
                        badge: 'BEST VALUE',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTierCard(
                        title: 'Lifetime',
                        price: '\$99',
                        period: 'one-time',
                        index: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Feature Comparison Matrix
                LiquidGlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildFeatureRow('Outcome correlation engine (Day 14+)', isProOnly: true),
                      _buildFeatureRow('Photo intelligence & trend scoring', isProOnly: true),
                      _buildFeatureRow('Cycle-aware weight & hormone insights', isProOnly: true),
                      _buildFeatureRow('Watermark-free 9:16 export cards', isProOnly: true),
                      _buildFeatureRow('Accountability Circles (up to 5)', isProOnly: true),
                      _buildFeatureRow('Dilution math calculator', isProOnly: false),
                      _buildFeatureRow('One-tap dose tracking', isProOnly: false),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Subscribe CTA
                TactileButton(
                  label: _selectedTier == 1 ? 'Start 7-day free trial' : 'Continue with Pro',
                  variant: TactileButtonVariant.primary,
                  height: 56,
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    await repo.setPro(true);
                    widget.onCompleted?.call();
                    nav.pop();
                    if (context.mounted) {
                      OmnyaToast.show(
                        context,
                        title: 'Welcome to Omnya Pro',
                        message: 'Unlimited protocols, advanced biomarkers & analytics unlocked.',
                        type: OmnyaToastType.success,
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Cancel anytime in App Store settings. No commitment.',
                    style: OmnyaTypography.bodySmall(color: OmnyaColors.taupeDark),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required String title,
    required String price,
    required String period,
    required int index,
    bool isHero = false,
    String? badge,
  }) {
    final isSelected = _selectedTier == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTier = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? OmnyaColors.plumSoft.withValues(alpha: 0.2) : OmnyaColors.plumSubtle)
              : (isDark ? const Color(0xFF282523) : OmnyaColors.cream),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? OmnyaColors.plum
                : (isDark ? const Color(0xFF38332E) : OmnyaColors.taupe.withValues(alpha: 0.35)),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: OmnyaColors.plum.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: OmnyaColors.plum,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: OmnyaColors.cream,
                  ),
                ),
              ),
            Text(title, style: OmnyaTypography.tag(color: OmnyaColors.taupeDark)),
            const SizedBox(height: 4),
            Text(
              price,
              style: OmnyaTypography.headline(
                color: isSelected ? OmnyaColors.plum : (isDark ? OmnyaColors.cream : OmnyaColors.charcoal),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              period,
              style: OmnyaTypography.bodySmall(color: OmnyaColors.taupeDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text, {required bool isProOnly}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCheckmarkBadge03,
            color: isProOnly ? OmnyaColors.plum : OmnyaColors.taupeDark,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: OmnyaTypography.bodyMedium(),
            ),
          ),
          if (isProOnly)
            const OmnyaProBadge(),
        ],
      ),
    );
  }
}
