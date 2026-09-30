---
type: Interview Ledger
parent: spec.md
---

## Records

### L1

Status: current

Question: Should `strata` remove the broad, generic key-value database interface (`NoSqlDatabaseInterface`) in favor of targeted, task-specific persistence contracts or eliminate `strata_storage` as a core contract package entirely?

Recommended Answer:
- Remove generic header interfaces (`NoSqlDatabaseInterface`, `SecureDatabaseInterface`) from public architecture API.
- Keep `strata_storage` focused on framework contracts (e.g., token storage) and infrastructure helpers.
- Require domain features to define narrow repository contracts tailored to their data models.
- Negative Requirement: `strata_core` and `strata_network` MUST NOT depend on generic key-value wrappers.

Answer: Remove the local storage contract and generic wrappers, making database engine choice project-specific.

Decision: Remove `NoSqlDatabaseInterface` and generic database CRUD abstractions from core framework contracts.

Reason: Generic database wrappers create indirection without value, restrict native database capabilities, and bloat core dependencies.

### L2

Status: current

Question: How should `strata_storage` be structured so that applications retain full, unrestricted access to their database engine's native capabilities?

Recommended Answer:
- Provide framework infrastructure contracts (`SensitiveStorageInterface`).
- Provide security & encryption utilities (`SecureKeyManager`).
- Provide engine lifecycle helpers (Hive/Drift path and box setup).
- Require feature repositories to interact directly with native database instances (Hive `Box`, Drift `Database`, Isar).
- Negative Requirement: `strata_storage` MUST NOT wrap or hide database CRUD/query APIs behind generic `save<T>`/`get<T>` interfaces.

Answer: Redesign `strata_storage` as an infrastructure/contract package while giving feature repositories direct native access to database capabilities.

Decision: `strata_storage` provides infrastructure contracts and startup helpers without wrapping database CRUD or query APIs.

Reason: Wrapping database drivers hides advanced queries, indexes, streams, and schema migrations.

### L3

Status: current

Question: How should `strata_storage` and `strata_network` handle engine neutrality so a project can use Drift (or Isar/SQLite) without pulling in Hive or forcing a specific database dependency?

Recommended Answer:
- Define pure Dart storage contracts in `strata_core`.
- Provide default `FlutterSecureStorage` implementation in `strata_storage`.
- Allow custom engine implementations (e.g. `DriftTokenStorage`) to be registered via GetIt.
- Feature repositories use Drift directly via constructor injection.
- Negative Requirement: `strata_network` MUST NOT import Hive, Drift, or `strata_storage`.

Answer: Decouple storage engine via pure Dart interfaces in `strata_core` so consumer applications can use Drift, Isar, or Hive without forced framework dependencies.

Decision: Decouple network and storage contracts using pure Dart interfaces in `strata_core` to achieve complete database engine neutrality.

Reason: Keeps high-level network and domain layers independent of underlying database vendor implementations.

### L4

Status: current

Question: What exact contract signature, method names, return types, and package location should be used for sensitive token/data storage?

Recommended Answer:
- Package location: `strata_core/lib/src/storage/sensitive_storage_interface.dart`.
- Exact signatures: `read(String key)`, `save(String key, String value)`, `delete(String key)`, `deleteAll()`, `containsKey(String key)`.
- Return types: `ResultFuture<T>` returning `StorageFailure` on exceptions.
- Default implementation in `strata_storage` as `FlutterSecureSensitiveStorage`.
- Negative Requirement: `SensitiveStorageInterface` MUST NOT depend on Flutter UI, Dio, or Hive.

Answer: Prefer FlutterSecureStorage for sensitive token data with `read`, `save`, `delete`, `deleteAll`, and `containsKey` methods.

Decision: Define `SensitiveStorageInterface` in `strata_core` returning `ResultFuture<T>` types, implemented by `FlutterSecureSensitiveStorage` in `strata_storage`.

Reason: Encapsulates sensitive token persistence behind a clean, type-safe, testable contract.

### L5

Status: current

Question: What unified naming convention should be used across all Strata abstract contracts and concrete implementations?

Recommended Answer:
- Abstract contracts standardise on `Interface` suffix (e.g. `SensitiveStorageInterface`, `ApiHandlerInterface`).
- Concrete implementations prepend technology/driver prefix before base name (e.g. `FlutterSecureSensitiveStorage`, `DioApiHandler`).
- Negative Requirements: Do NOT use `Contract` suffix, `*Impl`/`*Imp` suffix, or `I*` prefix.

Answer: Standardise on `Interface` suffix for contracts and `<Technology><BaseName>` prefix for concrete implementations.

Decision: Enforce `Interface` suffix for abstract classes and technology-prefixed names for implementations across all 7 packages.

Reason: Establishes clear, self-documenting naming consistency without ambiguous `Impl` suffixes or non-standard `Contract` keywords.

### L6

Status: current

Question: How should `strata_network` handle token refresh failure cleanup and concurrent cancel token tracking?

