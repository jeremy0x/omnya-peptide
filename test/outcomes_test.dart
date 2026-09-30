import 'package:flutter_test/flutter_test.dart';
import 'package:peptide_app/data/models/compound.dart';
import 'package:peptide_app/data/models/daily_check_in.dart';
import 'package:peptide_app/domain/outcomes.dart';
import 'package:peptide_app/domain/schedule.dart';
import 'insights_test.dart' show reta, log, now;

DailyCheckIn day(DateTime at, {double? lb, double? waist, List<String> effects = const []}) => DailyCheckIn(
  id: at.toIso8601String(),
  date: at,
  energyLevel: 3,
  appetiteLevel: 3,
  weightLbs: lb,
  waistIn: waist,
  sideEffects: effects,
);

void main() {
  test('titration: the latest started step sets the dose', () {
    final c = reta().copyWith(
      titration: [TitrationStep(DateTime(2026, 9, 10), 4), TitrationStep(DateTime(2026, 10, 10), 6)],
    );
    expect(c.doseOn(DateTime(2026, 9, 5)), 2);
    expect(c.doseOn(DateTime(2026, 9, 30)), 4);
    expect(c.doseOn(DateTime(2026, 10, 10)), 6);
    expect(formatDose(500, 'mcg'), '500 mcg');
  });

  test('outcome engine waits for day 14, then reads changes and doses kept', () {
    final start = DateTime(2026, 9, 2, 8);
    final logs = [for (var w = 0; w < 5; w++) log(addDays(start, w * 7), id: 'l$w')];
    final checkIns = [
      day(DateTime(2026, 9, 2), lb: 160, waist: 31, effects: ['Nausea']),
      day(DateTime(2026, 9, 4), lb: 159.6, effects: ['Nausea']),
      day(DateTime(2026, 9, 27), lb: 155.2, waist: 30),
      day(DateTime(2026, 9, 29), lb: 154.8),
    ];

    final early = outcomeReport(
      compounds: [reta()],
      logs: logs.take(1).toList(),
      checkIns: checkIns,
      now: DateTime(2026, 9, 10),
    );
    expect(early!.isReady, isFalse);
    expect(early.daysToGo, 5);

    final r = outcomeReport(compounds: [reta()], logs: logs, checkIns: checkIns, now: now)!;
    expect(r.isReady, isTrue);
    final o = r.compounds.single;
    expect(o.changes, containsAll(['weight down 4.8 lb', 'waist down 1 in']));
    expect(o.doses, (logged: 5, planned: 5));
    expect(o.dosesLine, contains('fair read'));
    expect(r.sideEffects.single, 'Nausea: 2 days in your first week, none this week.');
  });

  test('weekly report: change on last week, what is due, vial expiry', () {
    final c = reta(left: 3).copyWith(mixedOn: () => DateTime(2026, 9, 5), vialDays: () => 28);
    final report = weeklyReport(
      compounds: [c],
      logs: [log(DateTime(2026, 9, 26, 8))],
      checkIns: [day(DateTime(2026, 9, 20), lb: 158), day(DateTime(2026, 9, 29), lb: 156)],
      hasCycle: false,
      now: now,
    );
    expect(report.changed.first, 'Weight down 2 lb on last week.');
    expect(report.due, contains("Reta's mixed vial expires Saturday."));
  });
}
