class DoseLog {
  final String id;
  final String compoundId;
  final String compoundName;
  final double dose;
  final String unit;

  /// Empty for doses that aren't injected.
  final String injectionSite;
  final DateTime timestamp;

  DoseLog({
    required this.id,
    required this.compoundId,
    required this.compoundName,
    required this.dose,
    this.unit = 'mg',
    required this.injectionSite,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'compoundId': compoundId,
    'compoundName': compoundName,
    'doseMg': dose,
    'unit': unit,
    'injectionSite': injectionSite,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DoseLog.fromJson(Map<String, dynamic> json) => DoseLog(
    id: json['id'] as String,
    compoundId: json['compoundId'] as String,
    compoundName: json['compoundName'] as String,
    dose: (json['doseMg'] as num).toDouble(),
    unit: json['unit'] as String? ?? 'mg',
    injectionSite: json['injectionSite'] as String? ?? '',
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
