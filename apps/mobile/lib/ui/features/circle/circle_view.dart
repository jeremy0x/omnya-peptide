import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../../core/widgets/tactile_button.dart';
import '../../../data/models/circle_data.dart';
import '../../../data/repositories/protocol_repository.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/omnya_toast.dart';
import '../../core/omnya_header.dart';

class CircleView extends StatefulWidget {
  const CircleView({super.key});

  @override
  State<CircleView> createState() => _CircleViewState();
}

class _CircleViewState extends State<CircleView> {
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
                        _showInviteSheet(context, circle);
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
                          onPressed: () => _showInviteSheet(context, circle),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TactileButton(
                          label: 'Join with code',
                          variant: TactileButtonVariant.outline,
                          height: 44,
                          borderRadius: 14,
                          onPressed: () => _showJoinSheet(context, repo),
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

  void _showInviteSheet(BuildContext context, CircleModel? circle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawCode = circle?.inviteCode;
    final inviteCode = (rawCode != null && rawCode.isNotEmpty && rawCode != 'OMNYA')
        ? rawCode
        : ApiService.generateInviteCode();
    final memberCount = circle?.members.length ?? 1;
    final spotsLeft = (5 - memberCount).clamp(0, 5);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B18) : OmnyaColors.cream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? const Color(0xFF332E2A) : OmnyaColors.taupe.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 14,
            bottom: MediaQuery.of(ctx).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF4A443E) : OmnyaColors.taupe.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title & Subtitle
              Text(
                'Invite to Circle',
                style: OmnyaTypography.headline(
                  color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Accountability cohorts are capped at 5 friends to keep tracking intimate. Only consistency and shot days are visible — weights and notes stay strictly on-device.',
                style: OmnyaTypography.bodySmall(
                  color: isDark ? OmnyaColors.sandMuted : OmnyaColors.charcoalMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Hero Code Container
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF282420) : OmnyaColors.sand.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3E3832) : OmnyaColors.taupe.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      inviteCode.split('').join('  '),
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                        color: OmnyaColors.plum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? OmnyaColors.plum.withValues(alpha: 0.25) : OmnyaColors.plum.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? OmnyaColors.plumSoft.withValues(alpha: 0.3) : OmnyaColors.plum.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        '$spotsLeft of 5 spots remaining',
                        style: OmnyaTypography.label(
                          color: isDark ? OmnyaColors.plumSoft : OmnyaColors.plum,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Copy Action
              TactileButton(
                label: 'Copy Invite Code',
                variant: TactileButtonVariant.primary,
                height: 50,
                borderRadius: 16,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  Navigator.pop(ctx);
                  OmnyaToast.show(
                    context,
                    title: 'Invite Code Copied',
                    message: '$inviteCode is ready to share with your friends.',
                    type: OmnyaToastType.success,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showJoinSheet(BuildContext context, ProtocolRepository repo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    String? errorMessage;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1B18) : OmnyaColors.cream,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: isDark ? const Color(0xFF332E2A) : OmnyaColors.taupe.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 14,
                bottom: bottomInset + MediaQuery.of(ctx).padding.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF4A443E) : OmnyaColors.taupe.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title & Subtitle
                    Text(
                      'Join an Accountability Circle',
                      style: OmnyaTypography.headline(
                        color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your group\'s 5-character invite code to join your friends\' protocol circle.',
                      style: OmnyaTypography.bodySmall(
                        color: isDark ? OmnyaColors.sandMuted : OmnyaColors.charcoalMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Centered 5-character Code Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF282420) : OmnyaColors.sand.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: errorMessage != null
                              ? const Color(0xFFEF4444)
                              : (isDark ? const Color(0xFF3E3832) : OmnyaColors.taupe.withValues(alpha: 0.3)),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: codeController,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 5,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 12,
                          color: isDark ? OmnyaColors.cream : OmnyaColors.plum,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '• • • • •',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            letterSpacing: 8,
                            color: isDark ? const Color(0xFF5A524A) : OmnyaColors.taupeDark.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (_) {
                          if (errorMessage != null) {
                            setSheetState(() => errorMessage = null);
                          }
                        },
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedAlertCircle,
                              color: Color(0xFFEF4444),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Display Name Field
                    Text(
                      'Your Name in Circle',
                      style: OmnyaTypography.label(
                        color: isDark ? OmnyaColors.sandMuted : OmnyaColors.charcoalMuted,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF282420) : OmnyaColors.sand.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3E3832) : OmnyaColors.taupe.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: nameController,
                        style: OmnyaTypography.bodyMedium(
                          color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Alex',
                          hintStyle: OmnyaTypography.bodyMedium(
                            color: OmnyaColors.taupeDark.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    TactileButton(
                      label: isLoading ? 'Joining Cohort...' : 'Join This Circle',
                      variant: TactileButtonVariant.primary,
                      height: 50,
                      borderRadius: 16,
                      onPressed: isLoading
                          ? null
                          : () async {
                              final code = codeController.text.trim().toUpperCase();
                              final name = nameController.text.trim().isEmpty ? 'Member' : nameController.text.trim();

                              if (code.length != 5) {
                                setSheetState(() {
                                  errorMessage = 'Enter the complete 5-character code';
                                });
                                HapticFeedback.heavyImpact();
                                return;
                              }

                              setSheetState(() {
                                isLoading = true;
                                errorMessage = null;
                              });

                              final result = await repo.joinCircle(
                                inviteCode: code,
                                displayName: name,
                              );

                              if (!ctx.mounted) return;

                              if (result.success) {
                                HapticFeedback.lightImpact();
                                Navigator.pop(ctx);
                                if (context.mounted) {
                                  OmnyaToast.show(
                                    context,
                                    title: 'Joined Circle Cohort',
                                    message: 'You are now synced with ${result.circle?.name ?? "your group"}.',
                                    type: OmnyaToastType.success,
                                  );
                                }
                              } else {
                                HapticFeedback.heavyImpact();
                                setSheetState(() {
                                  isLoading = false;
                                  errorMessage = result.errorMessage ?? 'Failed to join circle';
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
