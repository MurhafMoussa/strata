import 'dart:convert';
import 'dart:math';
import 'package:fpdart/fpdart.dart';
import 'package:strata_core/strata_core.dart';

/// Container for encryption key rotation results.
class const StorageKeyRotationResult({
  required final List<int>? oldKeyBytes,
  required final List<int> newKeyBytes,
});

/// Helper utilities for encryption key management and rotation in [SensitiveStorageInterface].
class StorageEncryptionKeyHelper {
  /// Default key name in sensitive storage.
  static const String defaultKeyName = 'db_encryption_key';

  /// Generates cryptographically secure random bytes of length [lengthInBytes].
  static List<int> generateRandomKey({int lengthInBytes = 32}) {
    final random = Random.secure();
    return List<int>.generate(lengthInBytes, (_) => random.nextInt(256));
  }

  /// Fetches existing encryption key from [storage] or creates and saves a new key.
  static ResultFuture<List<int>> getOrCreateEncryptionKey({
    required SensitiveStorageInterface storage,
    String keyName = defaultKeyName,
    int lengthInBytes = 32,
  }) async {
    final readResult = await storage.read(keyName);

    return readResult.fold(
      left,
      (existingValue) async {
        if (existingValue != null && existingValue.isNotEmpty) {
          try {
            final bytes = base64.decode(existingValue);
            return right(bytes);
          } catch (e, s) {
            return left(
              StorageFailure(
                message: 'Failed to decode stored encryption key "$keyName": $e',
                originalException: e,
                stackTrace: s,
              ),
            );
          }
        }

        final newBytes = generateRandomKey(lengthInBytes: lengthInBytes);
        final base64Key = base64.encode(newBytes);

        final saveResult = await storage.save(keyName, base64Key);
        return saveResult.fold(
          left,
          (_) => right(newBytes),
        );
      },
    );
  }

  /// Rotates the encryption key in [storage] under [keyName].
  static ResultFuture<StorageKeyRotationResult> rotateEncryptionKey({
    required SensitiveStorageInterface storage,
    String keyName = defaultKeyName,
    int lengthInBytes = 32,
  }) async {
    final readResult = await storage.read(keyName);

    return readResult.fold(
      left,
      (existingValue) async {
        List<int>? oldKeyBytes;
        if (existingValue != null && existingValue.isNotEmpty) {
          try {
            oldKeyBytes = base64.decode(existingValue);
          } catch (e, s) {
            return left(
              StorageFailure(
                message: 'Failed to decode old encryption key during rotation: $e',
                originalException: e,
                stackTrace: s,
              ),
            );
          }
        }

        final newBytes = generateRandomKey(lengthInBytes: lengthInBytes);
        final base64Key = base64.encode(newBytes);

        final saveResult = await storage.save(keyName, base64Key);
        return saveResult.fold(
          left,
          (_) => right(
            StorageKeyRotationResult(
              oldKeyBytes: oldKeyBytes,
              newKeyBytes: newBytes,
            ),
          ),
        );
      },
    );
  }
}
