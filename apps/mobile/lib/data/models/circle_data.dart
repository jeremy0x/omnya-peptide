class CircleMemberModel {
  final String userId;
  final String displayName;
  final String avatarLetter;
  final bool checkedInToday;
  final int weeklyDosesLogged;
  final int weeklyDosesTarget;

  CircleMemberModel({
    required this.userId,
    required this.displayName,
    required this.avatarLetter,
    required this.checkedInToday,
    required this.weeklyDosesLogged,
    this.weeklyDosesTarget = 7,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'avatarLetter': avatarLetter,
        'checkedInToday': checkedInToday,
        'weeklyDosesLogged': weeklyDosesLogged,
        'weeklyDosesTarget': weeklyDosesTarget,
      };

  factory CircleMemberModel.fromJson(Map<String, dynamic> json) =>
      CircleMemberModel(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String,
        avatarLetter: json['avatarLetter'] as String,
        checkedInToday: json['checkedInToday'] as bool? ?? false,
        weeklyDosesLogged: json['weeklyDosesLogged'] as int? ?? 0,
        weeklyDosesTarget: json['weeklyDosesTarget'] as int? ?? 7,
      );
}

class CircleModel {
  final String id;
  final String inviteCode;
  final String name;
  final List<CircleMemberModel> members;

  CircleModel({
    required this.id,
    required this.inviteCode,
    required this.name,
    required this.members,
  });

  int get checkedInCount => members.where((m) => m.checkedInToday).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'inviteCode': inviteCode,
        'name': name,
        'members': members.map((m) => m.toJson()).toList(),
      };

  factory CircleModel.fromJson(Map<String, dynamic> json) => CircleModel(
        id: json['id'] as String,
        inviteCode: json['inviteCode'] as String,
        name: json['name'] as String,
        members: (json['members'] as List<dynamic>)
            .map((m) => CircleMemberModel.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}
