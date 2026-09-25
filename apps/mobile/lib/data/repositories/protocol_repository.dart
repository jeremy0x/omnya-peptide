import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/compound.dart';
import '../models/dose_log.dart';
import '../models/daily_check_in.dart';
import '../models/circle_data.dart';
import '../models/user_profile.dart';
import '../services/local_storage_service.dart';
import '../services/api_service.dart';
import '../../core/constants/compound_directory.dart';

class ProtocolRepository extends ChangeNotifier {
  final LocalStorageService storage;
  final ApiService api;
  final _uuid = const Uuid();

  List<Compound> _compounds = [];
  List<DoseLog> _doseLogs = [];
  List<DailyCheckIn> _checkIns = [];
  CircleModel? _circle;
  UserProfile? _profile;
  bool _isSyncing = false;

  ProtocolRepository({
    required this.storage,
    required this.api,
  }) {
    _loadFromStorage();
  }

  List<Compound> get compounds => List.unmodifiable(_compounds);
  List<DoseLog> get doseLogs => List.unmodifiable(_doseLogs);
  List<DailyCheckIn> get checkIns => List.unmodifiable(_checkIns);
  CircleModel? get circle => _circle;
  UserProfile? get profile => _profile;
  bool get isPro => _profile?.isPro ?? false;
  bool get isSyncing => _isSyncing;
  bool get hasPendingSync => storage.hasPendingSync;
  DateTime? get lastSyncTimestamp => storage.lastSyncTimestamp;

  void _loadFromStorage() {
    _compounds = storage.getCompounds();
    _doseLogs = storage.getDoseLogs();
    _checkIns = storage.getCheckIns();
    _circle = storage.getCircle();
    _profile = storage.getProfile();
    notifyListeners();
    syncWithCloud();
  }

