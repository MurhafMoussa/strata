import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_network/strata_network.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('DefaultTokenManager Tests', () {
    late MockSensitiveStorage mockStorage;
    late MockCookieJar mockCookieJar;
    setUp(() {
      mockStorage = MockSensitiveStorage();
      mockCookieJar = MockCookieJar();
    });

    test(
      'getters return set tokens in memory when secureStorageEnabled is false',
      () async {
        final manager = DefaultTokenManager(
          secureStorageEnabled: false,
          sensitiveStorage: mockStorage,
          cookieJar: mockCookieJar,
        );
        await manager.setTokens(
          accessToken: 'acc_123',
          refreshToken: 'ref_456',
        );

        expect(await manager.accessToken, equals('acc_123'));
        expect(await manager.refreshToken, equals('ref_456'));
      },
    );

    test('persists and retrieves tokens via SensitiveStorageInterface when secureStorageEnabled is true', () async {
      when(() => mockStorage.save('accessToken', 'acc_123'))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockStorage.save('refreshToken', 'ref_456'))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockStorage.read('accessToken'))
          .thenAnswer((_) async => const Right('acc_123'));
      when(() => mockStorage.read('refreshToken'))
          .thenAnswer((_) async => const Right('ref_456'));

      final manager = DefaultTokenManager(
        sensitiveStorage: mockStorage,
        cookieJar: mockCookieJar,
        secureStorageEnabled: true,
      );

      await manager.setTokens(accessToken: 'acc_123', refreshToken: 'ref_456');

      verify(() => mockStorage.save('accessToken', 'acc_123')).called(1);
      verify(() => mockStorage.save('refreshToken', 'ref_456')).called(1);

      expect(await manager.accessToken, equals('acc_123'));
      expect(await manager.refreshToken, equals('ref_456'));
    });

    test('clearTokens removes tokens in memory and storage', () async {
      when(() => mockStorage.delete('accessToken'))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockStorage.delete('refreshToken'))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockStorage.read('accessToken'))
          .thenAnswer((_) async => const Right(null));
      when(() => mockStorage.read('refreshToken'))
          .thenAnswer((_) async => const Right(null));
      when(() => mockCookieJar.deleteAll()).thenAnswer((_) async {});

      final manager = DefaultTokenManager(
        sensitiveStorage: mockStorage,
        cookieJar: mockCookieJar,
        secureStorageEnabled: true,
      );

      await manager.clearTokens();

      verify(() => mockStorage.delete('accessToken')).called(1);
      verify(() => mockStorage.delete('refreshToken')).called(1);
      verify(() => mockCookieJar.deleteAll()).called(1);
      expect(await manager.accessToken, equals(''));
      expect(await manager.refreshToken, equals(''));
    });

    test('notifyUnauthenticated emits event on unauthenticatedStream', () async {
      final manager = DefaultTokenManager();
      expect(manager.unauthenticatedStream, emits(null));
      manager.notifyUnauthenticated();
    });

    test('dispose closes unauthenticatedStream controller', () async {
      final manager = DefaultTokenManager();
      await manager.dispose();
      manager.notifyUnauthenticated(); // Should not throw even after closed
    });

    test('getters return cached memory value if present when secureStorageEnabled is true', () async {
      when(() => mockStorage.save(any(), any()))
          .thenAnswer((_) async => const Right(unit));

      final manager = DefaultTokenManager(
        sensitiveStorage: mockStorage,
        secureStorageEnabled: true,
      );
      await manager.setTokens(accessToken: 'cached_acc', refreshToken: 'cached_ref');

      expect(await manager.accessToken, equals('cached_acc'));
      expect(await manager.refreshToken, equals('cached_ref'));
      verifyNever(() => mockStorage.read(any()));
    });

    test('getters return empty string on Left(failure) or Right(null) from storage', () async {
      when(() => mockStorage.read('accessToken'))
          .thenAnswer((_) async => const Left(UnknownFailure(message: 'Storage error')));
      when(() => mockStorage.read('refreshToken'))
          .thenAnswer((_) async => const Right(null));

      final manager = DefaultTokenManager(
        sensitiveStorage: mockStorage,
        secureStorageEnabled: true,
      );

      expect(await manager.accessToken, equals(''));
      expect(await manager.refreshToken, equals(''));
    });

    test('setTokens does not save empty/null tokens to storage when secureStorageEnabled is true', () async {
      final manager = DefaultTokenManager(
        sensitiveStorage: mockStorage,
        secureStorageEnabled: true,
      );

      await manager.setTokens(accessToken: '', refreshToken: null);
      verifyNever(() => mockStorage.save(any(), any()));
    });
  });
}
