import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/circle_data.dart';
import '../models/compound.dart';
import '../models/dose_log.dart';
import '../models/daily_check_in.dart';
import '../models/user_profile.dart';

class CircleActionResult {
  final bool success;
  final String? errorMessage;
  final CircleModel? circle;

  CircleActionResult({
    required this.success,
    this.errorMessage,
    this.circle,
  });

  factory CircleActionResult.ok(CircleModel circle) =>
      CircleActionResult(success: true, circle: circle);

  factory CircleActionResult.err(String error) =>
      CircleActionResult(success: false, errorMessage: error);
}

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({
    this.baseUrl = 'http://127.0.0.1:3000',
    http.Client? client,
  }) : _client = client ?? http.Client();

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Register or verify anonymous device with backend / Supabase
  Future<Map<String, dynamic>?> registerAnonymousDevice(String deviceId) async {
    // 1. Direct Supabase
    final client = _supabase;
    if (client != null) {
      try {
        final userId = 'usr_$deviceId';
        final data = await client.from('profiles').upsert({
          'id': userId,
          'device_id': deviceId,
          'updated_at': DateTime.now().toIso8601String(),
        }).select().maybeSingle();
        if (data != null) {
          return {'userId': userId, 'profile': data};
        }
      } catch (e) {
        debugPrint('Supabase register anonymous fallback: $e');
      }
    }

    // 2. HTTP Fallback
    try {
      final res = await _client.post(
        Uri.parse('$baseUrl/api/v1/auth/anonymous'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': deviceId}),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Offline fallback: graceful handling
    }
    return null;
  }

  /// Sync: Push local protocols, doses, check-ins, and profile to Supabase / backend
  Future<bool> pushSync({
    required String userId,
    UserProfile? profile,
    List<Compound>? compounds,
    List<DoseLog>? doseLogs,
    List<DailyCheckIn>? checkIns,
  }) async {
    // 1. Direct Supabase sync
    final client = _supabase;
    if (client != null) {
      try {
        // Upsert user profile
        if (profile != null) {
          await client.from('profiles').upsert({
            'id': profile.id,
            'goals': profile.goals,
            'selected_compounds': profile.selectedCompounds,
            'experience_level': profile.experienceLevel,
            'has_cycle': profile.hasCycle,
            'day_90_goal': profile.day90GoalText,
            'photo_tracking_type': profile.photoTrackingType,
            'sunday_photo_prompt_enabled': profile.sundayPhotoPromptEnabled,
            'is_pro': profile.isPro,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } else {
          await client.from('profiles').upsert({
            'id': userId,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }

        // Push compounds
        if (compounds != null && compounds.isNotEmpty) {
          final compData = compounds.map((c) => {
            'id': c.id,
            'user_id': userId,
            'name': c.name,
            'nickname': c.nickname,
            'category': c.category.name,
            'dose_mg': c.doseMg,
            'frequency_days': c.frequencyDays,
            'injection_site': c.injectionSite,
            'vial_mg': c.vialMg,
            'bac_water_ml': c.bacWaterMl,
            'doses_left': c.dosesLeft,
            'cost_per_dose': c.costPerDose,
            'total_monthly_cost': c.totalMonthlyCost,
            'start_date': c.startDate.toIso8601String(),
            'runout_date': c.runoutDate.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }).toList();
          await client.from('compounds').upsert(compData);
        }

        // Push dose logs
        if (doseLogs != null && doseLogs.isNotEmpty) {
          final doseData = doseLogs.map((d) => {
            'id': d.id,
            'user_id': userId,
            'compound_id': d.compoundId,
            'compound_name': d.compoundName,
            'dose_mg': d.doseMg,
            'injection_site': d.injectionSite,
            'timestamp': d.timestamp.toIso8601String(),
          }).toList();
          await client.from('dose_logs').upsert(doseData);
        }

        // Push check-ins
        if (checkIns != null && checkIns.isNotEmpty) {
          final checkData = checkIns.map((c) => {
            'id': c.id,
            'user_id': userId,
            'date': c.date.toIso8601String(),
            'energy_level': c.energyLevel,
            'appetite_level': c.appetiteLevel,
            'weight_lbs': c.weightLbs,
            'waist_inches': c.waistInches,
            'cycle_phase': _mapCyclePhaseToDb(c.cyclePhase),
            'is_period_day': c.isPeriodDay,
            'photo_url': c.localPhotoPath,
            'notes': c.notes,
          }).toList();
          await client.from('check_ins').upsert(checkData);
        }

        return true;
      } catch (e) {
        debugPrint('Supabase pushSync direct note: $e');
      }
    }

    // 2. HTTP Fallback
    try {
      final payload = <String, dynamic>{
        'userId': userId,
        if (profile != null) 'profile': profile.toJson(),
        if (compounds != null) 'compounds': compounds.map((c) => c.toJson()).toList(),
        if (doseLogs != null) 'doseLogs': doseLogs.map((d) => d.toJson()).toList(),
        if (checkIns != null) 'checkIns': checkIns.map((c) => c.toJson()).toList(),
      };
      final res = await _client.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return res.statusCode == 200;
    } catch (_) {
      // Offline mode
      return false;
    }
  }

  /// Sync: Pull cloud data for user
  Future<Map<String, dynamic>?> pullSync(String userId) async {
    // 1. Direct Supabase
    final client = _supabase;
    if (client != null) {
      try {
        final compounds = await client.from('compounds').select().eq('user_id', userId);
        final doseLogs = await client.from('dose_logs').select().eq('user_id', userId);
        final checkIns = await client.from('check_ins').select().eq('user_id', userId);

        return {
          'compounds': compounds,
          'doseLogs': doseLogs,
          'checkIns': checkIns,
        };
      } catch (e) {
        debugPrint('Supabase pullSync note: $e');
      }
    }

    // 2. HTTP Fallback
    try {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/v1/sync/pull?userId=$userId'),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Offline mode
    }
    return null;
  }

  static String? _mapCyclePhaseToDb(CyclePhase? phase) {
    if (phase == null) return null;
    switch (phase) {
      case CyclePhase.follicular:
        return 'follicular';
      case CyclePhase.ovulation:
        return 'ovulatory';
      case CyclePhase.luteal:
        return 'luteal';
      case CyclePhase.menstruation:
        return 'menstrual';
    }
  }

  /// Generates a clean 5-character alphanumeric invite code (omitting ambiguous characters like 0/O/1/I)
  static String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = math.Random();
    return List.generate(5, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// Circle: Fetch active Circle cohort for user
  Future<CircleModel?> fetchUserCircle(String userId) async {
    // 1. Direct Supabase
    final client = _supabase;
    if (client != null) {
      try {
        final membership = await client
            .from('circle_members')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (membership != null) {
          final circleId = membership['circle_id'] as String;
          final circleData = await client.from('circles').select().eq('id', circleId).maybeSingle();
          if (circleData != null) {
            final members = await client.from('circle_members').select().eq('circle_id', circleId);
            return CircleModel(
              id: circleId,
              inviteCode: circleData['invite_code'] as String,
              name: circleData['name'] as String,
              members: members.map((m) => CircleMemberModel(
                userId: m['user_id'] as String,
                displayName: m['display_name'] as String,
                avatarLetter: (m['avatar_letter'] as String?)?.isNotEmpty == true ? (m['avatar_letter'] as String)[0] : 'U',
                checkedInToday: m['checked_in_today'] as bool? ?? false,
                weeklyDosesLogged: m['weekly_doses_logged'] as int? ?? 0,
                weeklyDosesTarget: m['weekly_doses_target'] as int? ?? 7,
              )).toList(),
            );
          }
        }
      } catch (e) {
        debugPrint('Supabase fetchUserCircle note: $e');
      }
    }

    // 2. HTTP Fallback
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/api/v1/circles/user/$userId'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['circle'] != null) {
          final circle = CircleModel.fromJson(data['circle']);
          final assignedCode = data['userInviteCode'] as String?;
          if (assignedCode != null && assignedCode.isNotEmpty) {
            return circle.copyWith(inviteCode: assignedCode);
          }
          return circle;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch or assign personal invite code specially assigned by backend
  Future<String?> fetchUserInviteCode(String userId) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/api/v1/users/$userId/invite-code'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['inviteCode'] != null) {
          return data['inviteCode'] as String;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Circle: Join an invite-only circle cohort
  Future<CircleActionResult> joinCircle({
    required String userId,
    required String inviteCode,
    required String displayName,
  }) async {
    final cleanCode = inviteCode.trim().toUpperCase();
    if (cleanCode.length != 5) {
      return CircleActionResult.err('Please enter a valid 5-character invite code');
    }

    // 1. Direct Supabase
    final client = _supabase;
    if (client != null) {
      try {
        // Ensure profile exists for foreign key constraint
        await client.from('profiles').upsert({
          'id': userId,
          'updated_at': DateTime.now().toIso8601String(),
        });

        final circle = await client
            .from('circles')
            .select()
            .eq('invite_code', cleanCode)
            .maybeSingle();

        if (circle == null) {
          return CircleActionResult.err('Invite code "$cleanCode" not found');
        }

        final circleId = circle['id'] as String;
        final members = await client.from('circle_members').select().eq('circle_id', circleId);
        final maxMembers = circle['max_members'] as int? ?? 5;

        // Check if already in circle
        final alreadyMember = members.any((m) => m['user_id'] == userId);
        if (!alreadyMember && members.length >= maxMembers) {
          return CircleActionResult.err('This circle is full (maximum 5 members)');
        }

        final letter = displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'U';
        await client.from('circle_members').upsert({
          'id': 'mem_${userId}_$circleId',
          'circle_id': circleId,
          'user_id': userId,
          'display_name': displayName.trim().isEmpty ? 'You' : displayName.trim(),
          'avatar_letter': letter,
          'checked_in_today': true,
          'weekly_doses_logged': 1,
          'weekly_doses_target': 7,
        });

        final updatedMembers = await client.from('circle_members').select().eq('circle_id', circleId);
        final result = CircleModel(
          id: circleId,
          inviteCode: circle['invite_code'] as String,
          name: circle['name'] as String,
          members: updatedMembers.map((m) => CircleMemberModel(
            userId: m['user_id'] as String,
            displayName: m['display_name'] as String,
            avatarLetter: (m['avatar_letter'] as String?)?.isNotEmpty == true ? (m['avatar_letter'] as String)[0] : 'U',
            checkedInToday: m['checked_in_today'] as bool? ?? false,
            weeklyDosesLogged: m['weekly_doses_logged'] as int? ?? 0,
            weeklyDosesTarget: m['weekly_doses_target'] as int? ?? 7,
          )).toList(),
        );
        return CircleActionResult.ok(result);
      } catch (e) {
        debugPrint('Supabase joinCircle direct note: $e');
      }
    }

    // 2. HTTP Fallback
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/api/v1/circles/join'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'inviteCode': cleanCode,
              'displayName': displayName,
            }),
          )
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return CircleActionResult.ok(CircleModel.fromJson(data['circle']));
      } else {
        final data = jsonDecode(res.body);
        final err = data['error'] as String? ?? 'Failed to join circle';
        return CircleActionResult.err(err);
      }
    } catch (_) {
      // Offline mode
      return CircleActionResult.err('Unable to connect. Check internet connection.');
    }
  }

  /// Circle: Create a new circle cohort
  Future<CircleModel?> createCircle({
    required String name,
    required String ownerUserId,
    required String ownerDisplayName,
    String? preferredInviteCode,
  }) async {
    final client = _supabase;
    final code = preferredInviteCode ?? generateInviteCode();
    final circleId = 'cir_${DateTime.now().millisecondsSinceEpoch}';

    if (client != null) {
      try {
        await client.from('profiles').upsert({
          'id': ownerUserId,
          'updated_at': DateTime.now().toIso8601String(),
        });

        final circleData = await client.from('circles').insert({
          'id': circleId,
          'invite_code': code,
          'name': name,
          'max_members': 5,
          'owner_user_id': ownerUserId,
        }).select().maybeSingle();

        if (circleData != null) {
          final letter = ownerDisplayName.trim().isNotEmpty ? ownerDisplayName.trim()[0].toUpperCase() : 'Y';
          await client.from('circle_members').insert({
            'id': 'mem_${ownerUserId}_$circleId',
            'circle_id': circleId,
            'user_id': ownerUserId,
            'display_name': ownerDisplayName,
            'avatar_letter': letter,
            'checked_in_today': true,
            'weekly_doses_logged': 1,
            'weekly_doses_target': 7,
          });

          return CircleModel(
            id: circleId,
            inviteCode: code,
            name: name,
            members: [
              CircleMemberModel(
                userId: ownerUserId,
                displayName: ownerDisplayName,
                avatarLetter: letter,
                checkedInToday: true,
                weeklyDosesLogged: 1,
                weeklyDosesTarget: 7,
              ),
            ],
          );
        }
      } catch (e) {
        debugPrint('Supabase createCircle direct note: $e');
      }
    }

    // 2. HTTP Fallback
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/api/v1/circles'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'ownerUserId': ownerUserId,
              'ownerDisplayName': ownerDisplayName,
              'inviteCode': code,
            }),
          )
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return CircleModel.fromJson(data['circle']);
      }
    } catch (_) {
      // Offline mode
    }
    return null;
  }

  /// Circle: Update member check-in & progress upon dose logging
  Future<bool> updateCircleMemberProgress({
    required String circleId,
    required String userId,
    required bool checkedInToday,
    required int weeklyDosesLogged,
  }) async {
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('circle_members').update({
          'checked_in_today': checkedInToday,
          'weekly_doses_logged': weeklyDosesLogged,
        }).eq('circle_id', circleId).eq('user_id', userId);
        return true;
      } catch (e) {
        debugPrint('Supabase updateCircleMemberProgress note: $e');
      }
    }

    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/api/v1/circles/$circleId/progress'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'checkedInToday': checkedInToday,
              'weeklyDosesLogged': weeklyDosesLogged,
            }),
          )
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Circle: Send cheer to a circle cohort member
  Future<bool> cheerMember({
    required String circleId,
    required String memberUserId,
  }) async {
    try {
      final res = await _client.post(
        Uri.parse('$baseUrl/api/v1/circles/$circleId/cheer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'memberUserId': memberUserId}),
      );
      return res.statusCode == 200;
    } catch (_) {
      // Offline mode
      return false;
    }
  }
}