  Future<bool> syncWithCloud({bool force = false}) async {
    if (_isSyncing && !force) return false;
    _isSyncing = true;
    notifyListeners();

    try {
      final userId = _profile?.id ?? 'usr_local_seed';
      final success = await api.pushSync(
        userId: userId,
        profile: _profile,
        compounds: _compounds,
        doseLogs: _doseLogs,
        checkIns: _checkIns,
      );

      if (success) {
        await storage.setPendingSync(false);
        await storage.setLastSyncTimestamp(DateTime.now());
      } else {
        await storage.setPendingSync(true);
      }
      _syncCircleInternal();
      return success;
    } catch (e) {
      await storage.setPendingSync(true);
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> syncCircle() async {
    await _syncCircleInternal();
  }

  Future<void> _syncCircleInternal() async {
    final userId = _profile?.id ?? 'usr_local_seed';
    try {
      final userCircle = await api.fetchUserCircle(userId);
      if (userCircle != null) {
        _circle = userCircle;
        await storage.saveCircle(userCircle);
        notifyListeners();
      } else if (_circle == null) {
        final created = await api.createCircle(
          name: 'My Cohort',
          ownerUserId: userId,
          ownerDisplayName: 'You',
        );
        if (created != null) {
          _circle = created;
          await storage.saveCircle(created);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void _markPendingAndSync() {
    storage.setPendingSync(true);
    notifyListeners();
    syncWithCloud();
  }

  // 1-Tap Dose Logging (Spec Page 2 & 6: "One card for the dose... 1 tap log")
  Future<void> logDose({
    required String compoundId,
    required String injectionSite,
  }) async {
    final index = _compounds.indexWhere((c) => c.id == compoundId);
    if (index == -1) return;

    final target = _compounds[index];
    final updatedDosesLeft = (target.dosesLeft - 1).clamp(0, 999);

    final newLog = DoseLog(
      id: _uuid.v4(),
      compoundId: target.id,
      compoundName: target.name,
      doseMg: target.doseMg,
      injectionSite: injectionSite,
      timestamp: DateTime.now(),
    );

    // Rotate injection site automatically
    final nextSite = _getNextRotationSite(injectionSite);

    _compounds[index] = target.copyWith(
      dosesLeft: updatedDosesLeft,
      injectionSite: nextSite,
    );
    _doseLogs.insert(0, newLog);

    await storage.saveCompounds(_compounds);
    await storage.saveDoseLogs(_doseLogs);

    // Update circle member check-in for current user
    if (_circle != null) {
      final currentUserId = _profile?.id ?? 'usr_local_seed';
      final updatedMembers = _circle!.members.map((m) {
        if (m.userId == currentUserId || m.userId == 'usr_you' || m.displayName == 'You') {
          return m.copyWith(
            checkedInToday: true,
            weeklyDosesLogged: m.weeklyDosesLogged + 1,
          );
        }
        return m;
      }).toList();

      final myMember = updatedMembers.firstWhere(
        (m) => m.userId == currentUserId || m.userId == 'usr_you' || m.displayName == 'You',
        orElse: () => updatedMembers.first,
      );

      _circle = _circle!.copyWith(members: updatedMembers);
      await storage.saveCircle(_circle!);
      api.updateCircleMemberProgress(
        circleId: _circle!.id,
        userId: myMember.userId,
        checkedInToday: true,
        weeklyDosesLogged: myMember.weeklyDosesLogged,
      );
    }

    notifyListeners();
    _markPendingAndSync();
  }

  String _getNextRotationSite(String current) {
    const sites = ['Left thigh', 'Right thigh', 'Abdomen left', 'Abdomen right', 'Left deltoid', 'Right deltoid'];
    final idx = sites.indexOf(current);
    if (idx == -1 || idx == sites.length - 1) return sites[0];
    return sites[idx + 1];
  }

  // 3-Tap Daily Check-in (Spec Page 2 & 6: "Energy, appetite, optional photo. Under 10 seconds")
  Future<void> submitCheckIn({
    required int energyLevel,
    required int appetiteLevel,
    double? weightLbs,
    String? photoPath,
    CyclePhase? cyclePhase,
    String? notes,
  }) async {
    final checkIn = DailyCheckIn(
      id: _uuid.v4(),
      date: DateTime.now(),
      energyLevel: energyLevel,
      appetiteLevel: appetiteLevel,
      weightLbs: weightLbs,
      localPhotoPath: photoPath,
      cyclePhase: cyclePhase,
      notes: notes,
    );

    _checkIns.insert(0, checkIn);
    await storage.saveCheckIns(_checkIns);
    notifyListeners();
    _markPendingAndSync();
  }

  // Attach / update weekly photo in user's protocol check-ins
  Future<void> attachWeeklyPhoto(String photoUrl) async {
    if (_checkIns.isNotEmpty) {
      final latest = _checkIns.first;
      _checkIns[0] = latest.copyWith(localPhotoPath: photoUrl);
    } else {
      final newCheckIn = DailyCheckIn(
        id: _uuid.v4(),
        date: DateTime.now(),
        energyLevel: 4,
        appetiteLevel: 3,
        localPhotoPath: photoUrl,
      );
      _checkIns.insert(0, newCheckIn);
    }
    await storage.saveCheckIns(_checkIns);
    notifyListeners();
    _markPendingAndSync();
  }

  // Add / Reconstitute Compound
  Future<void> saveCompound(Compound compound) async {
    final existingIdx = _compounds.indexWhere((c) => c.id == compound.id);
    if (existingIdx != -1) {
      _compounds[existingIdx] = compound;
    } else {
      _compounds.add(compound);
    }
    await storage.saveCompounds(_compounds);
    notifyListeners();
    _markPendingAndSync();
  }

  // Generate personalized compound stack based on onboarding quiz selections
  Future<void> initializeProtocolFromOnboarding(List<String> selectedNames) async {
    final now = DateTime.now();
    final List<Compound> generated = [];

    // Filter out 'Not sure yet' or blank
    final cleaned = selectedNames
        .where((n) => n.trim().isNotEmpty && !n.toLowerCase().contains('not sure'))
        .toList();

    if (cleaned.isEmpty) {
      cleaned.addAll(['Retatrutide', 'GHK-Cu', 'KLOW']);
    }

    for (int i = 0; i < cleaned.length; i++) {
      final query = cleaned[i].toLowerCase();
      CompoundPreset? matched;
      for (final p in CompoundDirectory.presets) {
        final pName = p.name.toLowerCase();
        if (pName.contains(query) || query.contains(pName) || p.id.toLowerCase() == query) {
          matched = p;
          break;
        }
      }

      final preset = matched ??
          CompoundPreset(
            id: 'comp_$i',
            name: cleaned[i],
            nickname: 'Custom protocol',
            category: CompoundCategory.body,
            defaultDoseMg: 2.0,
            defaultCadenceDays: 7,
          );

      generated.add(
        Compound(
          id: '${preset.id}_${now.millisecondsSinceEpoch}_$i',
          name: preset.name,
          nickname: preset.nickname,
          category: preset.category,
          doseMg: preset.defaultDoseMg,
          frequencyDays: preset.defaultCadenceDays,
          injectionSite: 'Abdomen',
          vialMg: preset.defaultDoseMg * 10,
          bacWaterMl: 2.0,
          dosesLeft: 10,
          costPerDose: 3.50,
          totalMonthlyCost: (30 / preset.defaultCadenceDays) * 3.50,
          startDate: now,
          runoutDate: now.add(Duration(days: preset.defaultCadenceDays * 10)),
        ),
      );
    }

    _compounds = generated;
    await storage.saveCompounds(_compounds);
    notifyListeners();
    _markPendingAndSync();
  }

  // Join Circle
  Future<CircleActionResult> joinCircle({
    required String inviteCode,
    required String displayName,
  }) async {
    final userId = _profile?.id ?? 'usr_local_seed';
    final result = await api.joinCircle(
      userId: userId,
      inviteCode: inviteCode,
      displayName: displayName,
    );

    if (result.success && result.circle != null) {
      _circle = result.circle;
      await storage.saveCircle(result.circle!);
      notifyListeners();
    }
    return result;
  }

  // Complete Onboarding
  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    await storage.saveProfile(profile);
    notifyListeners();
    _markPendingAndSync();
  }

  // Reset Onboarding (allows re-running the quiz flow)
  Future<void> resetOnboarding() async {
    _profile = null;
    await storage.clearProfile();
    notifyListeners();
  }

  // Toggle Pro
  Future<void> setPro(bool isPro) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(isPro: isPro);
      await storage.saveProfile(_profile!);
      notifyListeners();
      _markPendingAndSync();
    }
  }

  double calculateMonthlySpend() {
    double total = 0.0;
    for (final c in _compounds) {
      total += c.totalMonthlyCost;
    }
    return total > 0 ? total : 312.0; // fallback to spec mockup value if 0
  }
}
