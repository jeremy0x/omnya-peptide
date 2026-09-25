class UserProfile {
  final String id;
  final List<String> goals;
  final List<String> selectedCompounds;
  final String experienceLevel;
  final bool hasCycle;
  final String day90GoalText;
  final String photoTrackingType; // 'face', 'body', 'both'
  final bool sundayPhotoPromptEnabled;
  final bool isPro;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.goals,
    required this.selectedCompounds,
    required this.experienceLevel,
    required this.hasCycle,
    required this.day90GoalText,
    required this.photoTrackingType,
    required this.sundayPhotoPromptEnabled,
    this.isPro = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'goals': goals,
        'selectedCompounds': selectedCompounds,
        'experienceLevel': experienceLevel,
        'hasCycle': hasCycle,
        'day90GoalText': day90GoalText,
        'photoTrackingType': photoTrackingType,
        'sundayPhotoPromptEnabled': sundayPhotoPromptEnabled,
        'isPro': isPro,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        goals: List<String>.from(json['goals'] as List),
        selectedCompounds: List<String>.from(json['selectedCompounds'] as List),
        experienceLevel: json['experienceLevel'] as String,
        hasCycle: json['hasCycle'] as bool,
        day90GoalText: json['day90GoalText'] as String,
        photoTrackingType: json['photoTrackingType'] as String,
        sundayPhotoPromptEnabled: json['sundayPhotoPromptEnabled'] as bool,
        isPro: json['isPro'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  UserProfile copyWith({
    String? id,
    List<String>? goals,
    List<String>? selectedCompounds,
    String? experienceLevel,
    bool? hasCycle,
    String? day90GoalText,
    String? photoTrackingType,
    bool? sundayPhotoPromptEnabled,
    bool? isPro,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      goals: goals ?? this.goals,
      selectedCompounds: selectedCompounds ?? this.selectedCompounds,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      hasCycle: hasCycle ?? this.hasCycle,
      day90GoalText: day90GoalText ?? this.day90GoalText,
      photoTrackingType: photoTrackingType ?? this.photoTrackingType,
      sundayPhotoPromptEnabled:
          sundayPhotoPromptEnabled ?? this.sundayPhotoPromptEnabled,
      isPro: isPro ?? this.isPro,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
