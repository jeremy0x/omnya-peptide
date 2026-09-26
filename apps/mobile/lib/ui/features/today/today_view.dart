import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../../core/widgets/dose_celebration_action.dart';
import '../../../core/widgets/slide_page_route.dart';
import '../../../data/repositories/protocol_repository.dart';
import '../../../domain/outcome_correlator.dart';
import '../../core/omnya_header.dart';
import '../../core/sync_status_indicator.dart';
import '../photo_read/weekly_photo_read_view.dart';
import '../../../core/widgets/omnya_pro_badge.dart';
import '../../onboarding/paywall_view.dart';
import '../../onboarding/onboarding_quiz_view.dart';
import 'immersive_dose_log_view.dart';


class TodayView extends StatefulWidget {
  const TodayView({super.key});

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> with TickerProviderStateMixin {
  bool _doseLoggedToday = false;
  int _selectedEnergy = 4;
  int _selectedAppetite = 2;
  bool _photoCaptured = false;

  late final AnimationController _entranceController;
  late final AnimationController _ambientController;
  late final Animation<double> _headerAnimation;
  late final Animation<double> _heroAnimation;
  late final Animation<double> _checkInAnimation;
  late final Animation<double> _insightAnimation;
  late final Animation<double> _ambientGlowAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.04, 0.50, curve: Curves.easeOutCubic),
    );
    _heroAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.14, 0.68, curve: Curves.easeOutCubic),
    );
    _checkInAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.26, 0.82, curve: Curves.easeOutCubic),
    );
    _insightAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.38, 0.94, curve: Curves.easeOutCubic),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _ambientGlowAnimation = CurvedAnimation(
      parent: _ambientController,
      curve: Curves.easeInOutSine,
    );

    Future.microtask(() {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProtocolRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pick top scheduled compound (e.g. Retatrutide)
    final nextCompound = repo.compounds.isNotEmpty ? repo.compounds.first : null;
    final insight = OutcomeCorrelator.generateTodayInsight(
      checkIns: repo.checkIns,
      compounds: repo.compounds,
      doseLogs: repo.doseLogs,
      hasCycle: repo.profile?.hasCycle ?? true,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: RefreshIndicator(
              color: OmnyaColors.plum,
              backgroundColor: isDark ? const Color(0xFF282523) : OmnyaColors.cream,
              onRefresh: () => repo.syncWithCloud(force: true),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  _StaggeredEntranceItem(
                    animation: _headerAnimation,
                    slideOffset: -22.0,
                    child: OmnyaHeader(
                      title: 'Today',
                      showLogo: true,
                      onLogoTap: () => _showAppMenuSheet(context, repo),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          OmnyaProBadge(
                            onTap: () {
                              Navigator.push(
                                context,
                                SlidePageRoute(page: const PaywallView()),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          const SyncStatusIndicator(),
                          const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showAppMenuSheet(context, repo);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.all(8),
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
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedSettings01,
                              color: OmnyaColors.plum,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Card 1: Next Dose Card (Spec Page 2)
                _StaggeredEntranceItem(
                  animation: _heroAnimation,
                  slideOffset: 48.0,
                  applyScale: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedBuilder(
                      animation: _ambientGlowAnimation,
                      builder: (context, cardContent) {
                        final glow = _ambientGlowAnimation.value;
                        return Transform.scale(
                          scale: 1.0 + (0.007 * glow),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A1521) : OmnyaColors.plum,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08 + 0.10 * glow),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: OmnyaColors.plum.withValues(
                                    alpha: isDark ? 0.35 + 0.15 * glow : 0.26 + 0.16 * glow,
                                  ),
                                  blurRadius: 20 + 16 * glow,
                                  spreadRadius: glow * 2.2,
                                  offset: Offset(0, 8 + 4 * glow),
                                ),
                                BoxShadow(
                                  color: OmnyaColors.plumSoft.withValues(
                                    alpha: isDark ? 0.20 * glow : 0.16 * glow,
                                  ),
                                  blurRadius: 42 + 20 * glow,
                                  spreadRadius: 2.0 + glow * 5.0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(26),
                            child: cardContent,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dose',
                                style: OmnyaTypography.bodySmall(
                                  color: OmnyaColors.sandMuted.withValues(alpha: 0.8),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  nextCompound?.category.label ?? 'body',
                                  style: OmnyaTypography.tag(color: OmnyaColors.cream),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            nextCompound != null
                                ? '${nextCompound.name.substring(0, 4)}, ${nextCompound.doseMg.toStringAsFixed(0)} mg'
                                : 'Reta, 2 mg',
                            style: OmnyaTypography.displayMedium(color: OmnyaColors.cream),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${nextCompound?.injectionSite ?? 'Left thigh'} · due 8:00 am',
                            style: OmnyaTypography.bodyMedium(
                              color: OmnyaColors.sandMuted.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 24),
                          DoseCelebrationAction(
                            isLogged: _doseLoggedToday,
                            compoundName: nextCompound?.name ?? 'Retatrutide',
                            nextSite: nextCompound?.injectionSite ?? 'Right thigh',
                            onLog: () {
                              final currentSite = nextCompound?.injectionSite ?? 'Left thigh';
                              if (nextCompound != null) {
                                repo.logDose(
                                  compoundId: nextCompound.id,
                                  injectionSite: nextCompound.injectionSite,
                                );
                              }
                              setState(() => _doseLoggedToday = true);

                              final updatedNextSite = repo.compounds.isNotEmpty
                                  ? repo.compounds.first.injectionSite
                                  : 'Right thigh';

                              ImmersiveDoseLogView.show(
                                context,
                                compoundName: nextCompound?.name ?? 'Retatrutide',
                                doseMg: nextCompound?.doseMg ?? 2.0,
                                injectionSite: currentSite,
                                nextSite: updatedNextSite,
                                category: nextCompound?.category.label ?? 'body',
                              );
                            },
                            onUndo: () {
                              setState(() => _doseLoggedToday = false);
                            },
                            onViewDetails: () {
                              ImmersiveDoseLogView.show(
                                context,
                                compoundName: nextCompound?.name ?? 'Retatrutide',
                                doseMg: nextCompound?.doseMg ?? 2.0,
                                injectionSite: nextCompound?.injectionSite ?? 'Left thigh',
                                nextSite: repo.compounds.isNotEmpty
                                    ? repo.compounds.first.injectionSite
                                    : 'Right thigh',
                                category: nextCompound?.category.label ?? 'body',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Card 2: 3-Tap Daily Check-in Card (Spec Page 2)
                _StaggeredEntranceItem(
                  animation: _checkInAnimation,
                  slideOffset: 60.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LiquidGlassContainer(
                      borderRadius: 28,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily check-in',
                            style: OmnyaTypography.label(
                              color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                          
                          // Energy tap row
                          _buildTapRow(
                            label: 'Energy',
                            value: _selectedEnergy,
                            max: 5,
                            onSelect: (v) {
                              setState(() => _selectedEnergy = v);
                              HapticFeedback.selectionClick();
                            },
                          ),
                          const SizedBox(height: 16),

                          // Appetite tap row
                          _buildTapRow(
                            label: 'Appetite',
                            value: _selectedAppetite,
                            max: 5,
                            onSelect: (v) {
                              setState(() => _selectedAppetite = v);
                              HapticFeedback.selectionClick();
                            },
                          ),
                          const SizedBox(height: 18),

                          // Photo tap button
                          InkWell(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              await Navigator.push(
                                context,
                                SlidePageRoute(page: const WeeklyPhotoReadView()),
                              );
                              if (mounted) {
                                setState(() => _photoCaptured = true);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF282523) : OmnyaColors.cream,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF38332E) : OmnyaColors.taupe.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const HugeIcon(
                                    icon: HugeIcons.strokeRoundedCameraSmile02,
                                    color: OmnyaColors.plum,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _photoCaptured ? 'Weekly photo captured' : 'Weekly progress photo',
                                      style: OmnyaTypography.label(
                                        color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const HugeIcon(
                                    icon: HugeIcons.strokeRoundedArrowRight01,
                                    color: OmnyaColors.taupeDark,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Card 3: Insight Card (Spec Page 2: "Scale's up 2 lb, period's due Thursday. Ignore it.")
                _StaggeredEntranceItem(
                  animation: _insightAnimation,
                  slideOffset: 60.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LiquidGlassContainer(
                      borderRadius: 28,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.headline,
                            style: OmnyaTypography.tag(
                              color: OmnyaColors.taupeDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            insight.body,
                            style: OmnyaTypography.headline(
                              color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildTapRow({
    required String label,
    required int value,
    required int max,
    required ValueChanged<int> onSelect,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: OmnyaTypography.bodyMedium(
              color: isDark ? OmnyaColors.taupe : OmnyaColors.charcoalMuted,
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(max, (index) {
              final val = index + 1;
              final isSelected = val <= value;
              return GestureDetector(
                onTap: () => onSelect(val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? OmnyaColors.plumSoft : OmnyaColors.plum)
                        : (isDark ? const Color(0xFF282523) : OmnyaColors.sandMuted),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$val',
                    style: OmnyaTypography.label(
                      color: isSelected ? OmnyaColors.cream : OmnyaColors.charcoalMuted,
                      weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  void _showAppMenuSheet(BuildContext context, ProtocolRepository repo) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Material(
          color: isDark ? const Color(0xFF1E1A18) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick Access',
                style: OmnyaTypography.headline(
                  color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                ),
              ),
              const SizedBox(height: 20),

              // 1. Replay Onboarding Quiz
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: OmnyaColors.plum.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedQuiz03,
                      color: OmnyaColors.plum,
                      size: 20,
                    ),
                  ),
                ),
                title: Text('Protocol Assessment', style: OmnyaTypography.label(weight: FontWeight.w600)),
                subtitle: Text('Personalize your wellness goals, peptides, and cycle', style: OmnyaTypography.bodySmall()),
                trailing: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: OmnyaColors.taupeDark,
                  size: 18,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    SlidePageRoute(
                      page: OnboardingQuizView(
                        onFinished: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 16),

              // 2. Pro Paywall & Subscription
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: OmnyaColors.plum.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedHonourStar,
                      color: OmnyaColors.plum,
                      size: 20,
                    ),
                  ),
                ),
                title: Text('Omnya Pro', style: OmnyaTypography.label(weight: FontWeight.w600)),
                subtitle: Text(
                  repo.isPro ? 'Pro Active · Manage your plan' : 'Unlock photo reads, cycle correlations, and private circle',
                  style: OmnyaTypography.bodySmall(),
                ),
                trailing: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: OmnyaColors.taupeDark,
                  size: 18,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    SlidePageRoute(page: const PaywallView()),
                  );
                },
              ),
              const Divider(height: 16),

              // 3. Vault Cloud Backup Info & Action
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (repo.hasPendingSync ? const Color(0xFFD97706) : OmnyaColors.plum).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: repo.hasPendingSync
                          ? HugeIcons.strokeRoundedCloudUpload
                          : HugeIcons.strokeRoundedCloudCheck,
                      color: repo.hasPendingSync ? const Color(0xFFD97706) : OmnyaColors.plum,
                      size: 20,
                    ),
                  ),
                ),
                title: Text('Vault Cloud Backup', style: OmnyaTypography.label(weight: FontWeight.w600)),
                subtitle: Text(
                  repo.isSyncing
                      ? 'Syncing with Supabase...'
                      : (repo.hasPendingSync
                          ? 'Offline: Changes saved locally (tap to sync now)'
                          : 'Encrypted cloud backup active (tap to sync)'),
                  style: OmnyaTypography.bodySmall(
                    color: repo.hasPendingSync ? const Color(0xFFD97706) : OmnyaColors.charcoalLight,
                  ),
                ),
                trailing: repo.isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: OmnyaColors.plum),
                      )
                    : const HugeIcon(
                        icon: HugeIcons.strokeRoundedRefresh,
                        color: OmnyaColors.taupeDark,
                        size: 18,
                      ),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx);
                  await repo.syncWithCloud(force: true);
                },
              ),

            ],
          ),
        ),
      );
    },
  );
  }
}

/// Performant staggered entrance item applying a subtle vertical glide and opacity reveal
class _StaggeredEntranceItem extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double slideOffset;
  final bool applyScale;

  const _StaggeredEntranceItem({
    required this.animation,
    required this.child,
    this.slideOffset = 24.0,
    this.applyScale = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, staticChild) {
        final t = animation.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1.0 - t) * slideOffset),
            child: applyScale
                ? Transform.scale(
                    scale: 0.93 + (0.07 * t),
                    child: staticChild,
                  )
                : staticChild,
          ),
        );
      },
      child: child,
    );
  }
}

