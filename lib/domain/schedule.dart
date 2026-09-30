import 'package:intl/intl.dart';
import '../data/models/compound.dart';
import '../data/models/dose_log.dart';

// Calendar-day math. DateTime(y, m, d + n) instead of Duration keeps DST days correct.

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

DateTime addDays(DateTime day, int n) => DateTime(day.year, day.month, day.day + n);

int daysBetween(DateTime from, DateTime to) => (dayOf(to).difference(dayOf(from)).inHours / 24).round();

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Weeks start on Monday.
DateTime weekStartOf(DateTime t) => addDays(dayOf(t), 1 - t.weekday);

DoseLog? lastDoseOf(String compoundId, List<DoseLog> logs) {
  DoseLog? last;
  for (final l in logs) {
    if (l.compoundId == compoundId && (last == null || l.timestamp.isAfter(last.timestamp))) last = l;
  }
  return last;
}

DateTime nextDueDay(Compound c, List<DoseLog> logs) {
  final last = lastDoseOf(c.id, logs);
  return last == null ? dayOf(c.startDate) : addDays(dayOf(last.timestamp), c.frequencyDays);
}

/// The day of her last available dose, or null when she isn't tracking doses left.
DateTime? runoutDay(Compound c, List<DoseLog> logs) {
  final left = c.dosesLeft;
  if (left == null || left == 0 || !c.isConfigured) return null;
  return addDays(nextDueDay(c, logs), (left - 1) * c.frequencyDays);
}

/// The dose Today shows: the configured compound that is due soonest.
Compound? nextUp(List<Compound> compounds, List<DoseLog> logs) {
  final ready = compounds.where((c) => c.isConfigured).toList()
    ..sort((a, b) {
      final byDay = nextDueDay(a, logs).compareTo(nextDueDay(b, logs));
      return byDay != 0 ? byDay : a.name.compareTo(b.name);
    });
  return ready.isEmpty ? null : ready.first;
}

/// Planned doses in a week, e.g. daily = 7, every 3 days = 2, weekly = 1.
int plannedPerWeek(List<Compound> compounds) {
  var total = 0;
  for (final c in compounds.where((c) => c.isConfigured)) {
    final n = (7 / c.frequencyDays).round();
    total += n < 1 ? 1 : n;
  }
  return total;
}

int loggedThisWeek(List<DoseLog> logs, DateTime now) {
  final start = weekStartOf(now);
  return logs.where((l) => !l.timestamp.isBefore(start)).length;
}

/// "today", "tomorrow", "Thursday", "Oct 3", "yesterday".
String relativeDay(DateTime day, DateTime now) {
  final d = daysBetween(now, day);
  if (d == 0) return 'today';
  if (d == 1) return 'tomorrow';
  if (d == -1) return 'yesterday';
  if (d.abs() < 7) return DateFormat('EEEE').format(day);
  return DateFormat('MMM d').format(day);
}

/// "Left thigh · due today" / "Left thigh · was due Tuesday" / "due today" for doses not injected.
String dueLine(Compound c, List<DoseLog> logs, DateTime now) {
  final due = nextDueDay(c, logs);
  final when = daysBetween(now, due) < 0 ? 'was due ${relativeDay(due, now)}' : 'due ${relativeDay(due, now)}';
  return c.isInjected ? '${c.nextSite} · $when' : when;
}

/// "2 mg", "0.25 mg", "500 mcg": no trailing zeros.
String formatDose(double amount, [String unit = 'mg']) {
  final s = amount.toStringAsFixed(amount < 1 ? 3 : 2);
  return '${s.replaceFirst(RegExp(r'\.?0+$'), '')} $unit';
}

/// Her planned dose for the next due day, with its unit.
/// An overdue dose is logged today, so it takes today's step.
String nextDoseLabel(Compound c, List<DoseLog> logs) {
  final due = nextDueDay(c, logs);
  final today = dayOf(DateTime.now());
  return formatDose(c.doseOn(due.isBefore(today) ? today : due), c.unit);
}

String everyLabel(int days) => switch (days) {
  1 => 'daily',
  7 => 'weekly',
  _ => 'every $days days',
};
