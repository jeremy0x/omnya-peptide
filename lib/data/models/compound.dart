import '../../core/constants/compound_directory.dart';

class Compound {
  final String id;
  final String name;
  final String nickname;
  final CompoundCategory category;
  final double doseMg;
  final int frequencyDays; // e.g. 7 for weekly, 1 for daily
  final String injectionSite;
  final double vialMg;
  final double bacWaterMl;
  final int dosesLeft;
  final double costPerDose;
  final double totalMonthlyCost;
  final DateTime startDate;
  final DateTime runoutDate;

  Compound({
    required this.id,
    required this.name,
    required this.nickname,
    required this.category,
    required this.doseMg,
    required this.frequencyDays,
    required this.injectionSite,
    required this.vialMg,
    required this.bacWaterMl,
    required this.dosesLeft,
    required this.costPerDose,
    required this.totalMonthlyCost,
    required this.startDate,
    required this.runoutDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nickname': nickname,
        'category': category.name,
        'doseMg': doseMg,
        'frequencyDays': frequencyDays,
        'injectionSite': injectionSite,
        'vialMg': vialMg,
        'bacWaterMl': bacWaterMl,
        'dosesLeft': dosesLeft,
        'costPerDose': costPerDose,
        'totalMonthlyCost': totalMonthlyCost,
        'startDate': startDate.toIso8601String(),
        'runoutDate': runoutDate.toIso8601String(),
      };

  factory Compound.fromJson(Map<String, dynamic> json) => Compound(
        id: json['id'] as String,
        name: json['name'] as String,
        nickname: json['nickname'] as String,
        category: CompoundCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => CompoundCategory.body,
        ),
        doseMg: (json['doseMg'] as num).toDouble(),
        frequencyDays: json['frequencyDays'] as int,
        injectionSite: json['injectionSite'] as String,
        vialMg: (json['vialMg'] as num).toDouble(),
        bacWaterMl: (json['bacWaterMl'] as num).toDouble(),
        dosesLeft: json['dosesLeft'] as int,
        costPerDose: (json['costPerDose'] as num).toDouble(),
        totalMonthlyCost: (json['totalMonthlyCost'] as num).toDouble(),
        startDate: DateTime.parse(json['startDate'] as String),
        runoutDate: DateTime.parse(json['runoutDate'] as String),
      );

  Compound copyWith({
    String? id,
    String? name,
    String? nickname,
    CompoundCategory? category,
    double? doseMg,
    int? frequencyDays,
    String? injectionSite,
    double? vialMg,
    double? bacWaterMl,
    int? dosesLeft,
    double? costPerDose,
    double? totalMonthlyCost,
    DateTime? startDate,
    DateTime? runoutDate,
  }) {
    return Compound(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      category: category ?? this.category,
      doseMg: doseMg ?? this.doseMg,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      injectionSite: injectionSite ?? this.injectionSite,
      vialMg: vialMg ?? this.vialMg,
      bacWaterMl: bacWaterMl ?? this.bacWaterMl,
      dosesLeft: dosesLeft ?? this.dosesLeft,
      costPerDose: costPerDose ?? this.costPerDose,
      totalMonthlyCost: totalMonthlyCost ?? this.totalMonthlyCost,
      startDate: startDate ?? this.startDate,
      runoutDate: runoutDate ?? this.runoutDate,
    );
  }
}
