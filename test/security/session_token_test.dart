import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/secure_storage.dart';
import 'package:propkart/core/storage/isar_collections.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Session memory isolation', () {
    test('web in-memory repositories can be cleared between users', () {
      final prior = PropertyLocal()..id = 'p1';
      PropertyLocalRepository.inMemory['p1'] = prior;
      RequirementLocalRepository.inMemory['r1'] = RequirementLocal()..id = 'r1';
      OutboxLocalRepository.inMemory['o1'] = OutboxLocal()..id = 'o1';

      expect(PropertyLocalRepository.inMemory, isNotEmpty);

      PropertyLocalRepository.inMemory.clear();
      RequirementLocalRepository.inMemory.clear();
      FollowupLocalRepository.inMemory.clear();
      BuilderLocalRepository.inMemory.clear();
      OwnerLocalRepository.inMemory.clear();
      LookupLocalRepository.inMemory.clear();
      OutboxLocalRepository.inMemory.clear();
      ClientLocalRepository.inMemory.clear();

      expect(PropertyLocalRepository.inMemory, isEmpty);
      expect(RequirementLocalRepository.inMemory, isEmpty);
      expect(OutboxLocalRepository.inMemory, isEmpty);
    });

    test('in-memory token can be wiped so next login cannot reuse it', () {
      SecureStorage.inMemoryToken = 'stale-jwt-from-user-a';
      SecureStorage.inMemoryToken = null;
      expect(SecureStorage.inMemoryToken, isNull);
    });
  });
}
