/// A weekly photo. The image lives only on the device, in the app's photos folder.
class ProgressPhoto {
  final String id;
  final DateTime takenAt;

  /// File name inside the photos folder. Only the name is stored because the
  /// app container path changes between installs and updates on iOS.
  final String fileName;

  /// Measured on the phone when the photo is saved. Null when no face was found.
  /// Fullness is face width over height; evenness is 0 to 1, higher is more even skin tone.
  final double? fullness;
  final double? evenness;

  const ProgressPhoto({required this.id, required this.takenAt, required this.fileName, this.fullness, this.evenness});

  Map<String, dynamic> toJson() => {
    'id': id,
    'takenAt': takenAt.toIso8601String(),
    'fileName': fileName,
    'fullness': fullness,
    'evenness': evenness,
  };

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) => ProgressPhoto(
    id: json['id'] as String,
    takenAt: DateTime.parse(json['takenAt'] as String),
    fileName: json['fileName'] as String,
    fullness: (json['fullness'] as num?)?.toDouble(),
    evenness: (json['evenness'] as num?)?.toDouble(),
  );
}
