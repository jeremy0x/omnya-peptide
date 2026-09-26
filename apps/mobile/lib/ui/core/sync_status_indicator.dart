import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/omnya_colors.dart';
import '../../core/theme/omnya_typography.dart';
import '../../core/widgets/omnya_toast.dart';
import '../../data/repositories/protocol_repository.dart';

class SyncStatusIndicator extends StatefulWidget {
  final bool showLabel;

  const SyncStatusIndicator({
    super.key,
    this.showLabel = false,
  });

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {

  void _onTap(BuildContext context, ProtocolRepository repo) async {
    HapticFeedback.lightImpact();

    if (repo.isSyncing) return;

    if (repo.hasPendingSync) {
      OmnyaToast.show(
        context,
        title: 'Cloud Backup',
        message: 'Syncing pending local changes to cloud...',
        type: OmnyaToastType.info,
      );
      final ok = await repo.syncWithCloud(force: true);
      if (context.mounted) {
        OmnyaToast.show(
          context,
          title: ok ? 'Backed Up to Cloud' : 'Offline Mode Active',
          message: ok
              ? 'All your protocol logs are securely backed up.'
              : 'Protocol logs are stored safely on your device.',
          type: ok ? OmnyaToastType.success : OmnyaToastType.warning,
        );
      }
    } else {
      final lastSync = repo.lastSyncTimestamp;
      final timeStr = lastSync != null ? _formatTimestamp(lastSync) : 'just now';

      OmnyaToast.show(
        context,
        title: 'Cloud Sync Active',
        message: 'All data backed up • Last sync $timeStr',
        type: OmnyaToastType.success,
      );
      repo.syncWithCloud();
    }
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'moments ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProtocolRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color statusColor;
    final List<List<dynamic>> icon;
    final String label;

    if (repo.isSyncing) {
      statusColor = OmnyaColors.plum;
      icon = HugeIcons.strokeRoundedCloudSync;
      label = 'Syncing...';
    } else if (repo.hasPendingSync) {
      statusColor = const Color(0xFFD97706); // warm amber
      icon = HugeIcons.strokeRoundedCloudUpload;
      label = 'Pending sync';
    } else {
      statusColor = OmnyaColors.sage;
      icon = HugeIcons.strokeRoundedCloudCheck;
      label = 'Cloud synced';
    }

    final isCircular = !widget.showLabel;

    return GestureDetector(
      onTap: () => _onTap(context, repo),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isCircular
            ? const EdgeInsets.all(8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF282523) : OmnyaColors.cream,
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : BorderRadius.circular(16),
          border: Border.all(
            color: repo.hasPendingSync
                ? statusColor.withValues(alpha: 0.5)
                : (isDark ? const Color(0xFF3E3935) : OmnyaColors.taupe.withValues(alpha: 0.35)),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HugeIcon(
              icon: icon,
              color: statusColor,
              size: 18,
            ),
            if (repo.isSyncing) ...[
              const SizedBox(width: 5),
              const SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: OmnyaColors.plum,
                ),
              ),
            ],
            if (repo.hasPendingSync) ...[
              const SizedBox(width: 4),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD97706),
                ),
              ),
            ],
            if (widget.showLabel) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: OmnyaTypography.tag(color: statusColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
