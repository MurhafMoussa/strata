import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_storage/strata_storage.dart';

class MockSensitiveStorageInterface extends Mock implements SensitiveStorageInterface {}

void main() {
  late MockSensitiveStorageInterface mockStorage;

  setUp(() {
    mockStorage = MockSensitiveStorageInterface();
  });

  group('StorageEncryptionKeyHelper', () {
    const testKeyName = 'custom_db_key';

    group('generateRandomKey', () {
      test('generates byte array of requested length', () {
        final key256 = StorageEncryptionKeyHelper.generateRandomKey(lengthInBytes: 32);
        expect(key256.length, equals(32));

        final key128 = StorageEncryptionKeyHelper.generateRandomKey(lengthInBytes: 16);
        expect(key128.length, equals(16));
      });
    });

    group('getOrCreateEncryptionKey', () {
      test('returns decoded bytes when key already exists in storage', () async {
        final initialBytes = [10, 20, 30, 40, 50, 60, 70, 80];
        final encodedKey = base64.encode(initialBytes);

        when(() => mockStorage.read(testKeyName))
            .thenAnswer((_) async => right(encodedKey));

        final result = await StorageEncryptionKeyHelper.getOrCreateEncryptionKey(
          storage: mockStorage,
          keyName: testKeyName,
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (l) => fail('Should be Right'),
          (bytes) => expect(bytes, equals(initialBytes)),
        );
        verify(() => mockStorage.read(testKeyName)).called(1);
        verifyNever(() => mockStorage.save(any(), any()));
      });

      test('generates, saves, and returns new key when none exists in storage', () async {
        when(() => mockStorage.read(testKeyName))
            .thenAnswer((_) async => right(null));
        when(() => mockStorage.save(testKeyName, any()))
            .thenAnswer((_) async => right(unit));

        final result = await StorageEncryptionKeyHelper.getOrCreateEncryptionKey(
          storage: mockStorage,
          keyName: testKeyName,
          lengthInBytes: 32,
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (l) => fail('Should be Right'),
          (bytes) => expect(bytes.length, equals(32)),
        );
        verify(() => mockStorage.read(testKeyName)).called(1);
        verify(() => mockStorage.save(testKeyName, any())).called(1);
      });

      test('returns Left(Failure) if reading from storage fails', () async {
        const failure = StorageFailure(message: 'Storage read error');
        when(() => mockStorage.read(testKeyName))
            .thenAnswer((_) async => left(failure));

        final result = await StorageEncryptionKeyHelper.getOrCreateEncryptionKey(
          storage: mockStorage,
          keyName: testKeyName,
        );

        expect(result.isLeft(), isTrue);
        result.fold((f) => expect(f, equals(failure)), (r) => fail('Should be Left'));
      });

      test('returns Left(StorageFailure) if existing key is invalid base64', () async {
        when(() => mockStorage.read(testKeyName))
            .thenAnswer((_) async => right('invalid!!!base64'));

        final result = await StorageEncryptionKeyHelper.getOrCreateEncryptionKey(
          storage: mockStorage,
          keyName: testKeyName,
        );

        expect(result.isLeft(), isTrue);
        result.fold((f) => expect(f, isA<StorageFailure>()), (r) => fail('Should be Left'));
      });
    });

    group('rotateEncryptionKey', () {
      test('rotates key, returning old key bytes and new key bytes', () async {
        final oldBytes = [1, 2, 3, 4, 5];
        final oldEncoded = base64.encode(oldBytes);

        when(() => mockStorage.read(testKeyName))
            .thenAnswer((_) async => right(oldEncoded));
        when(() => mockStorage.save(testKeyName, any()))
            .thenAnswer((_) async => right(unit));

        final result = await StorageEncryptionKeyHelper.rotateEncryptionKey(
          storage: mockStorage,
          keyName: testKeyName,
          lengthInBytes: 32,
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (l) => fail('Should be Right'),
          (rotationResult) {
            expect(rotationResult.oldKeyBytes, equals(oldBytes));
            expect(rotationResult.newKeyBytes.length, equals(32));
          },
        );
      });

      test('rotates key when no previous key existed (oldKeyBytes is null)', () async {
        when(() => mockStorage.read(testKeyName))
            .thenAnswer((_) async => right(null));
        when(() => mockStorage.save(testKeyName, any()))
            .thenAnswer((_) async => right(unit));

        final result = await StorageEncryptionKeyHelper.rotateEncryptionKey(
          storage: mockStorage,
          keyName: testKeyName,
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (l) => fail('Should be Right'),
          (rotationResult) {
            expect(rotationResult.oldKeyBytes, isNull);
            expect(rotationResult.newKeyBytes.length, equals(32));
          },
        );
      });
    });
  });
}
