import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:strata_core/strata_core.dart';

/// Implementation of [SensitiveStorageInterface] backed by [FlutterSecureStorage].
class const FlutterSecureSensitiveStorage({
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(),
}) implements SensitiveStorageInterface {

  @override
  ResultFuture<String?> read(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      return right(value);
    } catch (e, stackTrace) {
      return left(
        StorageFailure(
          message: 'Failed to read key "$key": $e',
          originalException: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  ResultFuture<Unit> save(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      return right(unit);
    } catch (e, stackTrace) {
      return left(
        StorageFailure(
          message: 'Failed to save key "$key": $e',
          originalException: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  ResultFuture<Unit> delete(String key) async {
    try {
      await _secureStorage.delete(key: key);
      return right(unit);
    } catch (e, stackTrace) {
      return left(
        StorageFailure(
          message: 'Failed to delete key "$key": $e',
          originalException: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  ResultFuture<Unit> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
      return right(unit);
    } catch (e, stackTrace) {
      return left(
        StorageFailure(
          message: 'Failed to delete all keys: $e',
          originalException: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  ResultFuture<bool> containsKey(String key) async {
    try {
      final exists = await _secureStorage.containsKey(key: key);
      return right(exists);
    } catch (e, stackTrace) {
      return left(
        StorageFailure(
          message: 'Failed to check existence of key "$key": $e',
          originalException: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
