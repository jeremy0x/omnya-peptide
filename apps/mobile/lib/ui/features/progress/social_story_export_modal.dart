import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';
import '../../../core/widgets/tactile_button.dart';

class SocialStoryExportModal extends StatelessWidget {
  final bool isPro;

  const SocialStoryExportModal({super.key, this.isPro = false});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 9:16 Story Card Canvas
              AspectRatio(
                aspectRatio: 9 / 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: OmnyaColors.plum,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: OmnyaColors.plumDeep.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top header tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Week 6 · Reta + GHK-Cu',
                            style: OmnyaTypography.tag(
                              color: OmnyaColors.sandMuted.withValues(alpha: 0.8),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'face blurred',
                              style: OmnyaTypography.tag(color: OmnyaColors.cream),
                            ),
                          ),
                        ],
                      ),

                      // Headline
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Down 9 lb.\nSkin\'s\nglowing.',
                            style: OmnyaTypography.displayLarge(color: OmnyaColors.cream),
                          ),
                        ],
                      ),

                      // Stats Footer
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Waist', style: OmnyaTypography.bodySmall(color: OmnyaColors.sandMuted)),
                                    const SizedBox(height: 2),
                                    Text('-2.5 in', style: OmnyaTypography.label(color: OmnyaColors.cream)),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Doses kept', style: OmnyaTypography.bodySmall(color: OmnyaColors.sandMuted)),
                                    const SizedBox(height: 2),
                                    Text('41 of 42', style: OmnyaTypography.label(color: OmnyaColors.cream)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Brand wordmark bottom corner
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isPro ? '' : 'made with Omnya',
                                style: OmnyaTypography.bodySmall(
                                  color: OmnyaColors.sandMuted.withValues(alpha: 0.6),
                                ),
                              ),
                              Text(
                                'omnya.app',
                                style: OmnyaTypography.bodySmall(
                                  color: OmnyaColors.sandMuted.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TactileButton(
                      label: 'Save & share',
                      variant: TactileButtonVariant.primary,
                      leading: const HugeIcon(
                        icon: HugeIcons.strokeRoundedShare01,
                        color: OmnyaColors.cream,
                        size: 18,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('9:16 progress card ready for Instagram / TikTok stories!'),
                            backgroundColor: OmnyaColors.plum,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: OmnyaColors.cream,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: OmnyaColors.charcoal.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
