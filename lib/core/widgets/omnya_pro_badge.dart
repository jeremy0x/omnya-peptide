import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The Pro badge: light gold, used in the header and on the plans screen.
class OmnyaProBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const OmnyaProBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E4C3), // warm light gold bg
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'PRO',
        style: const TextStyle(
          fontFamily: 'InstrumentSans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6E5014), // refined deep warm gold/bronze
          letterSpacing: 0.8,
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
