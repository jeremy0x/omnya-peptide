/// Mathematical model for volumetric peptide reconstitution and syringe markings.
/// Strictly framed as a mathematical tool in accordance with App Store guidelines.
class ReconstitutionResult {
  final double vialMg;
  final double bacWaterMl;
  final double targetDoseMg;
  final double concentrationMgPerMl;
  final double doseVolumeMl;
  final double u100Units;
  final double u40Units;
  final int totalDosesPerVial;
  final double costPerDose;

  const ReconstitutionResult({
    required this.vialMg,
    required this.bacWaterMl,
    required this.targetDoseMg,
    required this.concentrationMgPerMl,
    required this.doseVolumeMl,
    required this.u100Units,
    required this.u40Units,
    required this.totalDosesPerVial,
    required this.costPerDose,
  });
}

abstract final class ReconstitutionCalculator {
  /// Calculates volumetric dilution and units for insulin syringes.
  /// - [vialMg]: Total peptide amount in vial (e.g., 5mg, 10mg)
  /// - [bacWaterMl]: Bacteriostatic water added in mL (e.g., 2.0mL)
  /// - [targetDoseMg]: Desired dose per injection in mg (e.g., 1.5mg)
  /// - [vialCost]: Cost of the vial in currency (optional, default 0)
  static ReconstitutionResult calculate({
    required double vialMg,
    required double bacWaterMl,
    required double targetDoseMg,
    double vialCost = 0.0,
  }) {
    if (vialMg <= 0 || bacWaterMl <= 0 || targetDoseMg <= 0) {
      return const ReconstitutionResult(
        vialMg: 0,
        bacWaterMl: 0,
        targetDoseMg: 0,
        concentrationMgPerMl: 0,
        doseVolumeMl: 0,
        u100Units: 0,
        u40Units: 0,
        totalDosesPerVial: 0,
        costPerDose: 0,
      );
    }

    final concentration = vialMg / bacWaterMl; // mg/mL
    final doseVolume = targetDoseMg / concentration; // mL
    final u100 = doseVolume * 100.0; // 100 units = 1 mL
    final u40 = doseVolume * 40.0; // 40 units = 1 mL
    final totalDoses = (vialMg / targetDoseMg).floor();
    final costPerDose = totalDoses > 0 ? (vialCost / totalDoses) : 0.0;

    return ReconstitutionResult(
      vialMg: vialMg,
      bacWaterMl: bacWaterMl,
      targetDoseMg: targetDoseMg,
      concentrationMgPerMl: concentration,
      doseVolumeMl: doseVolume,
      u100Units: u100,
      u40Units: u40,
      totalDosesPerVial: totalDoses,
      costPerDose: costPerDose,
    );
  }
}
