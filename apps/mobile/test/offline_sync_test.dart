import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peptide_app/data/services/local_storage_service.dart';
import 'package:peptide_app/data/services/api_service.dart';
import 'package:peptide_app/data/repositories/protocol_repository.dart';
import 'package:peptide_app/data/models/user_profile.dart';
import 'package:peptide_app/data/models/compound.dart';
import 'package:peptide_app/data/models/dose_log.dart';
import 'package:peptide_app/data/models/daily_check_in.dart';
import 'package:peptide_app/data/models/circle_data.dart';

class MockApiService extends ApiService {
  bool shouldSucceed = true;
  int pushSyncCallCount = 0;
  UserProfile? lastSyncedProfile;

  @override
  Future<bool> pushSync({
    required String userId,
    UserProfile? profile,
    List<Compound>? compounds,
    List<DoseLog>? doseLogs,
    List<DailyCheckIn>? checkIns,
  }) async {
    pushSyncCallCount++;
    lastSyncedProfile = profile;
    return shouldSucceed;
  }

  @override
  Future<CircleModel?> fetchUserCircle(String userId) async => null;

  @override
  Future<CircleModel?> createCircle({
    required String name,
    required String ownerUserId,
    required String ownerDisplayName,
    String? preferredInviteCode,
  }) async => null;

  @override
  Future<bool> updateCircleMemberProgress({
    required String circleId,
    required String userId,
    required bool checkedInToday,
    required int weeklyDosesLogged,
  }) async => shouldSucceed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Sync & Dirty Tracking Tests', () {
    late LocalStorageService storage;
    late MockApiService mockApi;
    late ProtocolRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await LocalStorageService.init();
      mockApi = MockApiService();
      repo = ProtocolRepository(storage: storage, api: mockApi);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('LocalStorageService tracks hasPendingSync and lastSyncTimestamp', () async {
      final freshStorage = LocalStorageService(await SharedPreferences.getInstance());
      await freshStorage.setPendingSync(false);
      expect(freshStorage.hasPendingSync, isFalse);

      await freshStorage.setPendingSync(true);
      expect(freshStorage.hasPendingSync, isTrue);

      final now = DateTime(2026, 9, 25, 12, 0, 0);
      await freshStorage.setLastSyncTimestamp(now);
      expect(freshStorage.lastSyncTimestamp, equals(now));

      await freshStorage.setPendingSync(false);
      expect(freshStorage.hasPendingSync, isFalse);
    });

    test('When offline, mutations mark pending sync flag', () async {
      mockApi.shouldSucceed = false; // Simulate offline

      expect(repo.compounds.isNotEmpty, isTrue);
      final firstComp = repo.compounds.first;

      await repo.logDose(
        compoundId: firstComp.id,
        injectionSite: 'Left thigh',
      );

      // Should be saved locally despite push failure
      expect(repo.doseLogs.isNotEmpty, isTrue);
      expect(repo.hasPendingSync, isTrue);
      expect(storage.hasPendingSync, isTrue);
    });

    test('When online, sync clears pending flag and updates timestamp', () async {
      mockApi.shouldSucceed = false;
      await repo.submitCheckIn(
        energyLevel: 5,
        appetiteLevel: 3,
        weightLbs: 135.0,
      );
      expect(repo.hasPendingSync, isTrue);

      // Connectivity restored
      mockApi.shouldSucceed = true;
      final synced = await repo.syncWithCloud(force: true);

      expect(synced, isTrue);
      expect(repo.hasPendingSync, isFalse);
      expect(repo.lastSyncTimestamp, isNotNull);
    });

    test('initializeProtocolFromOnboarding seeds matching compounds', () async {
      await repo.initializeProtocolFromOnboarding(['Retatrutide', 'GHK-Cu']);

      expect(repo.compounds.length, equals(2));
      expect(repo.compounds.any((c) => c.name.contains('Retatrutide')), isTrue);
      expect(repo.compounds.any((c) => c.name.contains('GHK-Cu')), isTrue);
    });

    test('initializeProtocolFromOnboarding falls back gracefully for unknown/empty', () async {
      await repo.initializeProtocolFromOnboarding(['Not sure yet']);

      // Falls back to starter trio
      expect(repo.compounds.length, equals(3));
      expect(repo.compounds.any((c) => c.name.contains('Retatrutide')), isTrue);
      expect(repo.compounds.any((c) => c.name.contains('GHK-Cu')), isTrue);
      expect(repo.compounds.any((c) => c.name.contains('KLOW')), isTrue);
    });
  });
}
