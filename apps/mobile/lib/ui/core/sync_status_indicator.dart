import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/omnya_colors.dart';
import '../../core/theme/omnya_typography.dart';
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

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _onTap(BuildContext context, ProtocolRepository repo) async {
    HapticFeedback.lightImpact();

    if (repo.isSyncing) return;

    if (repo.hasPendingSync) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Syncing pending local changes to cloud...'),
          duration: Duration(seconds: 2),
          backgroundColor: OmnyaColors.plum,
        ),
      );
      final ok = await repo.syncWithCloud(force: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Synced successfully.' : 'Offline. Changes remain safely saved locally.'),
            duration: const Duration(seconds: 2),
            backgroundColor: ok ? OmnyaColors.sage : const Color(0xFFD97706),
          ),
        );
      }
    } else {
      final lastSync = repo.lastSyncTimestamp;
      final timeStr = lastSync != null ? _formatTimestamp(lastSync) : 'just now';

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All data backed up to cloud • Last sync $timeStr'),
          duration: const Duration(seconds: 2),
          backgroundColor: OmnyaColors.plum,
        ),
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

    if (repo.isSyncing) {
      if (!_spinController.isAnimating) {
        _spinController.repeat();
      }
    } else {
      if (_spinController.isAnimating) {
        _spinController.stop();
        _spinController.reset();
      }
    }

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

    return GestureDetector(
      onTap: () => _onTap(context, repo),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: widget.showLabel ? 10 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF282523) : OmnyaColors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: repo.hasPendingSync
                ? statusColor.withValues(alpha: 0.5)
                : (isDark ? const Color(0xFF3E3935) : OmnyaColors.taupe.withValues(alpha: 0.35)),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (repo.isSyncing)
              RotationTransition(
                turns: _spinController,
                child: HugeIcon(
                  icon: icon,
                  color: statusColor,
                  size: 16,
                ),
              )
            else
              HugeIcon(
                icon: icon,
                color: statusColor,
                size: 16,
              ),
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
