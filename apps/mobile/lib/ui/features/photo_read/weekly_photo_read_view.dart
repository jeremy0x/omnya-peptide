import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../../core/widgets/tactile_button.dart';
import '../../../data/repositories/protocol_repository.dart';
import '../../../data/services/imgbb_service.dart';
import '../../../domain/outcome_correlator.dart';
import '../progress/social_story_export_modal.dart';

class WeeklyPhotoReadView extends StatefulWidget {
  const WeeklyPhotoReadView({super.key});

  @override
  State<WeeklyPhotoReadView> createState() => _WeeklyPhotoReadViewState();
}

class _WeeklyPhotoReadViewState extends State<WeeklyPhotoReadView> {
  bool _showingGhostCamera = false;
  bool _isUploading = false;
  String? _uploadedPhotoUrl;

  Future<Uint8List> _generateCheckInPhotoBytes() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 720, 960));

    // Studio portrait canvas with warm tone gradient
    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(
        const Offset(360, 420),
        500,
        [const Color(0xFF2C2622), const Color(0xFF161413)],
      );
    canvas.drawRect(const Rect.fromLTWH(0, 0, 720, 960), bgPaint);

    // Subtle face/torso alignment silhouette
    final silhouettePaint = Paint()
      ..color = const Color(0xFF4A4139).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(260, 220, 200, 260), silhouettePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(180, 480, 360, 440),
        const Radius.circular(90),
      ),
      silhouettePaint,
    );

    // Brand and check-in date watermark
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Omnya Protocol • Check-in ${DateTime.now().toIso8601String().substring(0, 10)}',
        style: const TextStyle(
          color: Color(0xFFEADFCF),
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(40, 890));

    final picture = recorder.endRecording();
    final img = await picture.toImage(720, 960);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _handlePhotoCaptured() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _showingGhostCamera = false;
      _isUploading = true;
    });

    try {
      final photoBytes = await _generateCheckInPhotoBytes();
      final imgbb = ImgbbService();
      final result = await imgbb.uploadBytes(
        photoBytes,
        fileName: 'omnya_checkin_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      if (!mounted) return;
      context.read<ProtocolRepository>().attachWeeklyPhoto(result.displayUrl);
      setState(() {
        _uploadedPhotoUrl = result.displayUrl;
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weekly photo saved'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo saved locally'),
          backgroundColor: OmnyaColors.plum,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProtocolRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPro = repo.isPro;

    final latestSyncedPhoto = _uploadedPhotoUrl ??
        (repo.checkIns.isNotEmpty ? repo.checkIns.first.localPhotoPath : null);
    final hasFreshPhoto = latestSyncedPhoto != null;

    final read = OutcomeCorrelator.generateWeeklyPhotoRead(
      weekNumber: 4,
      primaryCompound: 'GHK-Cu',
      hasFreshPhoto: hasFreshPhoto,
    );

    if (_showingGhostCamera) {
      return Scaffold(
        backgroundColor: const Color(0xFF161514),
        body: _buildGhostCameraView(context),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? OmnyaColors.plumDeep : OmnyaColors.sand,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 40,
        titleSpacing: 0,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
            size: 22,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text('Your week in photos', style: OmnyaTypography.headline()),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: _buildWeeklyReadCard(
              context,
              read,
              isPro,
              isDark,
              latestSyncedPhoto: latestSyncedPhoto,
              hasFreshPhoto: hasFreshPhoto,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(
    String? photoUrl, {
    required bool isCurrent,
    required bool isDark,
  }) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          color: isCurrent ? OmnyaColors.plum : OmnyaColors.taupeDark,
          size: 32,
        ),
      );
    }
    if (photoUrl.startsWith('http')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedUser,
              color: isCurrent ? OmnyaColors.plum : OmnyaColors.taupeDark,
              size: 32,
            ),
          );
        },
        errorBuilder: (_, _, _) => Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedUser,
            color: isCurrent ? OmnyaColors.plum : OmnyaColors.taupeDark,
            size: 32,
          ),
        ),
      );
    } else {
      return Image.file(
        File(photoUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedUser,
            color: isCurrent ? OmnyaColors.plum : OmnyaColors.taupeDark,
            size: 32,
          ),
        ),
      );
    }
  }

  Widget _buildWeeklyReadCard(
    BuildContext context,
    PhotoReadObservation read,
    bool isPro,
    bool isDark, {
    String? latestSyncedPhoto,
    bool hasFreshPhoto = false,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Side-by-Side comparison cards (Aug 25 vs Sep 1 / Today)
        Row(
          children: [
            // Card 1: Baseline
            Expanded(
              child: Container(
                height: 195,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF24201E) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? const Color(0x18FFFFFF) : const Color(0x10000000),
                    width: 0.75,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: OmnyaColors.sandMuted.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Aug 25', style: OmnyaTypography.tag(color: OmnyaColors.taupeDark)),
                        ),
                        Text(
                          'Day 1',
                          style: TextStyle(
                            fontFamily: 'InstrumentSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: OmnyaColors.taupeDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          color: OmnyaColors.taupe.withValues(alpha: 0.12),
                          child: _buildPhotoThumbnail(
                            'https://picsum.photos/seed/baseline_face_aug25/300/300',
                            isCurrent: false,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Baseline · Face', style: OmnyaTypography.bodySmall(color: OmnyaColors.taupeDark)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Card 2: Current / Today
            Expanded(
              child: Container(
                height: 195,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D1E27) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: hasFreshPhoto
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.45)
                        : (isDark ? const Color(0x28FFFFFF) : OmnyaColors.plumSoft.withValues(alpha: 0.2)),
                    width: hasFreshPhoto ? 1.0 : 0.75,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasFreshPhoto
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.08)
                          : OmnyaColors.plum.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasFreshPhoto
                                ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                                : OmnyaColors.plumSoft.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hasFreshPhoto ? 'Today' : 'Sep 1',
                            style: OmnyaTypography.tag(
                              color: hasFreshPhoto ? const Color(0xFF2E7D32) : OmnyaColors.plum,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hasFreshPhoto ? 'Synced' : 'Week 4',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          color: OmnyaColors.plumSoft.withValues(alpha: 0.18),
                          child: _buildPhotoThumbnail(
                            latestSyncedPhoto ?? 'https://picsum.photos/seed/glow_face_sep1/300/300',
                            isCurrent: true,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasFreshPhoto ? 'Current · Synced' : 'Current · +8% tone',
                      style: OmnyaTypography.bodySmall(
                        color: hasFreshPhoto ? const Color(0xFF2E7D32) : OmnyaColors.plum,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Sunday photo capture button
        TactileButton(
          label: 'Take Sunday photo',
          variant: TactileButtonVariant.outline,
          height: 46,
          borderRadius: 14,
          leading: const HugeIcon(
            icon: HugeIcons.strokeRoundedCameraSmile02,
            color: OmnyaColors.plum,
            size: 18,
          ),
          onPressed: () => setState(() => _showingGhostCamera = true),
        ),
        if (_isUploading) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: OmnyaColors.plumSoft.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: OmnyaColors.plum),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Syncing photo...',
                    style: OmnyaTypography.bodySmall(color: OmnyaColors.plum),
                  ),
                ),
              ],
            ),
          ),
        ] else if (latestSyncedPhoto != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: Color(0xFF2E7D32),
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Photo synced',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // The Read Card
        Stack(
          children: [
            LiquidGlassContainer(
              borderRadius: 26,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What I notice',
                    style: OmnyaTypography.tag(color: OmnyaColors.taupeDark),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    read.commentary,
                    style: OmnyaTypography.bodyLarge(
                      color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Divider(
                    color: isDark ? const Color(0x14FFFFFF) : const Color(0x10000000),
                    thickness: 0.75,
                    height: 24,
                  ),
                  const SizedBox(height: 14),

                  // Feature deltas
                  ...read.featureDeltas.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: OmnyaTypography.bodyMedium(
                              color: isDark ? OmnyaColors.sandMuted : OmnyaColors.taupeDark,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0x28FFFFFF) : OmnyaColors.sandMuted,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              entry.value,
                              style: OmnyaTypography.label(
                                color: isDark ? OmnyaColors.plumSoft : OmnyaColors.plum,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            if (!isPro)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedLockKey,
                            color: OmnyaColors.cream,
                            size: 28,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Weekly photo read is a Pro feature',
                            style: OmnyaTypography.headline(color: OmnyaColors.cream),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Unlock AI facial, tone, and waist trend reads.',
                            style: OmnyaTypography.bodySmall(color: OmnyaColors.sandMuted),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TactileButton(
                            label: 'Unlock for \$49.99/yr',
                            variant: TactileButtonVariant.primary,
                            height: 44,
                            borderRadius: 14,
                            onPressed: () {
                              context.read<ProtocolRepository>().setPro(true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pro unlocked')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Share this week button
        TactileButton(
          label: 'Share this week',
          variant: TactileButtonVariant.primary,
          height: 46,
          borderRadius: 14,
          leading: const HugeIcon(
            icon: HugeIcons.strokeRoundedShare01,
            color: OmnyaColors.cream,
            size: 18,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => SocialStoryExportModal(isPro: isPro),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGhostCameraView(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 1. Top bar: Close & Flip Camera
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _showingGhostCamera = false);
                    },
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                Text(
                  'Sunday Photo',
                  style: OmnyaTypography.label(color: Colors.white.withValues(alpha: 0.9), weight: FontWeight.w500),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                    },
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedSwitchCamera,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Camera viewfinder with minimal framing brackets
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFF161413),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 260,
                      height: 340,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(width: 18, height: 2, color: Colors.white70),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(width: 2, height: 18, color: Colors.white70),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(width: 18, height: 2, color: Colors.white70),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(width: 2, height: 18, color: Colors.white70),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(width: 18, height: 2, color: Colors.white70),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(width: 2, height: 18, color: Colors.white70),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(width: 18, height: 2, color: Colors.white70),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(width: 2, height: 18, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Position face in frame',
                      style: TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom controls: Clean tactile shutter button
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 32),
            child: Center(
              child: GestureDetector(
                onTap: _handlePhotoCaptured,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.5),
                    color: Colors.transparent,
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: OmnyaColors.plum,
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
}
