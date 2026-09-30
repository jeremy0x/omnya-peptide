import 'package:flutter_test/flutter_test.dart';
import 'package:peptide_app/domain/reconstitution_calculator.dart';
import 'package:peptide_app/domain/outcome_correlator.dart';
import 'package:peptide_app/core/constants/compound_directory.dart';
import 'package:peptide_app/data/models/daily_check_in.dart';

void main() {
  group('ReconstitutionCalculator Tests', () {
    test('Calculates standard 10mg / 2mL / 2mg dose on U-100 syringe', () {
      final result = ReconstitutionCalculator.calculate(
        vialMg: 10.0,
        bacWaterMl: 2.0,
        targetDoseMg: 2.0,
        vialCost: 45.0,
      );

      // Concentration = 10mg / 2mL = 5 mg/mL
      expect(result.concentrationMgPerMl, 5.0);
      // Dose volume = 2mg / 5mg/mL = 0.4 mL
      expect(result.doseVolumeMl, 0.4);
      // U-100 units = 0.4 mL * 100 = 40 units
      expect(result.u100Units, 40.0);
      // U-40 units = 0.4 mL * 40 = 16 units
      expect(result.u40Units, 16.0);
      // Total doses = 10 / 2 = 5 doses
      expect(result.totalDosesPerVial, 5);
      // Cost per dose = $45 / 5 = $9.00
      expect(result.costPerDose, 9.0);
    });

    test('Handles zero and negative values gracefully', () {
      final result = ReconstitutionCalculator.calculate(
        vialMg: 0,
        bacWaterMl: 0,
        targetDoseMg: 0,
      );
      expect(result.u100Units, 0.0);
      expect(result.totalDosesPerVial, 0);
    });
  });

  group('OutcomeCorrelator & Clinical Logic', () {
    test('Auto-flags water weight when in luteal phase', () {
      final mockCheckIns = [
        DailyCheckIn(
          id: '1',
          date: DateTime.now(),
          energyLevel: 4,
          appetiteLevel: 3,
          cyclePhase: CyclePhase.luteal,
        ),
      ];

      final insight = OutcomeCorrelator.generateTodayInsight(
        checkIns: mockCheckIns,
        compounds: [],
        doseLogs: [],
        hasCycle: true,
      );

      expect(insight.isCycleRelated, true);
      expect(insight.body, contains("Scale's up 2 lb, period's due Thursday. Ignore it."));
    });

    test('Generates honest weekly photo read deltas', () {
      final read = OutcomeCorrelator.generateWeeklyPhotoRead(
        weekNumber: 4,
        primaryCompound: 'GHK-Cu',
      );

      expect(read.commentary, contains('week 4 on GHK-Cu'));
      expect(read.featureDeltas.containsKey('Face fullness'), true);
      expect(read.featureDeltas.containsKey('Skin evenness'), true);
      expect(read.featureDeltas.containsKey('Waist'), true);
    });
  });

  group('Compound Directory & Nicknames', () {
    test('Contains all official spec compounds and nicknames', () {
      final names = CompoundDirectory.presets.map((c) => c.name).toList();
      expect(names, contains('Retatrutide'));
      expect(names, contains('GHK-Cu'));
      expect(names, contains('KLOW'));

      final reta = CompoundDirectory.presets.firstWhere((c) => c.id == 'reta');
      expect(reta.nickname, 'Dream bod, here we come.');

      final ghk = CompoundDirectory.presets.firstWhere((c) => c.id == 'ghk_cu');
      expect(ghk.nickname, 'Face card will be lethal.');

      final klow = CompoundDirectory.presets.firstWhere((c) => c.id == 'klow');
      expect(klow.nickname, 'Heal, glow, repeat.');
    });
  });
}
