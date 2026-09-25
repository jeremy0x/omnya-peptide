import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/omnya_colors.dart';
import '../../core/theme/omnya_typography.dart';
import '../../core/widgets/tactile_button.dart';
import '../../core/widgets/slide_page_route.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/protocol_repository.dart';
import 'paywall_view.dart';

class OnboardingQuizView extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingQuizView({super.key, required this.onFinished});

  @override
  State<OnboardingQuizView> createState() => _OnboardingQuizViewState();
}

class _OnboardingQuizViewState extends State<OnboardingQuizView> {
  int _currentStep = 0; // 0 to 5 (6 steps total)

  // Answers state
  final Set<String> _selectedGoals = {'Glow'};
  final Set<String> _selectedCompounds = {'GHK-Cu'};
  String _experienceLevel = 'First month';
  String _cycleStatus = 'natural'; // 'natural', 'birth_control', 'irregular'
  final TextEditingController _motivationController = TextEditingController(
    text: "Fitting into the dress from my sister's wedding and actually liking my skin without makeup.",
  );
  String _photoType = 'both';
  bool _sundayPrompt = true;

  bool get _hasCycle => _cycleStatus == 'natural';

  @override
  void dispose() {
    _motivationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_currentStep < 5) {
      setState(() => _currentStep++);
    } else {
      _showPersonalizedProtocolScreen();
    }
  }

  void _prevStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _showPersonalizedProtocolScreen() async {
    final repo = context.read<ProtocolRepository>();
    final profile = UserProfile(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      goals: _selectedGoals.toList(),
      selectedCompounds: _selectedCompounds.toList(),
      experienceLevel: _experienceLevel,
      hasCycle: _hasCycle,
      day90GoalText: _motivationController.text.trim(),
      photoTrackingType: _photoType,
      sundayPhotoPromptEnabled: _sundayPrompt,
      createdAt: DateTime.now(),
    );
    await repo.saveProfile(profile);
    await repo.initializeProtocolFromOnboarding(_selectedCompounds.toList());

    if (!mounted) return;

    final primaryCompound = _selectedCompounds.isNotEmpty && !_selectedCompounds.first.contains('Not sure')
        ? _selectedCompounds.first
        : 'this protocol';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: OmnyaColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: OmnyaColors.taupe.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your protocol is ready.',
              style: OmnyaTypography.headline(),
            ),
            const SizedBox(height: 12),
            Text(
              'Women running $primaryCompound usually see changes around week 4. Let\'s track yours.',
              style: OmnyaTypography.bodyLarge(color: OmnyaColors.charcoalMuted),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: OmnyaColors.sand,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Photos processed on-device. No account required to start.',
                style: OmnyaTypography.bodySmall(color: OmnyaColors.taupeDark),
              ),
            ),
            const SizedBox(height: 24),
            TactileButton(
              label: 'See personalized options',
              variant: TactileButtonVariant.primary,
              width: double.infinity,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  SlidePageRoute(
                    page: PaywallView(onCompleted: widget.onFinished),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 44,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
            size: 22,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (_currentStep > 0) {
              _prevStep();
            } else {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                widget.onFinished();
              }
            }
          },
        ),
        centerTitle: true,
        title: Text(
          '${_currentStep + 1} of 6',
          style: OmnyaTypography.tag(color: OmnyaColors.taupeDark),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onFinished();
            },
            child: Text(
              'Skip',
              style: OmnyaTypography.bodySmall(color: OmnyaColors.taupeDark),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 6.0,
                minHeight: 3,
                backgroundColor: isDark ? const Color(0xFF282523) : OmnyaColors.sandMuted,
                valueColor: const AlwaysStoppedAnimation<Color>(OmnyaColors.plum),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Content Switcher
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildCurrentStep(context),
                    ),
                  ),

                  // Bottom Action
                  TactileButton(
                    label: _currentStep == 5 ? 'Finish' : 'Continue',
                    variant: TactileButtonVariant.primary,
                    width: double.infinity,
                    height: 54,
                    onPressed: _nextStep,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Goals();
      case 1:
        return _buildStep2Compounds();
      case 2:
        return _buildStep3Experience();
      case 3:
        return _buildStep4Cycle();
      case 4:
        return _buildStep5Motivation();
      case 5:
        return _buildStep6Photos();
      default:
        return const SizedBox.shrink();
    }
  }

  // 1 of 6: What are you here for?
  Widget _buildStep1Goals() {
    const goals = ['Snatched', 'Glow', 'Heal and recover', 'Energy', 'All of it'];

    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What are you here for?', style: OmnyaTypography.displayMedium()),
        const SizedBox(height: 6),
        Text('Select one or more that matter most to you.', style: OmnyaTypography.bodyMedium()),
        const SizedBox(height: 24),
        ...goals.map((g) {
          final isSelected = _selectedGoals.contains(g);
          return _buildSelectableOption(
            title: g,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (g == 'All of it') {
                  _selectedGoals.clear();
                  _selectedGoals.add(g);
                } else {
                  _selectedGoals.remove('All of it');
                  if (isSelected) {
                    _selectedGoals.remove(g);
                  } else {
                    _selectedGoals.add(g);
                  }
                }
              });
            },
          );
        }),
      ],
    );
  }

  // 2 of 6: What are you running, or thinking about?
  Widget _buildStep2Compounds() {
    final options = [
      {'name': 'Retatrutide', 'sub': 'dream bod, here we come'},
      {'name': 'GHK-Cu', 'sub': 'face card will be lethal'},
      {'name': 'KLOW', 'sub': 'heal, glow, repeat'},
      {'name': 'Not sure yet', 'sub': 'explore library'},
    ];

    return Column(
      key: const ValueKey('step_2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What are you running,\nor thinking about?', style: OmnyaTypography.displayMedium()),
        const SizedBox(height: 6),
        Text('Adds compounds with defaults you confirm later.', style: OmnyaTypography.bodyMedium()),
        const SizedBox(height: 24),
        ...options.map((opt) {
          final name = opt['name']!;
          final isSelected = _selectedCompounds.contains(name);
          return _buildSelectableOption(
            title: name,
            subtitle: opt['sub'],
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedCompounds.remove(name);
                } else {
                  _selectedCompounds.add(name);
                }
              });
            },
          );
        }),
      ],
    );
  }

  // 3 of 6: How far in are you?
  Widget _buildStep3Experience() {
    const levels = ["Haven't started", 'First month', 'A few months', 'Over a year'];

    return Column(
      key: const ValueKey('step_3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How far in are you?', style: OmnyaTypography.displayMedium()),
        const SizedBox(height: 6),
        Text('Sets the tone and baseline of your first insights.', style: OmnyaTypography.bodyMedium()),
        const SizedBox(height: 24),
        ...levels.map((lvl) {
          return _buildSelectableOption(
            title: lvl,
            isSelected: _experienceLevel == lvl,
            onTap: () => setState(() => _experienceLevel = lvl),
          );
        }),
      ],
    );
  }

  // 4 of 6: Do you get a period?
  Widget _buildStep4Cycle() {
    return Column(
      key: const ValueKey('step_4'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Do you get a period?', style: OmnyaTypography.displayMedium()),
        const SizedBox(height: 6),
        Text('Turns on cycle-aware weight filtering and water weight alerts.', style: OmnyaTypography.bodyMedium()),
        const SizedBox(height: 24),
        _buildSelectableOption(
          title: 'Yes, natural cycle',
          isSelected: _cycleStatus == 'natural',
          onTap: () => setState(() => _cycleStatus = 'natural'),
        ),
        _buildSelectableOption(
          title: 'On hormonal birth control',
          isSelected: _cycleStatus == 'birth_control',
          onTap: () => setState(() => _cycleStatus = 'birth_control'),
        ),
        _buildSelectableOption(
          title: 'Irregular or not tracking',
          isSelected: _cycleStatus == 'irregular',
          onTap: () => setState(() => _cycleStatus = 'irregular'),
        ),
      ],
    );
  }

  // 5 of 6: What would make this worth it in 90 days?
  Widget _buildStep5Motivation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      key: const ValueKey('step_5'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What would make this worth it in 90 days?', style: OmnyaTypography.displayMedium()),
        const SizedBox(height: 6),
        Text('One line, your words. Shown back to you at Day 30 and Day 90.', style: OmnyaTypography.bodyMedium()),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B19) : OmnyaColors.cream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF3E3935) : OmnyaColors.taupe.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: TextField(
            controller: _motivationController,
            maxLines: 4,
            style: OmnyaTypography.bodyLarge(
              color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., Feeling confident in my own skin, effortless morning routine...',
              hintStyle: OmnyaTypography.bodyLarge(
                color: OmnyaColors.taupeDark,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
      ],
    );
  }

  // 6 of 6: Photos preference
  Widget _buildStep6Photos() {
    return Column(
      key: const ValueKey('step_6'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos: face, body, or both?', style: OmnyaTypography.displayMedium()),
        const SizedBox(height: 6),
        Text('Sets up your weekly photo read and camera alignment guide.', style: OmnyaTypography.bodyMedium()),
        const SizedBox(height: 24),
        _buildSelectableOption(
          title: 'Face & tone focus',
          isSelected: _photoType == 'face',
          onTap: () => setState(() => _photoType = 'face'),
        ),
        _buildSelectableOption(
          title: 'Body & posture focus',
          isSelected: _photoType == 'body',
          onTap: () => setState(() => _photoType = 'body'),
        ),
        _buildSelectableOption(
          title: 'Both (Recommended)',
          isSelected: _photoType == 'both',
          onTap: () => setState(() => _photoType = 'both'),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Enable Sunday morning photo prompt', style: OmnyaTypography.bodyMedium()),
          value: _sundayPrompt,
          activeTrackColor: OmnyaColors.plum,
          onChanged: (val) => setState(() => _sundayPrompt = val),
        ),
      ],
    );
  }

  Widget _buildSelectableOption({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? OmnyaColors.plumSoft : OmnyaColors.plum)
                : (isDark ? const Color(0xFF221F1C) : OmnyaColors.cream),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? (isDark ? OmnyaColors.plumSoft : OmnyaColors.plum)
                  : (isDark ? const Color(0xFF38332E) : OmnyaColors.taupe.withValues(alpha: 0.35)),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: OmnyaColors.plum.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: OmnyaTypography.label(
                        color: isSelected ? OmnyaColors.cream : (isDark ? OmnyaColors.cream : OmnyaColors.charcoal),
                        weight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: OmnyaTypography.bodySmall(
                          color: isSelected ? OmnyaColors.sandMuted : OmnyaColors.taupeDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: isSelected
                    ? const HugeIcon(
                        key: ValueKey('selected'),
                        icon: HugeIcons.strokeRoundedCheckmarkCircle03,
                        color: OmnyaColors.cream,
                        size: 22,
                      )
                    : SizedBox(
                        key: const ValueKey('unselected'),
                        width: 22,
                        height: 22,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF4A443E) : OmnyaColors.taupe.withValues(alpha: 0.45),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
