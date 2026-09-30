import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_storage/strata_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late FlutterSecureSensitiveStorage sensitiveStorage;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    sensitiveStorage = FlutterSecureSensitiveStorage(secureStorage: mockSecureStorage);
  });

  group('FlutterSecureSensitiveStorage', () {
    const testKey = 'test_key';
    const testValue = 'test_value';

    group('read', () {
      test('returns Right(value) when read succeeds', () async {
        when(() => mockSecureStorage.read(key: testKey))
            .thenAnswer((_) async => testValue);

        final result = await sensitiveStorage.read(testKey);

        expect(result.isRight(), isTrue);
        result.fold((l) => fail('Should be Right'), (r) => expect(r, testValue));
        verify(() => mockSecureStorage.read(key: testKey)).called(1);
      });

      test('returns Left(StorageFailure) when read throws an Exception', () async {
        when(() => mockSecureStorage.read(key: testKey))
            .thenThrow(Exception('Platform error'));

        final result = await sensitiveStorage.read(testKey);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<StorageFailure>());
            expect(failure.message, contains('Failed to read key'));
          },
          (r) => fail('Should be Left'),
        );
      });
    });

    group('save', () {
      test('returns Right(unit) when save succeeds', () async {
        when(() => mockSecureStorage.write(key: testKey, value: testValue))
            .thenAnswer((_) async {});

        final result = await sensitiveStorage.save(testKey, testValue);

        expect(result.isRight(), isTrue);
        verify(() => mockSecureStorage.write(key: testKey, value: testValue)).called(1);
      });

      test('returns Left(StorageFailure) when save throws an Exception', () async {
        when(() => mockSecureStorage.write(key: testKey, value: testValue))
            .thenThrow(Exception('Write error'));

        final result = await sensitiveStorage.save(testKey, testValue);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<StorageFailure>());
            expect(failure.message, contains('Failed to save key'));
          },
          (r) => fail('Should be Left'),
        );
      });
    });

    group('delete', () {
      test('returns Right(unit) when delete succeeds', () async {
        when(() => mockSecureStorage.delete(key: testKey))
            .thenAnswer((_) async {});

        final result = await sensitiveStorage.delete(testKey);

        expect(result.isRight(), isTrue);
        verify(() => mockSecureStorage.delete(key: testKey)).called(1);
      });

      test('returns Left(StorageFailure) when delete throws an Exception', () async {
        when(() => mockSecureStorage.delete(key: testKey))
            .thenThrow(Exception('Delete error'));

        final result = await sensitiveStorage.delete(testKey);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<StorageFailure>()),
          (r) => fail('Should be Left'),
        );
      });
    });

    group('deleteAll', () {
      test('returns Right(unit) when deleteAll succeeds', () async {
        when(() => mockSecureStorage.deleteAll())
            .thenAnswer((_) async {});

        final result = await sensitiveStorage.deleteAll();

        expect(result.isRight(), isTrue);
        verify(() => mockSecureStorage.deleteAll()).called(1);
      });

      test('returns Left(StorageFailure) when deleteAll throws an Exception', () async {
        when(() => mockSecureStorage.deleteAll())
            .thenThrow(Exception('Clear error'));

        final result = await sensitiveStorage.deleteAll();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<StorageFailure>()),
          (r) => fail('Should be Left'),
        );
      });
    });

    group('containsKey', () {
      test('returns Right(true) when key exists', () async {
        when(() => mockSecureStorage.containsKey(key: testKey))
            .thenAnswer((_) async => true);

        final result = await sensitiveStorage.containsKey(testKey);

        expect(result.isRight(), isTrue);
        result.fold((l) => fail('Should be Right'), (r) => expect(r, isTrue));
        verify(() => mockSecureStorage.containsKey(key: testKey)).called(1);
      });

      test('returns Left(StorageFailure) when containsKey throws an Exception', () async {
        when(() => mockSecureStorage.containsKey(key: testKey))
            .thenThrow(Exception('Check error'));

        final result = await sensitiveStorage.containsKey(testKey);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<StorageFailure>()),
          (r) => fail('Should be Left'),
        );
      });
    });
  });
}
