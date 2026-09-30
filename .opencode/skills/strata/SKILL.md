---
name: strata
description: Router and architecture guide for the Strata Flutter & Dart framework. Routes to specialized skills for bootstrapping, authentication, clean feature slicing, and pagination.
disable-model-invocation: true
---

# Strata Framework Router

Strata is an enterprise modular Flutter & Dart framework decomposed into focused sub-packages:
- `strata_core`: Pure Dart contracts, domain entities, `ResultFuture<T>` (`Either<Failure, T>`), `AsyncState<T>`, `SensitiveStorageInterface`, `PaginationStrategy`.
- `strata_network`: `ApiHandlerInterface` (Dio wrapper), `TokenManagerInterface`, `CancelRequestManagerInterface`.
- `strata_storage`: `FlutterSecureSensitiveStorage`, encryption key helpers, directory setup.
- `strata_state`: `AsyncHostMixin`, `AsyncHandler`, `StrataPaginationBloc`, persistent cubits (`ThemeCubit`, `LocalizationCubit`).
- `strata_ui`: `AsyncBuilder`, `StrataPaginationWidget`, platform-adaptive widgets, responsive helpers.
- `strata`: Meta-package orchestrating `StrataInitializer` and exporting all sub-packages.

---

## 🧭 Selecting a Workflow

Diagnose the consumer's current goal and route to the corresponding specialized skill:

| Goal / Task | Specialized Skill | Command |
| :--- | :--- | :--- |
| **New Project / App Setup**<br>Setting up `main.dart`, `StrataInitializer`, `StrataConfigEntity`, DI registration | `strata-bootstrap` | `@strata-bootstrap` |
| **Authentication & Tokens**<br>Setting up login/logout, `TokenManagerInterface`, auto-refresh interceptors, `AuthBloc` | `strata-auth` | `@strata-auth` |
| **Clean Feature Implementation**<br>Scaffolding Feature-First Clean Architecture (`domain/`, `data/`, `presentation/`), UseCase, BLoC, and `AsyncBuilder` UI | `strata-feature` | `@strata-feature` |
| **Infinite Scroll & Pagination**<br>Wiring `StrataPaginationBloc` with `StrataPaginationWidget`, Page/Cursor strategies, and caching | `strata-pagination` | `@strata-pagination` |

---

## 📋 Strata Architecture Principles

When implementing or reviewing Strata code, enforce these non-negotiable rules:

1. **Domain Isolation**:
   - The domain layer (`domain/entities`, `domain/usecases`, `domain/repositories`) must depend **only** on `strata_core` and `fpdart`.
   - Domain never imports Flutter, Dio, `strata_network`, or data models.
2. **Functional Error Handling**:
   - Asynchronous use cases return `ResultFuture<T>` (defined as `Future<Either<Failure, T>>`).
   - Use cases extend `ResultFutureUseCase<Output, Input>`.
3. **Reactive Async State Management**:
   - BLoCs and Cubits managing asynchronous operations mix in `AsyncHostMixin<CompositeState>`.
   - Manage async fields using `createAsyncHandler<SuccessData>(...)`.
   - Always call `handler.dispose()` via the mixin's automatic `close()` hook.
4. **Deterministic Unit Testing**:
   - Every Domain UseCase and State BLoC must have companion unit tests using `bloc_test` and `mocktail`.
   - Test all lifecycle states: `initial`, `loading`, `success`, and `failure`.
