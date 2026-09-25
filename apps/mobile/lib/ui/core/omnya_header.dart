import 'package:flutter/material.dart';
import '../../core/theme/omnya_typography.dart';
import '../../core/theme/omnya_colors.dart';
import '../../core/widgets/omnya_logo.dart';

class OmnyaHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showLogo;
  final VoidCallback? onLogoTap;

  const OmnyaHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showLogo = false,
    this.onLogoTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subtitle != null) ...[
                  Text(
                    subtitle!,
                    style: OmnyaTypography.tag(
                      color: isDark ? OmnyaColors.taupe : OmnyaColors.charcoalLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showLogo) ...[
                      GestureDetector(
                        onTap: onLogoTap,
                        behavior: HitTestBehavior.opaque,
                        child: const OmnyaLogo(size: 26),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: OmnyaTypography.displayMedium(
                          color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
