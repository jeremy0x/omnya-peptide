class DoseLog {
  final String id;
  final String compoundId;
  final String compoundName;
  final double doseMg;
  final String injectionSite;
  final DateTime timestamp;

  DoseLog({
    required this.id,
    required this.compoundId,
    required this.compoundName,
    required this.doseMg,
    required this.injectionSite,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'compoundId': compoundId,
        'compoundName': compoundName,
        'doseMg': doseMg,
        'injectionSite': injectionSite,
        'timestamp': timestamp.toIso8601String(),
      };

  factory DoseLog.fromJson(Map<String, dynamic> json) => DoseLog(
        id: json['id'] as String,
        compoundId: json['compoundId'] as String,
        compoundName: json['compoundName'] as String,
        doseMg: (json['doseMg'] as num).toDouble(),
        injectionSite: json['injectionSite'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
