import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/omnya_colors.dart';
import '../../core/theme/omnya_typography.dart';
import '../../core/widgets/omnya_logo.dart';
import '../features/today/today_view.dart';
import '../features/progress/progress_view.dart';
import '../features/stack/stack_view.dart';
import '../features/circle/circle_view.dart';

List<double> _saturationMatrix(double s) {
  const lumR = 0.2126, lumG = 0.7152, lumB = 0.0722;
  final ir = (1 - s) * lumR, ig = (1 - s) * lumG, ib = (1 - s) * lumB;
  return <double>[
    ir + s, ig,     ib,     0, 0,
    ir,     ig + s, ib,     0, 0,
    ir,     ig,     ib + s, 0, 0,
    0,      0,      0,      1, 0,
  ];
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _orbPressed = false;

  late final AnimationController _navEntranceController;
  late final Animation<double> _navFadeAnimation;
  late final Animation<Offset> _navSlideAnimation;

  final List<Widget> _pages = const [
    TodayView(),
    ProgressView(),
    StackView(),
    CircleView(),
  ];

  @override
  void initState() {
    super.initState();
    _navEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _navFadeAnimation = CurvedAnimation(
      parent: _navEntranceController,
      curve: const Interval(0.20, 0.85, curve: Curves.easeOutCubic),
    );
    _navSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.75),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _navEntranceController,
      curve: const Interval(0.15, 0.90, curve: Curves.easeOutCubic),
    ));

    _navEntranceController.forward();
  }

  @override
  void dispose() {
    _navEntranceController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = index);
    }
  }

  void _onOrbTapped() {
    HapticFeedback.mediumImpact();
    _showQuickSearchSheet(context);
  }

  void _showQuickSearchSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _QuickSearchAndLogSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? OmnyaColors.plumDeep : OmnyaColors.sand,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_currentIndex),
              child: _pages[_currentIndex],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _navSlideAnimation,
              child: FadeTransition(
                opacity: _navFadeAnimation,
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Row(
                          children: [
                            // Main floating liquid glass navigation capsule
                            Expanded(
                              child: _buildLiquidGlassPill(isDark),
                            ),
                            const SizedBox(width: 10),
                            // Adjacent circular 3D convex glass orb action button
                            _buildGlassOrbButton(isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidGlassPill(bool isDark) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : const Color(0x14000000),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: ColorFilter.matrix(_saturationMatrix(1.4)),
            inner: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          ),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0x66181412)
                  : const Color(0x66FFFFFF),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: isDark
                    ? const Color(0x2EFFFFFF)
                    : Colors.white.withValues(alpha: 0.85),
                width: 1.2,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final tabWidth = totalWidth / 4;
                final indicatorLeft = _currentIndex * tabWidth;

                return Stack(
                  children: [
                    // Smooth animated sliding pill indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      left: indicatorLeft,
                      top: 0,
                      bottom: 0,
                      width: tabWidth,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? [
                                    const Color(0x664A1E35),
                                    const Color(0x40361325),
                                  ]
                                : [
                                    const Color(0xF2FFFFFF),
                                    const Color(0xCCF2EAE1),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: isDark
                                ? const Color(0x4DFFFFFF)
                                : Colors.white,
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x18000000),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Navigation items row
                    Row(
                      children: [
                        Expanded(
                          child: _buildNavItem(
                            index: 0,
                            label: 'Today',
                            icon: HugeIcons.strokeRoundedCalendar03,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildNavItem(
                            index: 1,
                            label: 'Progress',
                            icon: HugeIcons.strokeRoundedAnalytics01,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildNavItem(
                            index: 2,
                            label: 'Stack',
                            icon: HugeIcons.strokeRoundedLayers01,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildNavItem(
                            index: 3,
                            label: 'Circle',
                            icon: HugeIcons.strokeRoundedUserGroup,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required dynamic icon,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    final activeColor = OmnyaColors.plum;
    final inactiveColor = isDark ? OmnyaColors.taupe : const Color(0xFF1F1D1C);

    return Semantics(
      label: '$label tab',
      selected: isSelected,
      button: true,
      child: GestureDetector(
        key: Key('nav_tab_${label.toLowerCase()}'),
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: HugeIcon(
                  icon: icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 21,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontFamily: 'InstrumentSans',
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.2,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassOrbButton(bool isDark) {
    return Semantics(
      label: 'Search peptides and protocols',
      button: true,
      child: GestureDetector(
        key: const Key('nav_orb_button'),
        onTapDown: (_) => setState(() => _orbPressed = true),
        onTapUp: (_) {
          setState(() => _orbPressed = false);
          _onOrbTapped();
        },
        onTapCancel: () => setState(() => _orbPressed = false),
        child: AnimatedScale(
          scale: _orbPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : const Color(0x16000000),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                if (!isDark)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    blurRadius: 6,
                    offset: const Offset(-1, -1),
                  ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.compose(
                  outer: ColorFilter.matrix(_saturationMatrix(1.4)),
                  inner: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0x66332D29),
                              const Color(0x40201C1A),
                            ]
                          : [
                              const Color(0xB3FFFFFF),
                              const Color(0x66F2ECE4),
                            ],
                    ),
                    border: Border.all(
                      color: isDark
                          ? const Color(0x33FFFFFF)
                          : Colors.white,
                      width: 1.2,
                    ),
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: Color(0xFF1F1D1C),
                      size: 23,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickSearchAndLogSheet extends StatefulWidget {
  const _QuickSearchAndLogSheet();

  @override
  State<_QuickSearchAndLogSheet> createState() => _QuickSearchAndLogSheetState();
}

class _QuickSearchAndLogSheetState extends State<_QuickSearchAndLogSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _filter = '';

  final List<Map<String, String>> _allPeptides = const [
    {
      'name': 'Retatrutide',
      'class': 'GLP-1 / GIP / Glucagon Tri-Agonist',
      'badge': 'Metabolic',
      'dose': '2.0 mg weekly',
    },
    {
      'name': 'GHK-Cu',
      'class': 'Copper Peptide (Dermal & Collagen)',
      'badge': 'Cellular Glow',
      'dose': '2.5 mg subcutaneous daily',
    },
    {
      'name': 'KLOW Blend',
      'class': 'BPC-157 + TB-500 + GHK-Cu + KPV',
      'badge': 'Anti-Inflammatory',
      'dose': '0.5 ml daily cycle',
    },
    {
      'name': 'Tirzepatide',
      'class': 'Dual GIP / GLP-1 Receptor Agonist',
      'badge': 'Metabolic',
      'dose': '5.0 mg weekly',
    },
    {
      'name': 'BPC-157',
      'class': 'Body Protection Compound 15-amino acid',
      'badge': 'Gut & Tissue',
      'dose': '500 mcg daily',
    },
    {
      'name': 'Semaglutide',
      'class': 'GLP-1 Receptor Agonist',
      'badge': 'Metabolic',
      'dose': '1.0 mg weekly',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _filter = val.trim().toLowerCase();
      _isSearching = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _isSearching = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = _allPeptides.where((p) {
      if (_filter.isEmpty) return true;
      return p['name']!.toLowerCase().contains(_filter) ||
          p['class']!.toLowerCase().contains(_filter) ||
          p['badge']!.toLowerCase().contains(_filter);
    }).toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xF01E1A18)
                : const Color(0xF7FDFBF9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? const Color(0x29FFFFFF) : const Color(0x66E5DCD3),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x44FFFFFF) : const Color(0x33000000),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Brand logo & title row
              Row(
                children: [
                  const OmnyaLogo(size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Protocol Library & Quick Log',
                      overflow: TextOverflow.ellipsis,
                      style: OmnyaTypography.headline(
                        color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Search input box
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x44FFFFFF) : const Color(0x0C000000),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0x22FFFFFF) : const Color(0x22B5A496),
                  ),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: isDark ? OmnyaColors.taupe : OmnyaColors.charcoalLight,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: OmnyaTypography.bodyMedium(
                          color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search compounds, benefits, blends...',
                          hintStyle: OmnyaTypography.bodyMedium(
                            color: isDark ? OmnyaColors.taupe : OmnyaColors.charcoalLight,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: isDark ? OmnyaColors.taupe : OmnyaColors.charcoalLight,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Content list or animated logo loader
              Expanded(
                child: _isSearching
                    ? const Center(
                        child: OmnyaLogoLoader(
                          size: 52,
                          message: 'Searching compounds...',
                        ),
                      )
                    : results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const OmnyaLogo(size: 40, monochrome: true),
                                const SizedBox(height: 12),
                                Text(
                                  'No matching peptides found',
                                  style: OmnyaTypography.bodyMedium(
                                    color: isDark ? OmnyaColors.taupe : OmnyaColors.charcoalLight,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final p = results[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0x26FFFFFF)
                                      : const Color(0x66FFFFFF),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0x1FFFFFFF)
                                        : const Color(0x2EB5A496),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: OmnyaColors.plum.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Center(
                                        child: OmnyaLogo(size: 24),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                p['name']!,
                                                style: OmnyaTypography.bodyLarge(
                                                  color: isDark
                                                      ? OmnyaColors.cream
                                                      : OmnyaColors.charcoal,
                                                ).copyWith(fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: OmnyaColors.plumSoft
                                                      .withValues(alpha: 0.18),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  p['badge']!,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: OmnyaColors.plum,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            p['class']!,
                                            style: OmnyaTypography.tag(
                                              color: isDark
                                                  ? OmnyaColors.taupe
                                                  : OmnyaColors.charcoalLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF282523)
                                            : OmnyaColors.cream,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF3E3935)
                                              : OmnyaColors.taupe.withValues(alpha: 0.35),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: HugeIcon(
                                          icon: HugeIcons.strokeRoundedLogin02,
                                          color: isDark
                                              ? OmnyaColors.plumSoft
                                              : OmnyaColors.plum,
                                          size: 20,
                                        ),
                                        tooltip: 'Log dose',
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          showDialog(
                                            context: context,
                                          builder: (dialogCtx) => AlertDialog(
                                            backgroundColor: isDark ? const Color(0xFF262220) : OmnyaColors.cream,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                            title: Text(
                                              'Log ${p['name']}?',
                                              style: OmnyaTypography.headline(
                                                color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                                              ),
                                            ),
                                            content: Text(
                                              'Confirm logging ${p['dose']} (${p['badge']}) for today\'s protocol.',
                                              style: OmnyaTypography.bodyMedium(
                                                color: isDark ? OmnyaColors.taupe : OmnyaColors.charcoalMuted,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  HapticFeedback.lightImpact();
                                                  Navigator.pop(dialogCtx);
                                                },
                                                child: Text(
                                                  'Cancel',
                                                  style: OmnyaTypography.bodyMedium(color: OmnyaColors.taupeDark),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  HapticFeedback.mediumImpact();
                                                  Navigator.pop(dialogCtx);
                                                  Navigator.of(context).pop();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      backgroundColor: OmnyaColors.plumDeep,
                                                      behavior: SnackBarBehavior.floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(14),
                                                      ),
                                                      content: Text(
                                                        'Logged ${p['name']} scheduled dose',
                                                        style: OmnyaTypography.bodyMedium(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  'Log dose',
                                                  style: OmnyaTypography.label(
                                                    color: isDark ? OmnyaColors.plumSoft : OmnyaColors.plum,
                                                    weight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
