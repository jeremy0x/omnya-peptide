import 'package:hugeicons/hugeicons.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/compound_directory.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';
import '../../../core/widgets/omnya_controls.dart';
import '../../../core/widgets/omnya_toast.dart';
import '../../../core/widgets/tactile_button.dart';
import '../../../data/repositories/protocol_repository.dart';
import '../../../data/services/native_service.dart';
import '../../../data/services/subscription_service.dart';
import '../../../domain/insights.dart';
import '../../../domain/schedule.dart';

/// The 9:16 progress card (spec page 6): one headline from her own numbers and
/// the wordmark in the corner. Her photo is optional and always goes out with faces blurred.
Future<void> showProgressCard(BuildContext context) =>
    showOmnyaSheet(context, builder: (_) => const _ProgressCardSheet());

class _ProgressCardSheet extends StatefulWidget {
  const _ProgressCardSheet();

  @override
  State<_ProgressCardSheet> createState() => _ProgressCardSheetState();
}

class _ProgressCardSheetState extends State<_ProgressCardSheet> {
  final _cardKey = GlobalKey();
  bool _sharing = false;
  Uint8List? _photo;
  bool _blurring = false;

  /// Blurs faces on her latest photo before it can appear on the card.
  Future<void> _togglePhoto(ProtocolRepository repo, bool on) async {
    if (!on) return setState(() => _photo = null);
    setState(() => _blurring = true);
    final blurred = await NativeService.blurFaces(repo.photoFile(repo.photos.last).path);
    if (!mounted) return;
    setState(() {
      _blurring = false;
      _photo = blurred;
    });
    if (blurred == null) {
      OmnyaToast.show(context, title: "Couldn't prepare the photo", type: OmnyaToastType.error);
    }
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      // 1080 px wide: the size story formats expect.
      final image = await boundary.toImage(pixelRatio: 1080 / boundary.size.width);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/omnya-progress.png').writeAsBytes(png!.buffer.asUint8List());
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      debugPrint('Share failed: $e');
      if (mounted) {
        OmnyaToast.show(
          context,
          title: "Couldn't open sharing",
          message: 'Try again, or take a screenshot.',
          type: OmnyaToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProtocolRepository>();
    final now = DateTime.now();
    final logs = repo.doseLogs;
    final started = logs.isNotEmpty ? logs.last.timestamp : repo.profile?.createdAt ?? now;
    final day = daysBetween(started, now) + 1;
    final week = (day - 1) ~/ 7 + 1;
    final names = repo.compounds
        .where((c) => c.isConfigured)
        .map((c) => CompoundDirectory.shortName(c.name))
        .take(3)
        .join(' + ');
    final trend = weightTrend(repo.checkIns);
    final headline = trend != null && trend.days >= 7 && trend.delta <= -0.5
        ? 'Down ${trend.delta.abs().toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')} lb.'
        : logs.isEmpty
        ? 'Day $day.'
        : 'Week $week.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Your progress card', style: OmnyaTypography.headline()),
        const SizedBox(height: 4),
        Text('Made from your own logs. Shares as an image.', style: OmnyaTypography.bodySmall()),
        const SizedBox(height: 18),
        Center(
          child: SizedBox(
            width: 250,
            child: RepaintBoundary(
              key: _cardKey,
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: OmnyaColors.plum,
                    borderRadius: BorderRadius.circular(OmnyaRadius.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        names.isEmpty ? 'Week $week' : 'Week $week · $names',
                        style: OmnyaTypography.tag(color: OmnyaColors.sandMuted),
                      ),
                      if (_photo != null) ...[
                        const SizedBox(height: 14),
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(OmnyaRadius.chip),
                            child: Image.memory(_photo!, fit: BoxFit.cover, width: double.infinity),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(headline, style: OmnyaTypography.displayLarge(color: OmnyaColors.cream)),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _Stat(label: 'Doses logged', value: '${logs.length}'),
                          ),
                          Expanded(
                            child: _Stat(label: 'Days tracked', value: '$day'),
                          ),
                        ],
                      ),
                      if (!context.watch<SubscriptionService>().isPro) ...[
                        const SizedBox(height: 18),
                        Text('made with Omnya', style: OmnyaTypography.bodySmall(color: OmnyaColors.sandMuted)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (repo.photos.isNotEmpty && defaultTargetPlatform == TargetPlatform.iOS) ...[
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _photo != null || _blurring,
            onChanged: _blurring ? null : (v) => _togglePhoto(repo, v),
            activeTrackColor: OmnyaColors.plum,
            title: Text('Add my latest photo', style: OmnyaTypography.label(weight: FontWeight.w600)),
            subtitle: Text('Faces are blurred before it goes on the card.', style: OmnyaTypography.bodySmall()),
          ),
        ],
        const SizedBox(height: 20),
        TactileButton(
          label: 'Share',
          width: double.infinity,
          isLoading: _sharing,
          leading: const HugeIcon(icon: HugeIcons.strokeRoundedShare01, color: OmnyaColors.cream, size: 18),
          onPressed: () {
            HapticFeedback.lightImpact();
            _share();
          },
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OmnyaTypography.bodySmall(color: OmnyaColors.sandMuted)),
        const SizedBox(height: 2),
        Text(value, style: OmnyaTypography.headline(color: OmnyaColors.cream)),
      ],
    );
  }
}
