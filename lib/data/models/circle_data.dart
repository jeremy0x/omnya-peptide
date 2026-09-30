import 'package:flutter/widgets.dart';

/// One person in a circle. Circles only ever see consistency, never weights or notes.
class CircleMember {
  final String userId;
  final String displayName;
  final DateTime? lastLoggedAt;
  final DateTime? weekStart;
  final int dosesThisWeek;
  final int dosesPlannedThisWeek;

  const CircleMember({
    required this.userId,
    required this.displayName,
    this.lastLoggedAt,
    this.weekStart,
    this.dosesThisWeek = 0,
    this.dosesPlannedThisWeek = 0,
  });

  String get initial => displayName.isEmpty ? '?' : displayName.characters.first.toUpperCase();

  bool loggedOn(DateTime day) {
    final t = lastLoggedAt?.toLocal();
    return t != null && t.year == day.year && t.month == day.month && t.day == day.day;
  }

  /// Numbers from a previous week read as zero rather than as stale progress.
  int dosesInWeek(DateTime currentWeekStart) =>
      weekStart != null && !weekStart!.isBefore(currentWeekStart) ? dosesThisWeek : 0;

  int plannedInWeek(DateTime currentWeekStart) =>
      weekStart != null && !weekStart!.isBefore(currentWeekStart) ? dosesPlannedThisWeek : 0;

  factory CircleMember.fromRow(Map<String, dynamic> row) => CircleMember(
    userId: row['user_id'] as String,
    displayName: row['display_name'] as String,
    lastLoggedAt: _date(row['last_logged_at']),
    weekStart: _date(row['week_start']),
    dosesThisWeek: row['doses_this_week'] as int? ?? 0,
    dosesPlannedThisWeek: row['doses_planned_this_week'] as int? ?? 0,
  );

  Map<String, dynamic> toRow() => {
    'user_id': userId,
    'display_name': displayName,
    'last_logged_at': lastLoggedAt?.toUtc().toIso8601String(),
    'week_start': weekStart == null ? null : _day(weekStart!),
    'doses_this_week': dosesThisWeek,
    'doses_planned_this_week': dosesPlannedThisWeek,
  };
}

/// A circle's code doubles as its id, so sharing the code is all it takes to invite.
class Circle {
  final String code;
  final String name;
  final String ownerId;
  final List<CircleMember> members;
  final int maxMembers;

  const Circle({
    required this.code,
    required this.name,
    required this.ownerId,
    required this.members,
    this.maxMembers = 5,
  });

  int get spotsLeft => (maxMembers - members.length).clamp(0, maxMembers);

  /// Same row shape as Supabase, so the cached copy and the API share one parser.
  factory Circle.fromRow(Map<String, dynamic> row) => Circle(
    code: row['id'] as String,
    name: row['name'] as String,
    ownerId: row['owner_id'] as String,
    maxMembers: row['max_members'] as int? ?? 5,
    members: [
      for (final m in (row['circle_members'] as List? ?? const [])) CircleMember.fromRow(m as Map<String, dynamic>),
    ],
  );

  Map<String, dynamic> toRow() => {
    'id': code,
    'name': name,
    'owner_id': ownerId,
    'max_members': maxMembers,
    'circle_members': [for (final m in members) m.toRow()],
  };
}

DateTime? _date(Object? value) => value == null ? null : DateTime.parse(value as String);

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
