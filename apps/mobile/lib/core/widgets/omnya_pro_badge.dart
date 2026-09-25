import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/omnya_colors.dart';

/// Reusable PRO pill badge ensuring 100% visual consistency across all views.
class OmnyaProBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const OmnyaProBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: OmnyaColors.plumSoft.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'PRO',
        style: GoogleFonts.instrumentSans(
          fontSize: 11,
          fontWeight: FontWeight.w300,
          color: isDark ? OmnyaColors.plumSoft : OmnyaColors.plum,
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
