import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_storage/strata_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late GetIt getIt;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    getIt = GetIt.asNewInstance();
    mockSecureStorage = MockFlutterSecureStorage();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('StrataStorageDiExtension', () {
    test('registers SensitiveStorageInterface with FlutterSecureSensitiveStorage', () {
      getIt.registerStrataStorage();

      expect(getIt.isRegistered<SensitiveStorageInterface>(), isTrue);
      final instance = getIt<SensitiveStorageInterface>();
      expect(instance, isA<FlutterSecureSensitiveStorage>());
    });

    test('does not overwrite existing SensitiveStorageInterface registration', () {
      final existingInstance = FlutterSecureSensitiveStorage(secureStorage: mockSecureStorage);
      getIt.registerSingleton<SensitiveStorageInterface>(existingInstance);

      getIt.registerStrataStorage();

      expect(getIt<SensitiveStorageInterface>(), same(existingInstance));
    });
  });
}
