---
type: Spec
title: Strata Monorepo Modularization and Refactoring
---

## Problem

The current `coore` Flutter foundation (v1.0.8) suffers from three core architectural limitations:
1. **Architectural Lock-in:** Consumer apps are forced to pull in `flutter_bloc` and `go_router` even if using Riverpod, Provider, or alternative routing solutions.
2. **Monolithic Scope:** Pure Dart domain and data logic are coupled with Flutter UI dependencies (`skeletonizer`, `easy_refresh`, `pinput`).
3. **Dependency Upkeep Risk:** Managing ~30 direct dependencies in a single monolithic `pubspec.yaml` increases version solver conflicts during Flutter SDK upgrades.
4. **Critical Core Bugs:**
   - Unhandled token refresh failures in `TokenRefreshInterceptorInterface` fail to clear stored expired tokens when API calls return `Left(Failure)`.
   - `DefaultCancelRequestManager` overwrites active cancel tokens when concurrent requests share the same request ID key, leaving active connections un-cancelable.
   - Async DI resolution in `initializeCoreDependencies()` does not `await getIt.allReady()`, causing startup race conditions.
   - `ApiStateHandler.handleApiCall()` silently swallows API execution calls if `currentState.isLoading` is true.

## Proposed Outcome

Rebrand and refactor `coore` into **`strata`**, an enterprise Melos monorepo comprising 6 focused sub-packages (`strata_core`, `strata_network`, `strata_storage`, `strata_state`, `strata_ui`, and meta-package `strata`). Remove monolithic database wrappers, establish a unified class and interface naming convention (`Interface` suffix, technology-prefixed implementation names), fix all networking and state lifecycle bugs, decouple UI widgets from state management/routing, and enforce strict Red-Green-Refactor TDD for all package implementations.

## User Stories

1. As a Flutter developer using Riverpod or Provider, I want to import `strata_network` and `strata_core` without compiling `flutter_bloc` or `go_router`, so that my application stays lean and free of forced framework lock-in. [L1, L3, L8, L9]
2. As a mobile application developer, I want my feature repositories to interact directly with native database engines (Drift, Isar, Hive) while storing auth tokens in `SensitiveStorageInterface`, so that I get 100% of my database's query capabilities without framework restrictions. [L1, L2, L4]
3. As an application security engineer, I want expired authentication tokens to be automatically deleted from secure storage whenever token refresh fails, so that users are cleanly redirected to authentication without getting stuck in infinite 401 retry loops. [L6]
4. As a mobile app user navigating rapidly between screens firing identical API requests, I want request cancellation to track each request distinctly, so that navigating away cancels only the intended network connection without corrupting concurrent requests. [L6]
5. As a developer building multi-stage async workflows in BLoC/Cubit, I want `ApiStateHandler.handleApiCall(force: true)` to allow explicit re-execution during loading states while logging diagnostic warnings when duplicate calls are skipped, so that my API requests are never silently swallowed. [L11]
6. As a developer writing unit and widget tests, I want `StrataInitializer.reset()` and package-specific GetIt extensions to clean up dependency injection state cleanly between test runs, so that my test suite remains fast and isolation-guaranteed. [L7, L10]

## Requirements

### Package Decomposition & Dependencies
1. The framework MUST be structured as a Melos monorepo containing 6 sub-packages:
   - `strata_core`: Pure Dart domain entities, failures (including `StorageFailure`), `ResultFuture<T>` typedefs, logger interfaces, `ApiState<T>`, and `SensitiveStorageInterface`. Has ZERO dependencies on Flutter, Dio, or Hive. [L1, L3, L4, L8]
   - `strata_network`: Dio HTTP client wrapper, `ApiHandlerInterface`, `TokenRefreshInterceptorInterface`, `CancelRequestManagerInterface`, `DefaultCancelRequestManager`, `TokenManagerInterface`, and `DefaultTokenManager`. Depends on `strata_core` and `dio`. [L3, L5, L6]
   - `strata_storage`: Infrastructure adapters including `FlutterSecureSensitiveStorage` and database setup/key-rotation helpers. Depends on `strata_core` and `flutter_secure_storage`. [L1, L2, L4]
   - `strata_state`: BLoC state utilities including `ApiStateHostMixin`, `DisposableApiStateHandlerInterface`, `ApiStateHandler`, and `ApiStateBuilder`. Depends on `strata_core` and `flutter_bloc`. [L8, L11]
   - `strata_ui`: Reusable UI components (`StrataPaginationWidget`, custom form fields, `StrataImage`). Depends on `strata_core` and `flutter`. MUST NOT depend on `flutter_bloc` or `go_router`. [L9]
   - `strata`: Orchestrator meta-package exporting all sub-packages for single-line app initialization. [L7]

### Interface & Class Naming Conventions
2. All abstract contracts and interfaces MUST use the `Interface` suffix (e.g., `SensitiveStorageInterface`, `ApiHandlerInterface`, `CancelRequestManagerInterface`, `TokenManagerInterface`). [L5]
3. All concrete implementations wrapping third-party drivers or SDKs MUST prepend the technology or driver name as a prefix before the base name (e.g., `FlutterSecureSensitiveStorage`, `DioApiHandler`). Generic in-memory or fallback framework components MAY use descriptive functional prefixes (e.g., `DefaultCancelRequestManager`, `DefaultTokenManager`). [L5]
4. Classes MUST NOT use the `Contract` suffix, generic `*Impl`/`*Imp` suffixes, or `I*` prefixes. [L5]

