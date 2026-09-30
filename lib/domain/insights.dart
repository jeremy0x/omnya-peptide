import 'package:intl/intl.dart';
import '../core/constants/compound_directory.dart';
import '../data/models/compound.dart';
import '../data/models/daily_check_in.dart';
import '../data/models/dose_log.dart';
import 'schedule.dart';

/// Every insight describes her own logged data. None of them give advice.
class Insight {
  final String label;
  final String text;
  const Insight(this.label, this.text);
}

class WeightTrend {
  final DateTime from;
  final double delta;
  final int days;
  const WeightTrend(this.from, this.delta, this.days);
}

WeightTrend? weightTrend(List<DailyCheckIn> checkIns) {
  final weighed = checkIns.where((c) => c.weightLbs != null).toList()..sort((a, b) => a.date.compareTo(b.date));
  if (weighed.length < 2) return null;
  return WeightTrend(
    weighed.first.date,
    weighed.last.weightLbs! - weighed.first.weightLbs!,
    daysBetween(weighed.first.date, weighed.last.date),
  );
}

/// Predicted next period from the starts she logged; 28 days until she has logged two.
DateTime? nextPeriodDue(List<DailyCheckIn> checkIns) {
  final starts = checkIns.where((c) => c.periodStarted).map((c) => dayOf(c.date)).toList()..sort();
  if (starts.isEmpty) return null;
  final gaps = <int>[
    for (var i = 1; i < starts.length; i++) daysBetween(starts[i - 1], starts[i]),
  ].where((g) => g >= 21 && g <= 45).toList();
  final cycle = gaps.isEmpty ? 28 : (gaps.reduce((a, b) => a + b) / gaps.length).round();
  return addDays(starts.last, cycle);
}

/// Change between her latest weigh-in and one about a week before it.
double? weeklyWeightChange(List<DailyCheckIn> checkIns, DateTime now) {
  final weighed = checkIns.where((c) => c.weightLbs != null).toList()..sort((a, b) => b.date.compareTo(a.date));
  if (weighed.isEmpty || daysBetween(weighed.first.date, now) > 3) return null;
  final latest = weighed.first;
  for (final c in weighed.skip(1)) {
    final gap = daysBetween(c.date, latest.date);
    if (gap >= 4 && gap <= 10) return latest.weightLbs! - c.weightLbs!;
  }
  return null;
}

String _lb(double v) => v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');

/// The one line on Today. Null until she has logged enough to say something true.
Insight? todayInsight({
  required List<Compound> compounds,
  required List<DoseLog> logs,
  required List<DailyCheckIn> checkIns,
  required bool hasCycle,
  required DateTime now,
}) {
  for (final c in compounds.where((c) => c.isConfigured)) {
    final name = CompoundDirectory.shortName(c.name);
    if (c.dosesLeft == 0) return Insight('Stack', '$name is out of doses. Update it when you restock.');
    final expires = c.vialExpires;
    if (expires != null && daysBetween(now, expires) <= 3) {
      return Insight(
        'Stack',
        daysBetween(now, expires) < 0
            ? "$name's mixed vial is past its date."
            : "$name's mixed vial expires ${relativeDay(expires, now)}.",
      );
    }
    final runout = runoutDay(c, logs);
    if (runout != null) {
      final d = daysBetween(now, runout);
      if (d >= 0 && d <= 6) return Insight('Stack', '$name runs out ${relativeDay(runout, now)}.');
    }
  }

  if (hasCycle) {
    final due = nextPeriodDue(checkIns);
    final up = weeklyWeightChange(checkIns, now);
    if (due != null && up != null && up >= 1) {
      final d = daysBetween(now, due);
      if (d >= 0 && d <= 7) {
        return Insight('Cycle', "Scale's up ${_lb(up)} lb, period's due ${relativeDay(due, now)}. Ignore it.");
      }
    }
  }

  final trend = weightTrend(checkIns);
  if (trend != null && trend.days >= 7 && trend.delta <= -0.5) {
    return Insight('Progress', 'Down ${_lb(-trend.delta)} lb since ${DateFormat('MMM d').format(trend.from)}.');
  }

  final n = loggedThisWeek(logs, now);
  if (n > 0) return Insight('This week', '$n ${n == 1 ? 'dose' : 'doses'} logged this week.');

  return null;
}

class Highlight {
  final String stat;
  final String caption;
  const Highlight(this.stat, this.caption);
}

/// The one plain-English result on Progress.
Highlight? progressHighlight(List<DailyCheckIn> checkIns, DateTime now) {
  final trend = weightTrend(checkIns);
  if (trend != null && trend.days >= 7 && trend.delta.abs() >= 0.5) {
    final sign = trend.delta < 0 ? '−' : '+';
    return Highlight('$sign${_lb(trend.delta.abs())} lb', 'since ${DateFormat('MMM d').format(trend.from)}');
  }

  final sorted = [...checkIns]..sort((a, b) => a.date.compareTo(b.date));
  if (sorted.length >= 6 && daysBetween(sorted.first.date, now) >= 14) {
    double avg(Iterable<DailyCheckIn> xs) => xs.map((c) => c.energyLevel!).reduce((a, b) => a + b) / xs.length;
    final rated = sorted.where((c) => c.energyLevel != null).toList();
    final firstWeek = rated.where((c) => daysBetween(sorted.first.date, c.date) < 7);
    final lastWeek = rated.where((c) => daysBetween(c.date, now) < 7);
    if (firstWeek.isNotEmpty && lastWeek.isNotEmpty) {
      final diff = avg(lastWeek) - avg(firstWeek);
      if (diff.abs() >= 0.5) {
        return Highlight(
          '${diff > 0 ? '+' : '−'}${diff.abs().toStringAsFixed(1)}',
          'average energy this week, compared with your first week',
        );
      }
    }
  }
  return null;
}

enum Milestone { firstDose, day30, day90 }

/// Which milestone, if any, the dose just logged completes. Each shows once.
/// Day 30 and 90 only show during that week, so a late upgrade doesn't celebrate day 30 on day 70.
Milestone? milestoneAfterLog(List<DoseLog> logs, Set<String> celebrated, DateTime now) {
  if (logs.isEmpty) return null;
  final first = logs.map((l) => l.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);
  final day = daysBetween(first, now) + 1;
  if (day >= 90 && day < 97 && !celebrated.contains(Milestone.day90.name)) return Milestone.day90;
  if (day >= 30 && day < 37 && !celebrated.contains(Milestone.day30.name)) return Milestone.day30;
  if (logs.length == 1 && !celebrated.contains(Milestone.firstDose.name)) return Milestone.firstDose;
  return null;
}
