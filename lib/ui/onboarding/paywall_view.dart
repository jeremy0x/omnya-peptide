import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/omnya_colors.dart';
import '../../core/theme/omnya_typography.dart';
import '../../core/widgets/omnya_card.dart';
import '../../core/widgets/omnya_pro_badge.dart';
import '../../core/widgets/tactile_button.dart';

/// Plans from spec page 8. Purchases are switched off until in-app purchase is
/// connected, so nothing here can charge her or unlock anything.
class PaywallView extends StatefulWidget {
  const PaywallView({super.key});

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  int _plan = 1; // yearly is shown first (spec)

  static const _plans = [
    (name: 'Monthly', price: r'$9.99', note: 'per month'),
    (name: 'Yearly', price: r'$49.99', note: 'per year, 7-day trial'),
    (name: 'Lifetime', price: r'$99', note: 'one time'),
  ];

  static const _pro = [
    'Unlimited compounds',
    'Weekly photo read and trend scores',
    'Cycle-aware weight insights',
    'Watermark-free progress cards',
    'Circles',
    'Vial cost, runout and reorder',
  ];

  static const _free = ['Mixing calculator', 'Up to 2 compounds', 'Weight and daily check-ins'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: OmnyaColors.charcoal, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          children: [
            Text('Free users log.\nPro users learn.', style: OmnyaTypography.displayLarge()),
            const SizedBox(height: 20),
            Row(
              children: [
                for (var i = 0; i < _plans.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _PlanCard(plan: _plans[i], selected: _plan == i, onTap: () => setState(() => _plan = i)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            OmnyaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Pro', style: OmnyaTypography.label(weight: FontWeight.w600)),
                      ),
                      const OmnyaProBadge(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final f in _pro) _Feature(f),
                  const Divider(height: 28),
                  Text('Free', style: OmnyaTypography.label(weight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  for (final f in _free) _Feature(f, muted: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const TactileButton(label: 'Pro opens soon', width: double.infinity, onPressed: null),
            const SizedBox(height: 10),
            Text(
              "Purchases aren't available yet. Nothing is charged and the app keeps working.",
              textAlign: TextAlign.center,
              style: OmnyaTypography.bodySmall(),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Text(
                'Continue',
                style: OmnyaTypography.label(color: OmnyaColors.plum, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ({String name, String price, String note}) plan;
  final bool selected;
  final VoidCallback onTap;
  const _PlanCard({required this.plan, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? OmnyaColors.plumSubtle : OmnyaColors.cream,
            borderRadius: BorderRadius.circular(OmnyaRadius.control),
            border: Border.all(color: selected ? OmnyaColors.plum : OmnyaColors.line, width: 1.5),
          ),
          child: Column(
            children: [
              Text(plan.name, style: OmnyaTypography.tag(color: OmnyaColors.taupeDark)),
              const SizedBox(height: 4),
              Text(
                plan.price,
                style: OmnyaTypography.headline(color: selected ? OmnyaColors.plum : OmnyaColors.charcoal),
              ),
              const SizedBox(height: 2),
              Text(plan.note, textAlign: TextAlign.center, style: OmnyaTypography.bodySmall()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final String text;
  final bool muted;
  const _Feature(this.text, {this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCheckmarkBadge03,
            color: muted ? OmnyaColors.taupeDark : OmnyaColors.plum,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: OmnyaTypography.bodyMedium(color: OmnyaColors.charcoal)),
          ),
        ],
      ),
    );
  }
}
