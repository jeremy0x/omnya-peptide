import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';
import '../../../core/widgets/tactile_button.dart';
import '../../../domain/insights.dart';

/// The one full-screen moment the spec allows: milestones, set in the serif.
class MilestoneView extends StatelessWidget {
  final String title;
  final String body;
  final String? goal;

  const MilestoneView({super.key, required this.title, required this.body, this.goal});

  static Future<void> show(
    BuildContext context,
    Milestone milestone, {
    required int dosesLogged,
    required String goal,
  }) {
    HapticFeedback.mediumImpact();
    final (title, body) = switch (milestone) {
      Milestone.firstDose => ('Day 1.', 'First dose logged.'),
      Milestone.day30 => ('Day 30.', '$dosesLogged doses logged so far.'),
      Milestone.day90 => ('Day 90.', '$dosesLogged doses logged in 90 days.'),
    };
    final showGoal = milestone != Milestone.firstDose && goal.trim().isNotEmpty;
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => MilestoneView(title: title, body: body, goal: showGoal ? goal.trim() : null),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OmnyaColors.plum,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              _Rise(
                delay: 0,
                child: Text(
                  title,
                  style: OmnyaTypography.displayLarge(color: OmnyaColors.cream).copyWith(fontSize: 56, height: 1.05),
                ),
              ),
              const SizedBox(height: 16),
              _Rise(
                delay: 0.15,
                child: Text(body, style: OmnyaTypography.headline(color: OmnyaColors.sandMuted)),
              ),
              if (goal != null) ...[
                const SizedBox(height: 40),
                _Rise(
                  delay: 0.3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What you said would make it worth it',
                        style: OmnyaTypography.label(color: OmnyaColors.sandMuted.withValues(alpha: 0.75)),
                      ),
                      const SizedBox(height: 8),
                      Text('“$goal”', style: OmnyaTypography.bodyLarge(color: OmnyaColors.cream)),
                    ],
                  ),
                ),
              ],
              const Spacer(flex: 4),
              TactileButton(
                label: 'Done',
                variant: TactileButtonVariant.onDark,
                width: double.infinity,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts its child in once, after [delay] (a fraction of the entrance).
class _Rise extends StatelessWidget {
  final double delay;
  final Widget child;
  const _Rise({required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (delay * 600).round()),
      curve: Interval(delay, 1, curve: Curves.easeOutCubic),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
