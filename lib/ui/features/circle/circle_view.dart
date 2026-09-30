import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';
import '../../../core/widgets/omnya_card.dart';
import '../../../core/widgets/omnya_controls.dart';
import '../../../core/widgets/omnya_logo.dart';
import '../../../core/widgets/omnya_toast.dart';
import '../../../core/widgets/tactile_button.dart';
import '../../../data/models/circle_data.dart';
import '../../../data/repositories/protocol_repository.dart';
import '../../../data/services/cloud_service.dart';
import '../../../domain/schedule.dart';
import '../../core/omnya_header.dart';

/// Spec page 2: invite-only, up to 5, consistency and shot days only.
class CircleView extends StatefulWidget {
  const CircleView({super.key});

  @override
  State<CircleView> createState() => _CircleViewState();
}

class _CircleViewState extends State<CircleView> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      await context.read<ProtocolRepository>().refreshCircle();
    } catch (e) {
      debugPrint('Circle refresh failed: $e'); // offline: keep showing the cached circle
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProtocolRepository>();
    final circle = repo.circle;

    return RefreshIndicator(
      color: OmnyaColors.plum,
      backgroundColor: OmnyaColors.cream,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          OmnyaHeader(
            title: 'Circle',
            subtitle: circle?.name ?? 'Your accountability group',
            trailing: circle == null
                ? null
                : OmnyaIconButton(
                    icon: HugeIcons.strokeRoundedUserAdd01,
                    tooltip: 'Invite a friend',
                    onPressed: () => _showInvite(context, circle),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: circle == null ? const _NoCircle() : _InCircle(circle: circle, me: repo.myUserId),
          ),
        ],
      ),
    );
  }
}

class _NoCircle extends StatelessWidget {
  const _NoCircle();

  @override
  Widget build(BuildContext context) {
    return OmnyaCard(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OmnyaEmptyState(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, color: OmnyaColors.taupeDark, size: 28),
            title: 'Keep each other going',
            body:
                'Invite up to four friends. You see each other\'s shot days and consistency. '
                'Weights, notes and photos stay private.',
          ),
          const SizedBox(height: 24),
          TactileButton(label: 'Start a circle', onPressed: () => _showNameSheet(context, joining: false)),
          const SizedBox(height: 10),
          TactileButton(
            label: 'Join with a code',
            variant: TactileButtonVariant.outline,
            onPressed: () => _showNameSheet(context, joining: true),
          ),
        ],
      ),
    );
  }
}

