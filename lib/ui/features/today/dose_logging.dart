import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/compound_directory.dart';
import '../../../core/widgets/omnya_toast.dart';
import '../../../data/models/compound.dart';
import '../../../data/repositories/protocol_repository.dart';
import '../../../domain/schedule.dart';
import 'milestone_view.dart';

/// Logs a dose and shows a milestone if this dose earned one. Undo sits on the Today card.
Future<void> logDoseWithFeedback(BuildContext context, Compound compound) async {
  final repo = context.read<ProtocolRepository>();
  HapticFeedback.mediumImpact();
  final result = await repo.logDose(compound.id);
  if (!context.mounted) return;
  final milestone = result.milestone;
  if (milestone != null) {
    await MilestoneView.show(
      context,
      milestone,
      dosesLogged: repo.doseLogs.length,
      goal: repo.profile?.day90GoalText ?? '',
    );
    if (!context.mounted) return;
  }
  OmnyaToast.show(
    context,
    title: 'Logged ${CompoundDirectory.shortName(compound.name)}, ${formatDose(result.log.dose, result.log.unit)}',
    message: result.log.injectionSite.isEmpty ? null : result.log.injectionSite,
  );
}
