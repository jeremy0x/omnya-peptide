const sideEffectOptions = ['Nausea', 'Headache', 'Tired', 'Bloating', 'Site reaction', 'Cycle change'];

class DailyCheckIn {
  final String id;
  final DateTime date;

  /// 1-5. Null on weigh-ins brought in by import, where she didn't rate them.
  final int? energyLevel;
  final int? appetiteLevel;
  final double? weightLbs;
  final double? waistIn;
  final double? sleepHours;

  /// 0 (none) to 10.
  final int? pain;
  final List<String> sideEffects;

  /// Skin and hair notes, in her words.
  final String notes;
  final bool periodStarted;

  const DailyCheckIn({
    required this.id,
    required this.date,
    this.energyLevel,
    this.appetiteLevel,
    this.weightLbs,
    this.waistIn,
    this.sleepHours,
    this.pain,
    this.sideEffects = const [],
    this.notes = '',
    this.periodStarted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'energyLevel': energyLevel,
    'appetiteLevel': appetiteLevel,
    'weightLbs': weightLbs,
    'waistIn': waistIn,
    'sleepHours': sleepHours,
    'pain': pain,
    'sideEffects': sideEffects,
    'notes': notes,
    'periodStarted': periodStarted,
  };

  factory DailyCheckIn.fromJson(Map<String, dynamic> json) => DailyCheckIn(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    energyLevel: json['energyLevel'] as int?,
    appetiteLevel: json['appetiteLevel'] as int?,
    weightLbs: (json['weightLbs'] as num?)?.toDouble(),
    waistIn: (json['waistIn'] as num?)?.toDouble(),
    sleepHours: (json['sleepHours'] as num?)?.toDouble(),
    pain: json['pain'] as int?,
    sideEffects: List<String>.from(json['sideEffects'] as List? ?? const []),
    notes: json['notes'] as String? ?? '',
    periodStarted: json['periodStarted'] as bool? ?? false,
  );
}