class _InCircle extends StatelessWidget {
  final Circle circle;
  final String? me;
  const _InCircle({required this.circle, required this.me});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final week = weekStartOf(now);
    final members = circle.members;
    final loggedToday = members.where((m) => m.loggedOn(now)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OmnyaCard(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 12,
                children: [
                  for (final m in members)
                    Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: m.loggedOn(now) ? OmnyaColors.plum : OmnyaColors.sandMuted,
                          ),
                          child: Text(
                            m.initial,
                            style: OmnyaTypography.label(
                              color: m.loggedOn(now) ? OmnyaColors.cream : OmnyaColors.charcoalMuted,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m.userId == me ? 'You' : m.displayName,
                          style: OmnyaTypography.bodySmall(color: OmnyaColors.charcoal),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$loggedToday of ${members.length} logged a dose today',
                style: OmnyaTypography.label(color: OmnyaColors.taupeDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OmnyaCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Consistency this week', style: OmnyaTypography.label(weight: FontWeight.w600)),
              const SizedBox(height: 14),
              for (final m in members)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(m.userId == me ? 'You' : m.displayName, style: OmnyaTypography.bodyLarge())),
                      Text(
                        m.plannedInWeek(week) == 0
                            ? '${m.dosesInWeek(week)} logged'
                            : '${m.dosesInWeek(week)}/${m.plannedInWeek(week)}',
                        style: OmnyaTypography.label(color: OmnyaColors.plum, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                'Doses logged against doses planned. Only shot days and consistency are shared.',
                style: OmnyaTypography.bodySmall(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (circle.spotsLeft > 0)
          TactileButton(label: 'Invite a friend', onPressed: () => _showInvite(context, circle)),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => _confirmLeave(context),
          child: Text('Leave circle', style: OmnyaTypography.label(color: OmnyaColors.charcoalMuted)),
        ),
      ],
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final repo = context.read<ProtocolRepository>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Leave ${circle.name}?', style: OmnyaTypography.headline()),
        content: Text(
          'You can rejoin later with the code if there is still room.',
          style: OmnyaTypography.bodyMedium(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Leave',
              style: OmnyaTypography.label(color: OmnyaColors.error, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await withLoadingOverlay(context, repo.leaveCircle);
    } on CloudException catch (e) {
      if (context.mounted) {
        OmnyaToast.show(context, title: "Couldn't leave the circle", message: e.message, type: OmnyaToastType.error);
      }
    }
  }
}

void _showInvite(BuildContext context, Circle circle) {
  showOmnyaSheet<void>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Invite a friend', style: OmnyaTypography.headline(), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          '${circle.spotsLeft} of ${circle.maxMembers} spots left. They enter this code in Omnya under Circle.',
          style: OmnyaTypography.bodyMedium(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Semantics(
          button: true,
          label: 'Invite code ${circle.code.split('').join(' ')}. Tap to copy.',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: circle.code));
              HapticFeedback.lightImpact();
              OmnyaToast.show(ctx, title: 'Code copied');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(color: OmnyaColors.sand, borderRadius: BorderRadius.circular(OmnyaRadius.card)),
              child: Text(
                circle.code,
                textAlign: TextAlign.center,
                style: OmnyaTypography.displayMedium(color: OmnyaColors.plum).copyWith(letterSpacing: 8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Tap the code to copy it', style: OmnyaTypography.bodySmall(), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        TactileButton(
          label: 'Share code',
          leading: const HugeIcon(icon: HugeIcons.strokeRoundedShare01, color: OmnyaColors.cream, size: 18),
          onPressed: () {
            final box = ctx.findRenderObject() as RenderBox?;
            SharePlus.instance.share(
              ShareParams(
                text: 'Join my circle on Omnya. Open Circle, tap Join with a code and enter ${circle.code}.',
                sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
              ),
            );
          },
        ),
      ],
    ),
  );
}

/// Asks for her circle name, and the code when joining.
void _showNameSheet(BuildContext context, {required bool joining}) {
  showOmnyaSheet<void>(context, builder: (_) => _NameSheet(joining: joining));
}

class _NameSheet extends StatefulWidget {
  final bool joining;
  const _NameSheet({required this.joining});

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  String? _codeError;
  String? _nameError;
  String? _error;
  bool _busy = false;

  static final _codePattern = RegExp(r'^[A-HJ-NP-Z2-9]{5}$');

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim().toUpperCase();
    final name = _name.text.trim();
    setState(() {
      _codeError = widget.joining && !_codePattern.hasMatch(code)
          ? 'Codes are 5 letters and numbers, without O, I, 0 or 1'
          : null;
      _nameError = name.isEmpty ? 'Add the name your circle will see' : null;
      _error = null;
    });
    if (_codeError != null || _nameError != null) return;

    setState(() => _busy = true);
    final repo = context.read<ProtocolRepository>();
    try {
      if (widget.joining) {
        await repo.joinCircle(code, name);
      } else {
        await repo.createCircle(name);
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
    } on CloudException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.joining ? 'Join a circle' : 'Start a circle', style: OmnyaTypography.headline()),
        const SizedBox(height: 6),
        Text(
          widget.joining
              ? 'Enter the code a friend shared with you.'
              : "You'll get a code to share with up to four friends.",
          style: OmnyaTypography.bodyMedium(),
        ),
        const SizedBox(height: 20),
        if (widget.joining) ...[
          OmnyaField(
            label: 'Invite code',
            controller: _code,
            maxLength: 5,
            capitalization: TextCapitalization.characters,
            error: _codeError,
            autofocus: true,
          ),
          const SizedBox(height: 14),
        ],
        OmnyaField(
          label: 'Your name in the circle',
          controller: _name,
          maxLength: 24,
          capitalization: TextCapitalization.words,
          error: _nameError,
          autofocus: !widget.joining,
        ),
        if (_error != null) ...[const SizedBox(height: 12), OmnyaInlineError(_error!)],
        const SizedBox(height: 20),
        TactileButton(label: widget.joining ? 'Join circle' : 'Start circle', isLoading: _busy, onPressed: _submit),
      ],
    );
  }
}
