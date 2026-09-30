import 'package:fpdart/fpdart.dart';
import '../typedefs/result_typedefs.dart';

/// Secure key-value storage contract for sensitive data (tokens, keys).
abstract interface class SensitiveStorageInterface {
  /// Reads string value associated with [key].
  ResultFuture<String?> read(String key);

  /// Saves [value] associated with [key].
  ResultFuture<Unit> save(String key, String value);

  /// Deletes value associated with [key].
  ResultFuture<Unit> delete(String key);

  /// Deletes all stored key-value pairs.
  ResultFuture<Unit> deleteAll();

  /// Checks whether [key] exists in storage.
  ResultFuture<bool> containsKey(String key);
}