Recommended Answer:
- Token refresh failure explicitly calls `_tokenManager.clearTokens()` on any `Left` result or exception and triggers `onUnauthenticated` callback.
- `CancelRequestManagerInterface` upgraded to track `Map<String, Set<CancelToken>>` with per-token unregistration.
- Negative Requirements: Refresh interceptor MUST NOT leave expired tokens in storage; cancel manager MUST NOT overwrite active cancel tokens during concurrent requests.

Answer: Fix token refresh cleanup to clear expired tokens on any failure, and upgrade cancel request manager to track multiple tokens per request ID.

Decision: `TokenRefreshInterceptor` explicitly clears tokens on failure, and `DefaultCancelRequestManager` tracks multi-token sets per request key.

Reason: Prevents infinite 401 retry loops from leftover expired tokens and prevents orphaned network connections during concurrent requests.

### L7

Status: current

Question: How should dependency injection modularization and testing teardown be orchestrated across sub-packages in `strata`?

Recommended Answer:
- Each sub-package provides a GetIt extension method (e.g., `registerStrataNetwork()`).
- Meta-package `strata` orchestrates DI via `StrataInitializer.initialize()`, awaiting `getIt.allReady()`.
- Expose `StrataInitializer.reset()` for unit/widget test teardowns.
- Negative Requirement: `StrataInitializer.initialize()` MUST NOT return before `await getIt.allReady()` resolves.

Answer: Provide modular GetIt extension methods per sub-package and orchestrate DI initialization via `StrataInitializer` with mandatory `await getIt.allReady()`.

Decision: Modularize DI with package-specific GetIt extensions, central `StrataInitializer` with async readiness, and clean test reset helpers.

Reason: Eliminates startup race conditions on async singletons and allows partial module consumption for non-BLoC/non-GoRouter apps.

### L8

Status: current

Question: How should `strata_state` decouple pure state representations (`ApiState<T>`) from BLoC-specific utilities?

Recommended Answer:
- Move pure union `ApiState<T>` to `strata_core` with zero BLoC/Flutter dependencies.
- Keep `ApiStateHostMixin` and `ApiStateHandler` in `strata_state`.
- Negative Requirement: `strata_core` MUST NOT import `flutter_bloc` or `flutter`.

Answer: Relocate `ApiState<T>` to `strata_core` so non-BLoC projects can use the core state model without pulling in `flutter_bloc`.

Decision: Move `ApiState<T>` to `strata_core` and isolate BLoC-specific mixins in `strata_state`.

Reason: Allows Riverpod, Provider, or Signals applications to use `ApiState<T>` without compiling unused BLoC classes.

### L9

Status: current

Question: How should `strata_navigation` and `strata_ui` be isolated so that UI components do not enforce GoRouter or state management dependencies?

Recommended Answer:
- `strata_navigation` contains GoRouter configuration and `ScreenParams`.
- `strata_ui` contains reusable UI widgets (`StrataPaginationWidget`, `StrataImage`).
- `strata_ui` widgets receive navigation callbacks via closures (`onItemTap`) and do not import `go_router` or `flutter_bloc`.
- Negative Requirement: Importing `strata_ui` MUST NOT compile `go_router` or `flutter_bloc`.

Answer: Keep `strata_ui` decoupled from `go_router` and `flutter_bloc` by passing navigation and state handlers via standard Flutter callbacks.

Decision: Isolate `strata_ui` from routing and BLoC dependencies using closure callbacks.

Reason: Ensures UI widgets remain 100% reusable across different state management and routing frameworks.

### L10

Status: current

Question: How should the migration from `coore` to `strata` be executed, and what development methodology should be enforced?

Recommended Answer:
- Clean break for `strata` monorepo (no legacy migration script or deprecated `coore` class wrappers).
- Mandate TDD (Red-Green-Refactor) for all package extraction and implementation work.
- Negative Requirement: Core `strata` packages MUST NOT carry legacy `coore` class wrappers or deprecated aliases.

Answer: Execute a clean break migration to `strata` monorepo without legacy bridge wrappers, and strictly enforce Red-Green-Refactor TDD during implementation.

Decision: Implement `strata` as a clean monorepo with no legacy debt, enforcing strict TDD for all unit and integration work.

Reason: Prevents legacy code debt from corrupting the new architecture and guarantees a 100% regression-proof test suite.

### L11

Status: current

Question: How should `ApiStateHandler.handleApiCall` prevent request swallowing when state is already `loading()`?

Recommended Answer:
- Add `force: bool = false` parameter to `handleApiCall()`.
- When `force: true`, execute API call immediately even if `currentState.isLoading` is true.
- If `force: false` and `currentState.isLoading` is true, log a diagnostic warning via `CoreLogger` instead of swallowing silently.
- Negative Requirement: `handleApiCall` MUST NOT silently drop requests without executing them (when `force: true`) or logging a diagnostic warning.

Answer: Add `force: bool = false` option to `handleApiCall` and log diagnostic warnings when skipping calls during loading states.

Decision: Enhance `ApiStateHandler.handleApiCall` with `force: true` override and diagnostic logging for skipped loading states.

Reason: Eliminates subtle request-swallowing bugs in multi-step async workflows and manual `ApiState.loading()` emissions.
