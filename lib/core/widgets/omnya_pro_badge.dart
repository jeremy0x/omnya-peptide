import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The Pro badge: light gold, used in the header and on the plans screen.
/// [label] swaps the text, e.g. "Upgrade" for people not on Pro yet.
class OmnyaProBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;

  const OmnyaProBadge({super.key, this.onTap, this.label = 'PRO'});

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E4C3), // warm light gold bg
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'InstrumentSans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6E5014), // refined deep warm gold/bronze
          // Tracking suits the all-caps PRO, not a word like Upgrade.
          letterSpacing: label == label.toUpperCase() ? 0.8 : 0,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }

    return badge;
  }
}
