# strata_storage

Infrastructure adapters, secure sensitive key-value storage (`FlutterSecureSensitiveStorage`), encryption key generation & rotation utilities, and database setup helpers for the Strata framework.

## Overview

`strata_storage` provides secure persistence infrastructure for mobile applications. It implements the pure Dart `SensitiveStorageInterface` from `strata_core` using platform-native encrypted storage (`FlutterSecureStorage`) and offers helper utilities for database key rotation and directory resolution.

## Architectural Rules & Boundaries

- **Sub-package Isolation**: Depends on `strata_core`, `flutter`, `flutter_secure_storage`, `path_provider`, `get_it`, and `fpdart`.
- **UI & State Decoupling**: Does NOT depend on `flutter_bloc`, `go_router`, `dio`, or any UI widgets.
- **Database Engine Neutrality**: Does NOT wrap or restrict native database engines (Drift, Hive, Isar) behind generic key-value CRUD abstractions. Feature repositories interact directly with native database engines injected via constructors, while storing encryption keys in `SensitiveStorageInterface`.

## Key Components

### 1. `FlutterSecureSensitiveStorage`
Concrete implementation of `SensitiveStorageInterface` backed by `FlutterSecureStorage` using functional `ResultFuture<T>` error handling:

```dart
import 'package:strata_storage/strata_storage.dart';

final storage = FlutterSecureSensitiveStorage();

// Save token
await storage.save('accessToken', 'jwt_token_123');

// Read token
final tokenResult = await storage.read('accessToken');
tokenResult.fold(
  (failure) => print('Failed to read: ${failure.message}'),
  (token) => print('Read token: $token'),
);

// Delete token
await storage.delete('accessToken');
```

### 2. `StorageEncryptionKeyHelper`
Generates, retrieves, and rotates 256-bit encryption keys for encrypted local databases (e.g., Hive, Drift, Realm, SQLCipher):

```dart
import 'package:strata_storage/strata_storage.dart';

final keyHelper = StorageEncryptionKeyHelper(storage);

// Get existing key or generate a new cryptographically secure key
final keyResult = await keyHelper.getOrCreateEncryptionKey('db_key');

keyResult.fold(
  (failure) => print('Key creation failed: ${failure.message}'),
  (bytes) => print('Encryption key ready (32 bytes)'),
);

// Rotate encryption key
await keyHelper.rotateEncryptionKey(
  keyName: 'db_key',
  reEncryptDatabase: (oldKey, newKey) async {
    // Re-encrypt native database with new key
  },
);
```

### 3. `StorageDirectoryHelper`
Resolves cross-platform storage paths for native database engines:

```dart
import 'package:strata_storage/strata_storage.dart';

// Get documents directory path for native database files
final path = await StorageDirectoryHelper.getDatabaseDirectoryPath();
```

### 4. Dependency Injection (`StrataStorageDiExtension`)
Registers `SensitiveStorageInterface` on `GetIt`:

```dart
import 'package:get_it/get_it.dart';
import 'package:strata_storage/strata_storage.dart';

final getIt = GetIt.instance;

getIt.registerStrataStorage();
```

## Running Tests & Audits

Run static analysis and tests inside the `strata_storage` directory:

```bash
cd strata_storage
dart analyze
dart test
```
