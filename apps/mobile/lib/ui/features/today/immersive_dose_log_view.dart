import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';

/// Clean, editorial full-screen dose logging ritual.
///
/// Principles applied:
/// - Staggered entrance choreography: elements slowly glide & fade in sequentially.
/// - Serene background ambience with calm, subtle breathing depth (zero particle clutter).
/// - Exact design match to the search button: a clean off-white circular surface
///   with a single stroke checkmark icon (HugeIcons.strokeRoundedTick02).
/// - Zero extraneous icons: all status dots and repeat icons removed for pure editorial clarity.
class ImmersiveDoseLogView extends StatefulWidget {
  final String compoundName;
  final double doseMg;
  final String injectionSite;
  final String nextSite;
  final String category;

  const ImmersiveDoseLogView({
    super.key,
    required this.compoundName,
    required this.doseMg,
    required this.injectionSite,
    required this.nextSite,
    required this.category,
  });

  static Future<void> show(
    BuildContext context, {
    required String compoundName,
    required double doseMg,
    required String injectionSite,
    required String nextSite,
    required String category,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ImmersiveDoseLogView(
            compoundName: compoundName,
            doseMg: doseMg,
            injectionSite: injectionSite,
            nextSite: nextSite,
            category: category,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<ImmersiveDoseLogView> createState() => _ImmersiveDoseLogViewState();
}

class _ImmersiveDoseLogViewState extends State<ImmersiveDoseLogView>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _entranceController;

  late final Animation<double> _checkOpacity;
  late final Animation<double> _checkScale;
  late final Animation<Offset> _checkSlide;

  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardSlide;

  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    // 1. Serene ambient breathing background (slow 5.5s cycle)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat(reverse: true);

    // 2. Choreographed entrance animation (1100ms total staggered entrance)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Stagger 1: Checkmark circle (0.0 -> 0.55)
    final checkCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(checkCurve);
    _checkScale = Tween<double>(begin: 0.82, end: 1.0).animate(checkCurve);
    _checkSlide = Tween<Offset>(
      begin: const Offset(0, 18),
      end: Offset.zero,
    ).animate(checkCurve);

    // Stagger 2: Headline & subtitle (0.20 -> 0.70)
    final textCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.20, 0.70, curve: Curves.easeOutCubic),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(textCurve);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 22),
      end: Offset.zero,
    ).animate(textCurve);

    // Stagger 3: Details summary card (0.38 -> 0.86)
    final cardCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.38, 0.86, curve: Curves.easeOutCubic),
    );
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(cardCurve);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 24),
      end: Offset.zero,
    ).animate(cardCurve);

    // Stagger 4: Bottom Done action (0.55 -> 1.00)
    final buttonCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 1.00, curve: Curves.easeOutCubic),
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(buttonCurve);
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(buttonCurve);

    _startChoreography();
  }

  void _startChoreography() async {
    // Initial subtle acknowledgement
    await HapticFeedback.lightImpact();
    if (!mounted) return;

    _entranceController.forward();

    // Medium confirmatory haptic right as the checkmark settles into place (~450ms)
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    await HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _onDone() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    return Scaffold(
      backgroundColor: const Color(0xFF130911),
      body: Stack(
        children: [
          // 1. Ambient Living Background (Deep rich Omnya Plum with subtle breathing depth)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) {
                final breath = _ambientController.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.25),
                      radius: 1.0 + 0.20 * breath,
                      colors: [
                        Color.lerp(
                          const Color(0xFF2E1325),
                          const Color(0xFF3B1830),
                          breath,
                        )!,
                        const Color(0xFF1F0D19),
                        const Color(0xFF130911),
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Main Content Column with Sequenced Staggered Entrance
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // Top header: Clean, quiet timestamp (no badges or dot icons)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DOSE RECORDED',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.45),
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: GoogleFonts.instrumentSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.40),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(flex: 3),

                      // Item 1: Central Checkmark Icon
                      // Styled like the search button: Clean circular surface with stroke checkmark
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _checkOpacity.value,
                            child: Transform.translate(
                              offset: _checkSlide.value,
                              child: Transform.scale(
                                scale: _checkScale.value,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFCF9F6), // matching search button cream surface
                            border: Border.all(
                              color: const Color(0x44B5A496), // matching search button border
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedTick02,
                              color: OmnyaColors.charcoal,
                              size: 32,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Item 2: Headline & Subtitle
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textOpacity.value,
                            child: Transform.translate(
                              offset: _textSlide.value,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Text(
                              'Dose Logged',
                              style: OmnyaTypography.displayMedium(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your administration has been recorded and synced.',
                              style: OmnyaTypography.bodyMedium(
                                color: Colors.white.withValues(alpha: 0.68),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Item 3: Administration Details Card (Pure editorial layout, zero icons)
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _cardOpacity.value,
                            child: Transform.translate(
                              offset: _cardSlide.value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Compound name & Category pill
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.compoundName,
                                        style: OmnyaTypography.headline(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Target: ${widget.doseMg.toStringAsFixed(1)} mg',
                                        style: OmnyaTypography.bodySmall(
                                          color: Colors.white.withValues(
                                            alpha: 0.60,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.16),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      widget.category,
                                      style: GoogleFonts.instrumentSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.85),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  height: 1,
                                ),
                              ),

                              // Administration & Next Rotation details (No icons, pure typography)
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ADMINISTERED',
                                          style: GoogleFonts.instrumentSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withValues(
                                              alpha: 0.45,
                                            ),
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.injectionSite,
                                          style: OmnyaTypography.bodyMedium(
                                            color: Colors.white.withValues(
                                              alpha: 0.95,
                                            ),
                                          ).copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 32,
                                    color: Colors.white.withValues(alpha: 0.10),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'NEXT ROTATION',
                                          style: GoogleFonts.instrumentSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withValues(
                                              alpha: 0.45,
                                            ),
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.nextSite,
                                          style: OmnyaTypography.bodyMedium(
                                            color: const Color(0xFFF1E4C3), // gentle warm gold highlight
                                          ).copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 4),

                      // Item 4: Bottom Done Action
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _buttonOpacity.value,
                            child: Transform.translate(
                              offset: _buttonSlide.value,
                              child: child,
                            ),
                          );
                        },
                        child: _RitualDoneButton(
                          onPressed: _onDone,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile Done button matching Omnya's warm minimal brand aesthetic
/// and design engineering principle: scale(0.96) on press.
class _RitualDoneButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _RitualDoneButton({required this.onPressed});

  @override
  State<_RitualDoneButton> createState() => _RitualDoneButtonState();
}

class _RitualDoneButtonState extends State<_RitualDoneButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
    );
    // make-interfaces-feel-better principle: scale(0.96) exactly
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFFCF9F6), // warm off-white cream surface
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0x44B5A496),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Done',
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: OmnyaColors.charcoal,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
