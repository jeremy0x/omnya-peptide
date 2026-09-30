enum CyclePhase { follicular, ovulation, luteal, menstruation }

class DailyCheckIn {
  final String id;
  final DateTime date;
  final int energyLevel; // 1-5
  final int appetiteLevel; // 1-5
  final String? localPhotoPath;
  final double? weightLbs;
  final double? waistInches;
  final CyclePhase? cyclePhase;
  final bool isPeriodDay;
  final String? notes;

  DailyCheckIn({
    required this.id,
    required this.date,
    required this.energyLevel,
    required this.appetiteLevel,
    this.localPhotoPath,
    this.weightLbs,
    this.waistInches,
    this.cyclePhase,
    this.isPeriodDay = false,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'energyLevel': energyLevel,
        'appetiteLevel': appetiteLevel,
        'localPhotoPath': localPhotoPath,
        'weightLbs': weightLbs,
        'waistInches': waistInches,
        'cyclePhase': cyclePhase?.name,
        'isPeriodDay': isPeriodDay,
        'notes': notes,
      };

  factory DailyCheckIn.fromJson(Map<String, dynamic> json) => DailyCheckIn(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        energyLevel: json['energyLevel'] as int,
        appetiteLevel: json['appetiteLevel'] as int,
        localPhotoPath: json['localPhotoPath'] as String?,
        weightLbs: json['weightLbs'] != null ? (json['weightLbs'] as num).toDouble() : null,
        waistInches: json['waistInches'] != null ? (json['waistInches'] as num).toDouble() : null,
        cyclePhase: json['cyclePhase'] != null
            ? CyclePhase.values.firstWhere((e) => e.name == json['cyclePhase'])
            : null,
        isPeriodDay: json['isPeriodDay'] as bool? ?? false,
        notes: json['notes'] as String?,
      );

  DailyCheckIn copyWith({
    String? id,
    DateTime? date,
    int? energyLevel,
    int? appetiteLevel,
    String? localPhotoPath,
    double? weightLbs,
    double? waistInches,
    CyclePhase? cyclePhase,
    bool? isPeriodDay,
    String? notes,
  }) {
    return DailyCheckIn(
      id: id ?? this.id,
      date: date ?? this.date,
      energyLevel: energyLevel ?? this.energyLevel,
      appetiteLevel: appetiteLevel ?? this.appetiteLevel,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      weightLbs: weightLbs ?? this.weightLbs,
      waistInches: waistInches ?? this.waistInches,
      cyclePhase: cyclePhase ?? this.cyclePhase,
      isPeriodDay: isPeriodDay ?? this.isPeriodDay,
      notes: notes ?? this.notes,
    );
  }
}
