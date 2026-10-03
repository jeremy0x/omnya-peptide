import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/circle_data.dart';
import '../models/compound.dart';
import '../models/daily_check_in.dart';
import '../models/dose_log.dart';
import '../models/progress_photo.dart';
import '../models/user_profile.dart';

/// A row deleted on this device that the cloud copy still has to delete.
typedef PendingDelete = ({String table, String id});

/// The device is the source of truth. Everything works offline and syncs later.
class LocalStorageService {
  static const _profileKey = 'omnya_user_profile';
  static const _compoundsKey = 'omnya_compounds';
  static const _doseLogsKey = 'omnya_dose_logs';
  static const _checkInsKey = 'omnya_check_ins';
  static const _photosKey = 'omnya_photos';
  static const _circleKey = 'omnya_circle_v2';
  static const _pendingDeletesKey = 'omnya_pending_deletes';
  static const _pendingSyncKey = 'omnya_pending_sync';
  static const _lastSyncKey = 'omnya_last_sync_timestamp';
  static const _milestonesKey = 'omnya_milestones';
  static const _isProKey = 'omnya_is_pro';

  final SharedPreferences _prefs;

  /// Weekly photos. They never leave the device.
  final Directory photosDir;

  LocalStorageService(this._prefs, this.photosDir);

  /// [photosDir] is for tests; the app uses its documents folder.
  static Future<LocalStorageService> init({Directory? photosDir}) async {
    final prefs = await SharedPreferences.getInstance();
    final photos =
        photosDir ??
        await Directory('${(await getApplicationDocumentsDirectory()).path}/photos').create(recursive: true);
    final storage = LocalStorageService(prefs, photos);
    await storage._removeLegacyDemoData();
    return storage;
  }

  // One unreadable row is skipped instead of dropping the whole list.
  List<T> _list<T>(String key, T Function(Map<String, dynamic>) parse) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    final List<dynamic> items;
    try {
      items = jsonDecode(raw) as List;
    } catch (e) {
      debugPrint('Unreadable $key: $e');
      return [];
    }
    final out = <T>[];
    for (final item in items) {
      try {
        out.add(parse(item as Map<String, dynamic>));
      } catch (e) {
        debugPrint('Skipping unreadable $key row: $e');
      }
    }
    return out;
  }

  Future<void> _put(String key, Iterable<Map<String, dynamic>> rows) =>
      _prefs.setString(key, jsonEncode(rows.toList()));

  List<Compound> getCompounds() => _list(_compoundsKey, Compound.fromJson);
  Future<void> saveCompounds(List<Compound> v) => _put(_compoundsKey, v.map((e) => e.toJson()));

  List<DoseLog> getDoseLogs() => _list(_doseLogsKey, DoseLog.fromJson);
  Future<void> saveDoseLogs(List<DoseLog> v) => _put(_doseLogsKey, v.map((e) => e.toJson()));

  List<DailyCheckIn> getCheckIns() => _list(_checkInsKey, DailyCheckIn.fromJson);
  Future<void> saveCheckIns(List<DailyCheckIn> v) => _put(_checkInsKey, v.map((e) => e.toJson()));

  List<ProgressPhoto> getPhotos() => _list(_photosKey, ProgressPhoto.fromJson);
  Future<void> savePhotos(List<ProgressPhoto> v) => _put(_photosKey, v.map((e) => e.toJson()));

  UserProfile? getProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Unreadable profile: $e');
      return null;
    }
  }

  Future<void> saveProfile(UserProfile p) => _prefs.setString(_profileKey, jsonEncode(p.toJson()));

  /// Last circle seen online, so the tab still shows something offline.
  Circle? getCircle() {
    final raw = _prefs.getString(_circleKey);
    if (raw == null) return null;
    try {
      return Circle.fromRow(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCircle(Circle? c) =>
      c == null ? _prefs.remove(_circleKey) : _prefs.setString(_circleKey, jsonEncode(c.toRow()));

  List<PendingDelete> get pendingDeletes => [
    for (final e in jsonDecode(_prefs.getString(_pendingDeletesKey) ?? '[]') as List)
      (table: (e as Map<String, dynamic>)['table'] as String, id: e['id'] as String),
  ];

  Future<void> _savePendingDeletes(List<PendingDelete> v) => _prefs.setString(
    _pendingDeletesKey,
    jsonEncode([
      for (final d in v) {'table': d.table, 'id': d.id},
    ]),
  );

  Future<void> addPendingDelete(String table, String id) =>
      _savePendingDeletes([...pendingDeletes, (table: table, id: id)]);

  /// Drops only what was sent, so deletes queued during a sync aren't lost.
  Future<void> removePendingDeletes(List<PendingDelete> sent) =>
      _savePendingDeletes(pendingDeletes.where((d) => !sent.contains(d)).toList());

  bool get hasPendingSync => _prefs.getBool(_pendingSyncKey) ?? false;
  Future<void> setPendingSync(bool value) => _prefs.setBool(_pendingSyncKey, value);

  DateTime? get lastSyncTimestamp => DateTime.tryParse(_prefs.getString(_lastSyncKey) ?? '');
  Future<void> setLastSyncTimestamp(DateTime t) => _prefs.setString(_lastSyncKey, t.toIso8601String());

  Set<String> get celebratedMilestones => (_prefs.getStringList(_milestonesKey) ?? const []).toSet();
  Future<void> markMilestone(String name) =>
      _prefs.setStringList(_milestonesKey, {...celebratedMilestones, name}.toList());

  bool getIsPro() => _prefs.getBool(_isProKey) ?? false;
  Future<void> saveIsPro(bool v) => _prefs.setBool(_isProKey, v);

  /// Wipes everything the app stored on this device, photos included.
  Future<void> clearAll() async {
    await _prefs.clear();
    if (await photosDir.exists()) {
      await for (final f in photosDir.list()) {
        await f.delete(recursive: true);
      }
    }
  }

  // ponytail: removes the demo rows builds before October 2026 seeded on first launch
  // (fake compounds, circle members and a weigh-in). Delete once testers have updated.
  Future<void> _removeLegacyDemoData() async {
    const ids = {'reta_01', 'ghkcu_01', 'klow_01', 'log_01', 'chk_01'};
    final compounds = getCompounds();
    if (compounds.any((c) => ids.contains(c.id))) {
      await saveCompounds(compounds.where((c) => !ids.contains(c.id)).toList());
    }
    final logs = getDoseLogs();
    if (logs.any((l) => ids.contains(l.id))) {
      await saveDoseLogs(logs.where((l) => !ids.contains(l.id)).toList());
    }
    final checkIns = getCheckIns();
    if (checkIns.any((c) => ids.contains(c.id))) {
      await saveCheckIns(checkIns.where((c) => !ids.contains(c.id)).toList());
    }
    await _prefs.remove('omnya_circle');
  }
}
