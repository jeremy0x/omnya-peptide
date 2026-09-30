import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/omnya_controls.dart';
import '../../core/widgets/omnya_logo.dart';
import '../../core/widgets/omnya_toast.dart';
import '../../data/repositories/protocol_repository.dart';

/// Plain status of the cloud copy, for the header button and settings.
String backupStatusText(ProtocolRepository repo) {
  if (repo.isSyncing) return 'Backing up now';
  final last = repo.lastSyncTimestamp;
  if (repo.hasPendingSync) {
    return repo.syncError == null ? 'Waiting to back up' : 'Not backed up yet. Everything is saved on this phone.';
  }
  if (last == null) return 'Not backed up yet';
  final ago = DateTime.now().difference(last);
  final when = ago.inMinutes < 1
      ? 'just now'
      : ago.inHours < 1
      ? '${ago.inMinutes} min ago'
      : ago.inDays < 1
      ? '${ago.inHours} h ago'
      : '${ago.inDays} d ago';
  return 'Backed up $when';
}

/// Cloud button in the Today header. While a backup runs, the spinner takes the icon's place.
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  Future<void> _backUpNow(BuildContext context, ProtocolRepository repo) async {
    if (repo.isSyncing) return;
    final ok = await repo.sync();
    if (!context.mounted) return;
    OmnyaToast.show(
      context,
      title: ok ? 'Backed up' : "Couldn't back up right now",
      message: ok ? null : "Everything is saved on this phone. It'll try again on its own.",
      type: ok ? OmnyaToastType.success : OmnyaToastType.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProtocolRepository>();
    return OmnyaIconButton(
      icon: repo.hasPendingSync ? HugeIcons.strokeRoundedCloudUpload : HugeIcons.strokeRoundedCloudSavingDone01,
      tooltip: backupStatusText(repo),
      onPressed: () => _backUpNow(context, repo),
      child: repo.isSyncing ? const OmnyaLogoLoader(size: 26) : null,
    );
  }
}
