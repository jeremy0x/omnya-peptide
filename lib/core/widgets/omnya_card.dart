import 'package:flutter/material.dart';
import '../theme/omnya_colors.dart';

/// The one card surface: flat cream, hairline border, no gradient or glow.
class OmnyaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;

  const OmnyaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = OmnyaColors.cream,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(OmnyaRadius.card),
        border: Border.all(color: OmnyaColors.line),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
  }
}

/// Muted placeholder used wherever a photo or chart has nothing to show yet.
class OmnyaEmptyState extends StatelessWidget {
  final Widget? icon;
  final String title;
  final String? body;
  final Widget? action;

  const OmnyaEmptyState({super.key, this.icon, required this.title, this.body, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[icon!, const SizedBox(height: 12)],
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.titleSmall?.copyWith(
            fontFamily: 'InstrumentSans',
            fontWeight: FontWeight.w600,
            color: OmnyaColors.charcoal,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: 4),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'InstrumentSans',
              fontSize: 13,
              height: 1.4,
              color: OmnyaColors.charcoalLight,
            ),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    );
  }
}
