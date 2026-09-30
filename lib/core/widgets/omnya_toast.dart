import 'dart:async';
import 'dart:ui';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/omnya_colors.dart';
import '../theme/omnya_typography.dart';

enum OmnyaToastType { success, info, warning, error }

/// A short note that drops in from the top on Liquid Glass (frosted glass before iOS 26).
/// One at a time; swipe up or wait to dismiss.
class OmnyaToast {
  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String title,
    String? message,
    OmnyaToastType type = OmnyaToastType.success,
  }) {
    HapticFeedback.lightImpact();
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Toast(
        title: title,
        message: message,
        type: type,
        onGone: () {
          if (_current == entry) _current = null;
          entry.remove();
        },
      ),
    );
    _current = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }
}

class _Toast extends StatefulWidget {
  final String title;
  final String? message;
  final OmnyaToastType type;
  final VoidCallback onGone;
  const _Toast({required this.title, this.message, required this.type, required this.onGone});

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 200),
  )..forward();
  Timer? _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: widget.type == OmnyaToastType.error ? 4500 : 3000), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_leaving) return;
    _leaving = true;
    _timer?.cancel();
    if (mounted) await _anim.reverse();
    widget.onGone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (widget.type) {
      OmnyaToastType.success => (HugeIcons.strokeRoundedCheckmarkCircle02, OmnyaColors.plum),
      OmnyaToastType.info => (HugeIcons.strokeRoundedInformationCircle, OmnyaColors.plum),
      OmnyaToastType.warning => (HugeIcons.strokeRoundedAlert02, OmnyaColors.taupeDark),
      OmnyaToastType.error => (HugeIcons.strokeRoundedAlertCircle, OmnyaColors.error),
    };
    final curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: HugeIcon(icon: icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: OmnyaTypography.label(weight: FontWeight.w600)),
                if (widget.message != null && widget.message!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(widget.message!, style: OmnyaTypography.bodySmall(color: OmnyaColors.charcoalMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final glass = PlatformVersion.shouldUseNativeGlass
        ? LiquidGlassContainer(
            // Above every sheet, so it keeps its glass while one is open.
            autoHideOnModal: false,
            config: const LiquidGlassConfig(shape: CNGlassEffectShape.rect, cornerRadius: 22),
            child: content,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: OmnyaColors.cream.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: OmnyaColors.line),
                ),
                child: content,
              ),
            ),
          );

    return Positioned(
      left: 12,
      right: 12,
      top: MediaQuery.paddingOf(context).top + 6,
      child: SafeArea(
        top: false,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -0.6), end: Offset.zero).animate(curve),
          child: FadeTransition(
            opacity: curve,
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < 0) _dismiss();
              },
              child: Semantics(
                liveRegion: true,
                label: [widget.title, widget.message].whereType<String>().join('. '),
                excludeSemantics: true,
                child: Material(type: MaterialType.transparency, child: glass),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
