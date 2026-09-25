import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compound.dart';
import '../models/dose_log.dart';
import '../models/daily_check_in.dart';
import '../models/circle_data.dart';
import '../models/user_profile.dart';
import '../../core/constants/compound_directory.dart';

class LocalStorageService {
  static const _kProfileKey = 'omnya_user_profile';
  static const _kCompoundsKey = 'omnya_compounds';
  static const _kDoseLogsKey = 'omnya_dose_logs';
  static const _kCheckInsKey = 'omnya_check_ins';
  static const _kCircleKey = 'omnya_circle';
  static const _kPendingSyncKey = 'omnya_pending_sync';
  static const _kLastSyncTimestampKey = 'omnya_last_sync_timestamp';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  bool get hasPendingSync => _prefs.getBool(_kPendingSyncKey) ?? false;

  Future<void> setPendingSync(bool value) async {
    await _prefs.setBool(_kPendingSyncKey, value);
  }

  DateTime? get lastSyncTimestamp {
    final raw = _prefs.getString(_kLastSyncTimestampKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    await _prefs.setString(_kLastSyncTimestampKey, timestamp.toIso8601String());
  }

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = LocalStorageService(prefs);
    await service._ensureSeeded();
    return service;
  }

  Future<void> _ensureSeeded() async {
    // Seed initial protocol if new install (matching spec page 2 layout)
    if (_prefs.getString(_kCompoundsKey) == null) {
      final now = DateTime.now();
      final defaultCompounds = [
        Compound(
          id: 'reta_01',
          name: 'Retatrutide',
          nickname: 'Dream bod, here we come.',
          category: CompoundCategory.body,
          doseMg: 2.0,
          frequencyDays: 7,
          injectionSite: 'Left thigh',
          vialMg: 10.0,
          bacWaterMl: 2.0,
          dosesLeft: 3,
          costPerDose: 4.10,
          totalMonthlyCost: 16.40,
          startDate: now.subtract(const Duration(days: 21)),
          runoutDate: now.add(const Duration(days: 4)), // Runs out Thursday
        ),
        Compound(
          id: 'ghkcu_01',
          name: 'GHK-Cu',
          nickname: 'Face card will be lethal.',
          category: CompoundCategory.glowAndSkin,
          doseMg: 1.5,
          frequencyDays: 1,
          injectionSite: 'Abdomen',
          vialMg: 50.0,
          bacWaterMl: 3.0,
          dosesLeft: 22,
          costPerDose: 2.50,
          totalMonthlyCost: 75.00,
          startDate: now.subtract(const Duration(days: 28)),
          runoutDate: now.add(const Duration(days: 22)),
        ),
        Compound(
          id: 'klow_01',
          name: 'KLOW',
          nickname: 'Heal, glow, repeat.',
          category: CompoundCategory.glowAndSkin,
          doseMg: 1.0,
          frequencyDays: 1,
          injectionSite: 'Deltoid',
          vialMg: 30.0,
          bacWaterMl: 2.0,
          dosesLeft: 18,
          costPerDose: 3.20,
          totalMonthlyCost: 96.00,
          startDate: now.subtract(const Duration(days: 12)),
          runoutDate: now.add(const Duration(days: 18)),
        ),
      ];

      await saveCompounds(defaultCompounds);

      // Seed default circle
      final defaultCircle = CircleModel(
        id: 'circ_omnya_default',
        inviteCode: 'OMNYA',
        name: 'Sunday Glow Cohort',
        members: [
          CircleMemberModel(
            userId: 'usr_mia',
            displayName: 'Mia',
            avatarLetter: 'M',
            checkedInToday: true,
            weeklyDosesLogged: 7,
          ),
          CircleMemberModel(
            userId: 'usr_you',
            displayName: 'You',
            avatarLetter: 'Y',
            checkedInToday: true,
            weeklyDosesLogged: 6,
          ),
          CircleMemberModel(
            userId: 'usr_jess',
            displayName: 'Jess',
            avatarLetter: 'J',
            checkedInToday: true,
            weeklyDosesLogged: 5,
          ),
          CircleMemberModel(
            userId: 'usr_sarah',
            displayName: 'Sarah',
            avatarLetter: 'S',
            checkedInToday: true,
            weeklyDosesLogged: 6,
          ),
          CircleMemberModel(
            userId: 'usr_ava',
            displayName: 'Ava',
            avatarLetter: 'A',
            checkedInToday: false,
            weeklyDosesLogged: 4,
          ),
        ],
      );
      await saveCircle(defaultCircle);

      // Seed default check-in and dose logs
      final defaultDoseLogs = [
        DoseLog(
          id: 'log_01',
          compoundId: 'reta_01',
          compoundName: 'Retatrutide',
          doseMg: 2.0,
          injectionSite: 'Left thigh',
          timestamp: now.subtract(const Duration(days: 7)),
        ),
      ];
      await saveDoseLogs(defaultDoseLogs);

      final defaultCheckIns = [
        DailyCheckIn(
          id: 'chk_01',
          date: now,
          energyLevel: 4,
          appetiteLevel: 2,
          cyclePhase: CyclePhase.luteal,
          weightLbs: 141.2,
          notes: "Feeling energized, mild appetite suppression.",
        ),
      ];
      await saveCheckIns(defaultCheckIns);
      // Notice: Profile is intentionally NOT auto-seeded so new users
      // naturally experience the 6-step onboarding quiz first.
    }
  }

  // Compounds
  Future<void> saveCompounds(List<Compound> compounds) async {
    final list = compounds.map((c) => c.toJson()).toList();
    await _prefs.setString(_kCompoundsKey, jsonEncode(list));
  }

  List<Compound> getCompounds() {
    final raw = _prefs.getString(_kCompoundsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => Compound.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // Dose Logs
  Future<void> saveDoseLogs(List<DoseLog> logs) async {
    final list = logs.map((l) => l.toJson()).toList();
    await _prefs.setString(_kDoseLogsKey, jsonEncode(list));
  }

  List<DoseLog> getDoseLogs() {
    final raw = _prefs.getString(_kDoseLogsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => DoseLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // Check-ins
  Future<void> saveCheckIns(List<DailyCheckIn> checkIns) async {
    final list = checkIns.map((c) => c.toJson()).toList();
    await _prefs.setString(_kCheckInsKey, jsonEncode(list));
  }

  List<DailyCheckIn> getCheckIns() {
    final raw = _prefs.getString(_kCheckInsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => DailyCheckIn.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // Circle
  Future<void> saveCircle(CircleModel circle) async {
    await _prefs.setString(_kCircleKey, jsonEncode(circle.toJson()));
  }

  CircleModel? getCircle() {
    final raw = _prefs.getString(_kCircleKey);
    if (raw == null) return null;
    try {
      return CircleModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // Profile
  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_kProfileKey, jsonEncode(profile.toJson()));
  }

  UserProfile? getProfile() {
    final raw = _prefs.getString(_kProfileKey);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearProfile() async {
    await _prefs.remove(_kProfileKey);
  }
}
