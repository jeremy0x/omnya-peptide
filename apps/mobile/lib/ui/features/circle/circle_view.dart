import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../../core/widgets/tactile_button.dart';
import '../../../data/repositories/protocol_repository.dart';
import '../../core/omnya_header.dart';

class CircleView extends StatefulWidget {
  const CircleView({super.key});

  @override
  State<CircleView> createState() => _CircleViewState();
}

class _CircleViewState extends State<CircleView> {
  final _inviteController = TextEditingController();

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProtocolRepository>();
    final circle = repo.circle;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final members = circle?.members ?? [];
    final checkedInCount = circle?.checkedInCount ?? 4;
    final totalCount = members.isNotEmpty ? members.length : 5;

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
                  title: 'Circle',
                  subtitle: 'Accountability group',
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
                        _showInviteDialog(context, circle?.inviteCode ?? 'OMNYA');
                      },
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedUserAdd01,
                        color: OmnyaColors.plum,
                        size: 20,
                      ),
                      tooltip: 'Invite a friend',
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 1. Avatar Status Row (Spec Page 2: S M J A, 4 of 5 checked in today)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LiquidGlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    child: Column(
                      children: [
                        // Avatar Row with check status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: members.map((member) {
                            return Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: member.checkedInToday
                                            ? (isDark ? OmnyaColors.plumSoft : OmnyaColors.plum)
                                            : (isDark ? const Color(0xFF2E2B29) : OmnyaColors.sandMuted),
                                        boxShadow: member.checkedInToday
                                            ? [
                                                BoxShadow(
                                                  color: OmnyaColors.plum.withValues(alpha: 0.25),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        member.avatarLetter,
                                        style: OmnyaTypography.label(
                                          color: member.checkedInToday ? OmnyaColors.cream : OmnyaColors.charcoalMuted,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (member.checkedInToday)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: OmnyaColors.taupeDark,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark ? OmnyaColors.charcoal : OmnyaColors.cream,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  member.displayName,
                                  style: OmnyaTypography.bodySmall(
                                    color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '$checkedInCount of $totalCount checked in today',
                          style: OmnyaTypography.label(
                            color: OmnyaColors.taupeDark,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Consistency This Week List (Spec Page 2: Mia 7/7, You 6/7, Jess 5/7)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LiquidGlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consistency this week',
                          style: OmnyaTypography.label(
                            color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ...members.map((member) {
                          final ratio = member.weeklyDosesLogged / member.weeklyDosesTarget;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      member.displayName,
                                      style: OmnyaTypography.bodyMedium(
                                        color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                                      ),
                                    ),
                                    Text(
                                      '${member.weeklyDosesLogged}/${member.weeklyDosesTarget}',
                                      style: OmnyaTypography.label(
                                        color: isDark ? OmnyaColors.plumSoft : OmnyaColors.plum,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ratio.clamp(0.0, 1.0),
                                    minHeight: 6,
                                    backgroundColor: isDark ? const Color(0xFF2E2B29) : OmnyaColors.sandMuted,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? OmnyaColors.plumSoft : OmnyaColors.plum,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        Text(
                          'Invite-only, up to 5. Consistency and shot days only. Weights hidden by default.',
                          style: OmnyaTypography.bodySmall(color: OmnyaColors.taupeDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Join / Share Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TactileButton(
                          label: 'Share invite link',
                          variant: TactileButtonVariant.primary,
                          height: 44,
                          borderRadius: 14,
                          onPressed: () => _showInviteDialog(context, circle?.inviteCode ?? 'OMNYA'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TactileButton(
                          label: 'Join with code',
                          variant: TactileButtonVariant.outline,
                          height: 44,
                          borderRadius: 14,
                          onPressed: () => _showJoinDialog(context, repo),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: OmnyaColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Invite a friend', style: OmnyaTypography.headline()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your circle is capped at 5 close friends to maintain authentic consistency without noise.',
              style: OmnyaTypography.bodyMedium(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OmnyaColors.sand,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    code,
                    style: OmnyaTypography.headline(color: OmnyaColors.plum),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(ClipboardData(text: code));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite code copied to clipboard!')),
                      );
                    },
                    child: const Text('Copy'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, ProtocolRepository repo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: OmnyaColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Join circle', style: OmnyaTypography.headline()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _inviteController,
              decoration: InputDecoration(
                hintText: 'Enter 5-character invite code',
                filled: true,
                fillColor: OmnyaColors.sand,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: OmnyaColors.plum,
              foregroundColor: OmnyaColors.cream,
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final code = _inviteController.text.trim();
              if (code.isNotEmpty) {
                final nav = Navigator.of(context);
                await repo.joinCircle(inviteCode: code, displayName: 'You');
                nav.pop();
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