### Sensitive Storage Contract
5. `SensitiveStorageInterface` MUST be defined in `strata_core` with the following method signatures returning `ResultFuture<T>` (resolving to `StorageFailure` on error):
   - `ResultFuture<String?> read(String key)`
   - `ResultFuture<Unit> save(String key, String value)`
   - `ResultFuture<Unit> delete(String key)`
   - `ResultFuture<Unit> deleteAll()`
   - `ResultFuture<bool> containsKey(String key)` [L4]
6. `strata_storage` MUST provide `FlutterSecureSensitiveStorage` implementing `SensitiveStorageInterface` using `FlutterSecureStorage`. [L4]
7. `strata_core` and generic storage contracts MUST NOT wrap or restrict native database APIs (Hive, Drift, Isar) behind generic key-value CRUD abstractions like `NoSqlDatabaseInterface`. [L1, L2]

### Networking & Token Lifecycle
8. When token refresh fails (returning `Left(Failure)` or throwing an Exception during refresh API calls), `TokenRefreshInterceptorInterface` MUST explicitly call `_tokenManager.clearTokens()` and emit an `onUnauthenticated` event callback (configured via constructor or `TokenManagerInterface`) before rejecting pending queued requests. [L6]
9. `DefaultCancelRequestManager` implementing `CancelRequestManagerInterface` MUST track active cancel tokens using a multi-token map (`Map<String, Set<CancelToken>>`):
   - `CancelToken registerRequest(String requestId)` MUST create, store, and return a distinct `CancelToken`.
   - `void cancelToken(CancelToken token, {String? reason})` MUST cancel only the specified token instance.
   - `void cancelRequest(String requestId, {String? reason})` MUST cancel all active tokens associated with `requestId`.
   - `void unregisterToken(String requestId, CancelToken token)` MUST remove only the specified token from the set. [L6]

### Dependency Injection Orchestration
10. Each sub-package MUST expose a GetIt registration extension (e.g., `registerStrataNetwork()`). [L7]
11. `StrataInitializer.initialize(StrataConfigEntity config)` in the `strata` meta-package MUST invoke sub-package extensions and MUST `await getIt.allReady()` before returning to eliminate async startup race conditions. [L7]
12. `StrataInitializer.reset()` MUST reset GetIt singletons cleanly for test teardowns. [L7]

### State Management & Request Handling
13. `ApiStateHandler.handleApiCall()` MUST accept an optional `force: bool = false` parameter. [L11]
14. When `force: true` is supplied, `handleApiCall()` MUST execute the API request immediately even if `currentState.isLoading` is true. [L11]
15. When `force: false` and `currentState.isLoading` is true, `handleApiCall()` MUST log a diagnostic warning via `CoreLogger` explaining why the duplicate request was skipped. [L11]

## Technical Decisions

1. **Clean Monorepo Break:** `strata` is published as a clean monorepo without carrying legacy `coore` backwards-compatibility class wrappers, migration scripts, or deprecated aliases internally. [L10]
2. **Database Neutrality:** `strata_network` depends solely on `SensitiveStorageInterface` in `strata_core`. App feature repositories interact directly with native database engines (Drift, Isar, Hive) injected via constructor parameters. [L1, L2, L3]
3. **Decoupled State Representation:** Pure `ApiState<T>` is located in `strata_core`, freeing non-BLoC projects from `flutter_bloc` compile-time dependencies. [L8]
4. **UI Decoupling via Callbacks:** `strata_ui` widgets receive navigation and event handlers as standard Flutter closures (`onItemTap`, `onRefresh`), isolating `strata_ui` from `go_router` and `flutter_bloc`. [L9]

## Testing Strategy

1. **Test-Driven Development (Red-Green-Refactor):** All sub-package implementations, bug fixes, and feature refactorings MUST be developed using strict TDD:
   - **Red:** Write a failing unit/widget test in `test/` capturing the exact requirement.
   - **Green:** Write the minimum production code required to make the test pass.
   - **Refactor:** Optimize code structure and naming while keeping tests passing. [L10]
2. **Network Interceptor Tests:**
   - Unit test `TokenRefreshInterceptorInterface` to verify `_tokenManager.clearTokens()` is called and `onUnauthenticated` is emitted on HTTP 400/401 refresh responses. [L6]
   - Unit test `DefaultCancelRequestManager` with concurrent requests sharing the same request ID to verify both tokens remain active and can be cancelled independently via `cancelToken` or `cancelRequest`. [L6]
3. **State Handler Tests:**
   - Unit test `ApiStateHandler.handleApiCall(force: true)` to verify request execution when state is `ApiState.loading()`. [L11]
   - Unit test `ApiStateHandler.handleApiCall(force: false)` to verify diagnostic log output when skipped during loading state. [L11]
4. **Dependency Injection Tests:**
   - Test `StrataInitializer.initialize()` to verify `allReady()` is awaited before returning and that `StrataInitializer.reset()` safely clears registrations. [L7]
5. **Package Boundary & UI Tests:**
   - Automated dependency audit tests verifying that `strata_core` and `strata_ui` do not import prohibited packages (`flutter_bloc`, `go_router`). [L1, L8, L9]
   - Widget tests for `strata_ui` components verifying event callback invocation without routing/state framework bindings. [L9]

## Out of Scope

1. Legacy `coore` package backwards-compatibility bridge layers or migration scripts (clean break upgrade). [L10]
2. Monolithic database wrappers (`NoSqlDatabaseInterface` and `SecureDatabaseInterface` CRUD wrappers). [L1, L2]
3. Automatic database ORM generation for app-level domain data. [L2, L3]
