# strata_core

The foundational, zero-dependency pure Dart domain package for the Strata framework.

## Overview

`strata_core` provides the core domain abstractions, functional error handling, state models, and storage/logger contracts used across all Strata sub-packages. It has **zero dependencies** on Flutter, Dio, Hive, BLoC, or any UI framework.

## Architectural Rules & Boundaries

* **Zero Framework Coupling**: Must NEVER import `package:flutter/`, `package:dio/`, `package:flutter_bloc/`, or `package:hive/`.
* **Pure Functional Core**: Uses `fpdart` for functional data structures (`Either`, `Option`, `Unit`) and `equatable` for value equality.
* **Strict Boundary Enforcement**: Enforced at build and CI time via `package_dependency_test.dart`.

## Key Components

### 1. `AsyncState<T>`
A pure functional sealed class representing asynchronous state transitions independent of BLoC or Flutter:

```dart
import 'package:strata_core/strata_core.dart';

final state = AsyncState<String>.success('data');

// Pattern matching
final message = state.when(
  initial: () => 'Initial state',
  loading: () => 'Loading...',
  success: (data) => 'Loaded: $data',
  failure: (failure, retry) => 'Error: ${failure.message}',
);
```

### 2. Failure Hierarchy
Strongly-typed exception and failure models extending `Failure` (which implements `Exception` and `Equatable`):

* `StorageFailure`: Key-value or local storage operation errors.
* `ServerFailure`: Backend HTTP 4xx/5xx errors (includes `statusCode` and optional `requestId`).
* `UnauthorizedFailure`: Auth/permission issues (401/403).
* `BusinessFailure`: Domain/business logic rule violations.
* `UnknownFailure`: Unhandled or unexpected exceptions.
* `ConnectionFailure`: Network connectivity errors.
* `ValidationFailure`: Client-side input validation errors.

### 3. `ResultFuture<T>` and `ResultStream<T>`
Standardized type definitions for asynchronous and real-time operations returning `Either<Failure, T>`:

```dart
typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;
```

### 4. `SensitiveStorageInterface`
Abstract contract for secure key-value token and credential storage:

```dart
abstract interface class SensitiveStorageInterface {
  ResultFuture<String?> read(String key);
  ResultFuture<Unit> save(String key, String value);
  ResultFuture<Unit> delete(String key);
  ResultFuture<Unit> deleteAll();
  ResultFuture<bool> containsKey(String key);
}
```

### 5. `StrataLoggerInterface`
Abstract logging interface and `NoOpStrataLogger` for testing or quiet environments:

```dart
abstract interface class StrataLoggerInterface {
  void verbose(dynamic message, [Object? error, StackTrace? stackTrace]);
  void debug(dynamic message, [Object? error, StackTrace? stackTrace]);
  void info(dynamic message, [Object? error, StackTrace? stackTrace]);
  void warning(dynamic message, [Object? error, StackTrace? stackTrace]);
  void error(dynamic message, [Object? error, StackTrace? stackTrace]);
}
```

### 6. `NetworkStatusInterface` & `ConnectionStatus`
Abstract contract for network connectivity monitoring with cold-start `unknown` state support:

```dart
enum ConnectionStatus { connected, disconnected, unknown }

abstract interface class NetworkStatusInterface {
  Future<bool> get isConnected;
  Stream<ConnectionStatus> get connectionStream;
  void dispose();
}
```

### 7. `PlatformServiceInterface` & `DeviceInfoEntity`
Contract for hardware and operating system metadata resolution:

```dart
abstract interface class PlatformServiceInterface {
  Future<DeviceInfoEntity> getDeviceInfo();
}
```

## Running Tests & Audits

Run unit tests and dependency boundary checks inside the `strata_core` directory:

```bash
cd strata_core
dart analyze
dart test
```
