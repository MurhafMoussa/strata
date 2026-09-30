# Strata Framework — Package Assessment Report

**Date:** 2026-09-30  
**Scope:** Full monorepo audit of `strata_core`, `strata_network`, `strata_state`, `strata_storage`, `strata_ui`, and `strata` meta-package.

---

## Executive Summary

The Strata framework is a well-intentioned modular Flutter/Dart monorepo with clear architectural goals: pure-Dart core, functional error handling, decoupled UI, and strict package boundaries. The codebase demonstrates strong domain modeling (sealed unions, immutable entities, `Either`-based error handling) and thoughtful API design.

However, the packages are **messing up** in several significant ways: boundary violations that undermine the entire modular architecture, a missing package that was spec'd but never built, naming inconsistencies that contradict the project's own GLOSSARY, a UI dependency smuggled into the state management package, and a meta-package that silently hides public API types from consumers.

---

## 1. Dependency Boundary Violations

### 1.1 `strata_core` depends on `talker` — a Flutter package

**File:** `strata_core/pubspec.yaml`, line 16  
**File:** `strata_core/lib/src/dev_tools/talker_strata_logger.dart`, line 1

```yaml
# strata_core/pubspec.yaml
dependencies:
  talker: ^4.6.0   # <-- Flutter package in "pure Dart" core
```

The `talker` package depends on Flutter. This directly violates:
- `AGENTS.md` line 9: *"strata_core must never import Flutter or third-party UI/network packages"*
- `ai_specs/0001-strata-framework-migration/spec.md` line 35: *"Has ZERO dependencies on Flutter, Dio, or Hive"*
- `README.md` line 15: *"Pure Dart (equatable, fpdart, get_it)"*

The `TalkerStrataLogger` class imports `package:talker/talker.dart` which transitively pulls Flutter into any consumer that imports `strata_core`. This **destroys the entire value proposition** of the modular architecture — a developer using Riverpod who imports `strata_core` for `AsyncState<T>` will now compile Flutter.

**Severity: Critical.** This is the single most damaging issue in the monorepo.

### 1.2 `strata_state` depends on `skeletonizer` — a UI package

**File:** `strata_state/pubspec.yaml`, line 22  
**File:** `strata_state/lib/src/state_management/async_builder.dart`, line 3

```yaml
# strata_state/pubspec.yaml
dependencies:
  skeletonizer: ^3.0.0   # <-- UI package in state management
```

The `AsyncBuilder` widget uses `Skeletonizer` for loading states. This couples `strata_state` to a UI rendering library, which means:
- `strata_state` is no longer a pure state management package
- Any consumer of `strata_state` must accept `skeletonizer` as a transitive dependency
- The `AsyncBuilder` widget should live in `strata_ui`, not `strata_state`

**Severity: High.** Blurs the line between state management and UI.

### 1.3 `strata_state` depends on `device_info_plus` and `package_info_plus`

**File:** `strata_state/pubspec.yaml`, lines 13, 21  
**File:** `strata_state/lib/src/platform/platform_service_impl.dart`, lines 1-3

```yaml
dependencies:
  device_info_plus: ^13.2.0
  package_info_plus: ^10.2.1
```

These are platform-specific plugins. While `PlatformServiceImpl` legitimately needs them, this means `strata_state` cannot be used in pure Dart contexts (e.g., server-side rendering, CLI tools, or testing without Flutter bindings). The `PlatformCubit` and `PlatformServiceImpl` should arguably live in a separate `strata_platform` package or in `strata_ui`.

**Severity: Medium.** Reduces the portability of `strata_state`.

### 1.4 `strata_ui` depends on `strata_state`

**File:** `strata_ui/pubspec.yaml`, lines 26-27  
**File:** `strata_ui/lib/src/pagination/strata_pagination_widget.dart`, line 5

```yaml
dependencies:
  strata_state:
    path: ../strata_state
```

The `StrataPaginationWidget` consumes `StrataPaginationState` from `strata_state`. This creates a **circular architectural dependency**: `strata_state` has UI components (`AsyncBuilder`) that should be in `strata_ui`, and `strata_ui` depends on `strata_state` for state types. The dependency graph should be strictly hierarchical: `core → state → ui`, not bidirectional coupling.

**Severity: Medium.** Creates architectural coupling that will cause circular dependency issues as the codebase grows.

### 1.5 `strata_network` exports `talker_dio_logger` types

**File:** `strata_network/lib/strata_network.dart`, lines 1-2

```dart
export 'package:talker_dio_logger/talker_dio_logger.dart'
    show TalkerDioLogger, TalkerDioLoggerSettings;
```

This leaks third-party Dio logger types into the public API. Consumers of `strata_network` now have `TalkerDioLogger` in their namespace, and the `NetworkConfigEntity` exposes `TalkerDioLoggerSettings?` as a public field (`network_config_entity.dart`, line 65). This violates the principle of hiding implementation details behind interfaces.

**Severity: Medium.** Leaks third-party types into the public API contract.

---

## 2. Missing Package: `strata_navigation`

**File:** `ai_specs/0001-strata-framework-migration/spec.md`, line 39  
**File:** `pubspec.yaml`, lines 9-15

The spec defines 7 sub-packages:
> `strata_core`, `strata_network`, `strata_storage`, `strata_state`, `strata_navigation`, `strata_ui`, and meta-package `strata`

The workspace only contains 6:
```yaml
workspace:
  - strata
  - strata_core
  - strata_network
  - strata_state
  - strata_storage
  - strata_ui
```

`strata_navigation` was never created. The README (line 7) also claims "7 focused sub-packages" but only lists 6 in the table. This is a **specification-implementation gap** — either the spec was wrong or the package was dropped without updating the documentation.

**Severity: High.** The documentation is inconsistent with reality, and the missing package leaves routing concerns unaddressed.

---

## 3. Naming Inconsistencies with GLOSSARY

### 3.1 `PaginatedCancelManagerInterface` vs `CancelRequestManagerInterface`

**File:** `strata_core/lib/src/network/cancel_request_manager_interface.dart`, line 17  
**File:** `strata_network/lib/src/api_handler/cancel_request_manager_interface.dart`, line 6  
**File:** `GLOSSARY.md`, lines 23-25

The GLOSSARY explicitly states:
> **CancelRequestManagerInterface**: The network management interface in `strata_network`...

But `strata_core` defines `PaginatedCancelManagerInterface` (in a file named `cancel_request_manager_interface.dart`!), and `strata_network` defines `CancelRequestManagerInterface` that implements it. This is confusing:
- The file name in core doesn't match the class name
- The GLOSSARY says `CancelRequestManagerInterface` lives in `strata_network`, but there's also a `PaginatedCancelManagerInterface` in core
- The naming convention is inconsistent — one uses "Paginated" prefix, the other doesn't

**Severity: Medium.** Creates confusion about which interface is the canonical one.

### 3.2 `PlatformServiceImpl` naming

**File:** `strata_state/lib/src/platform/platform_service_impl.dart`, line 7

The GLOSSARY says:
> _Avoid_: `*Impl` suffix

But `PlatformServiceImpl` uses the `*Impl` suffix. The convention should be something like `DeviceInfoPlatformService` or `PlatformInfoService`.

**Severity: Low.** Minor naming convention violation.

### 3.3 `CoreBlocObserver` naming

**File:** `strata_state/lib/src/dev_tools/core_bloc_observer.dart`, line 6

The GLOSSARY says:
> _Avoid_: `Core*` prefix (implied by the pattern of avoiding legacy naming)

`CoreBlocObserver` uses the `Core*` prefix which the project explicitly moved away from. Should be `StrataBlocObserver`.

**Severity: Low.** Minor naming convention violation.

---

## 4. Code Smells and Architectural Issues

### 4.1 `strata_core` contains UI-adjacent utilities

**File:** `strata_core/lib/src/extensions/strata_string_extensions.dart` (283 lines)  
**File:** `strata_core/lib/src/extensions/strata_datetime_extensions.dart` (302 lines)  
**File:** `strata_core/lib/src/utils/value_tester.dart` (53 lines)

These are 638 lines of string/date/utility code that have nothing to do with the stated purpose of `strata_core` ("Domain entities, failures, logger contracts, and storage interfaces"). The `isVideo`, `isImage`, `isAudio`, `isPDF`, `isExcel`, `isWord` checks are UI-adjacent concerns. The `ValueTester` class is a generic utility that could live anywhere.

This bloats the core package and increases its surface area for no architectural benefit.

**Severity: Low.** Not harmful, but muddies the package's purpose.

### 4.2 `strata_ui_di.dart` is an empty stub

**File:** `strata_ui/lib/src/di/strata_ui_di.dart`, lines 1-9

```dart
extension StrataUiDiExtension on GetIt {
  void registerStrataUi() {
    // Component registrations if any UI dependencies are needed.
  }
}
```

This is a no-op. It exists solely to satisfy the pattern that every package has a DI extension. It's dead code that adds maintenance burden.

**Severity: Low.** Dead code.

### 4.3 `strata` meta-package hides public API types

**File:** `strata/lib/strata.dart`, lines 3-4

```dart
export 'package:strata_core/strata_core.dart'
    hide SkipPaginationParams, CursorPaginationParams;
```

The meta-package hides `SkipPaginationParams` and `CursorPaginationParams` from `strata_core`, but these are legitimate public API types that consumers may need. This is inconsistent — `PagePaginationParams` is exported but the other two pagination strategies are hidden. If consumers need them, they must import `strata_core` directly, defeating the purpose of the meta-package.

**Severity: Medium.** Inconsistent API surface that will confuse consumers.

### 4.4 `strata_storage` uses `library;` directive without name

**File:** `strata_storage/lib/strata_storage.dart`, line 1

```dart
library;
```

The `strata` meta-package also uses `library;` (line 1 of `strata/lib/strata.dart`). This is a Dart 3.x feature but using it without a name is unusual and provides no benefit. It's a code smell that suggests the file was generated or copied without understanding.

**Severity: Low.** Style issue.

### 4.5 `AsyncBuilder` in `strata_state` is a UI widget

**File:** `strata_state/lib/src/state_management/async_builder.dart`, line 7

`AsyncBuilder` is a `StatelessWidget` that uses `BlocBuilder` and `Skeletonizer`. It's a UI component living in the state management package. This should be in `strata_ui`.

**Severity: High.** Violates the separation of concerns between state management and UI.

### 4.6 `StrataPaginationWidget` is 791 lines in a single file

**File:** `strata_ui/lib/src/pagination/strata_pagination_widget.dart` (791 lines)

This is a god widget that handles: initial loading, error states, empty states, skeleton loading, pull-to-refresh, infinite scroll, offline badges, desktop shortcuts, scroll-to-top FAB, and three different builder patterns (scrollable, slivers, custom). It should be decomposed into smaller, testable components.

**Severity: Medium.** Maintainability and testability concern.

### 4.7 `StrataTextField` has 99 parameters

**File:** `strata_ui/lib/src/forms/strata_textfield.dart`, lines 14-99

The `StrataTextField` constructor has 99 named parameters. This is a code smell indicating the widget is doing too much. It wraps `typed_form_fields` but adds so many parameters that it's essentially a configuration object with a build method.

**Severity: Medium.** API usability concern.

### 4.8 `StrataPaginationBloc` uses dynamic typing for request ID generation

**File:** `strata_state/lib/src/pagination/strata_pagination_bloc.dart`, lines 100-112

```dart
String _generateRequestId(P params) {
  if (requestIdGenerator != null) {
    return requestIdGenerator!(params);
  }
  try {
    final dynamic p = params;
    final dynamic reqId = p.requestId;
    if (reqId is String && reqId.isNotEmpty) {
      return reqId;
    }
  } catch (_) {}
  return params.toString();
}
```

Using `dynamic` to access `requestId` on a generic type `P` is a type safety hole. If `P` doesn't have a `requestId` getter, it silently falls back to `params.toString()`. This should be constrained by an interface or use a different approach.

**Severity: Medium.** Type safety concern.

---

## 5. Test Coverage Gaps

### 5.1 `strata_core` has no tests for extensions

The `strata_string_extensions.dart` (283 lines) and `strata_datetime_extensions.dart` (302 lines) have no dedicated test files. These are pure functions that should be trivially testable.

**Severity: Medium.** 600+ lines of untested code.

### 5.2 `strata_network` has no tests for `DioApiHandler`

The `DioApiHandler` class (283 lines) is the core of the network package but has no direct unit tests. The `dio_api_handler_test.dart` file exists but the handler's `_handleResponse` method (which contains the response type dispatching logic) is complex and should have thorough tests.

**Severity: Medium.** Core logic may be undertested.

### 5.3 `strata_ui` has no tests for `StrataImage`

The `StrataImage` widget (405 lines) has a test file (`strata_image_test.dart`) but given the complexity of the widget (network, file, asset, SVG, shimmer, error states), the coverage is likely insufficient.

**Severity: Low.** May be adequately tested, but the complexity suggests gaps.

### 5.4 `strata_storage` has no tests for `FlutterSecureSensitiveStorage`

The `FlutterSecureSensitiveStorage` class (89 lines) has a test file but `FlutterSecureStorage` requires platform channels, making unit testing difficult. The tests likely use mocks, but the actual platform interaction is untested.

**Severity: Low.** Expected limitation of platform plugins.

---

## 6. Over-Engineering and Under-Engineering

### 6.1 Over-engineered: `ValueSelectorCubit` hierarchy

**Files:** `strata_state/lib/src/value_selector/` (4 files)

The `ValueSelectorCubit` → `SingleSelectorCubit` / `MultiSelectorCubit` hierarchy is 4 classes for what is essentially "toggle a value in a list." The abstraction is not pulling its weight — the `ValueSetter<List<T>>` callback pattern is unusual and the `updateAvailableValues` method mutates the `values` list in place, which is a side effect that breaks the immutable state pattern used elsewhere.

**Severity: Low.** Not harmful, but unnecessarily complex.

### 6.2 Over-engineered: `PaginationCachePolicy` enum

**File:** `strata_core/lib/src/pagination/pagination_cache_policy.dart` (28 lines)

A 3-value enum with 2 boolean getters. This is a simple configuration value that doesn't need its own file and could be a field on the pagination state or bloc.

**Severity: Low.** Minor over-abstraction.

### 6.3 Under-engineered: `Identifiable` interface

**File:** `strata_core/lib/src/models/identifiable.dart` (3 lines)

```dart
abstract interface class Identifiable {
  dynamic get id;
}
```

Using `dynamic` for `id` is a type safety hole. It should be `Object?` or generic `Identifiable<T>`. The `StrataPaginationBloc._deduplicateAndAppend` method uses `item.id` as a `String` in `findById(String id)` but the interface allows any type.

**Severity: Medium.** Type safety concern.

### 6.4 Under-engineered: `UseCase` base class

**File:** `strata_core/lib/src/use_cases/usecase.dart` (3 lines)

```dart
abstract class UseCase {
  const UseCase();
}
```

This is a marker class with no behavior. It adds no value and could be replaced with a simple typedef or just removed. The `ResultFutureUseCase`, `ResultStreamUseCase`, and `UnawaitedUseCase` all extend it but add their own `call` method signatures.

**Severity: Low.** Unnecessary abstraction.

---

## 7. Documentation Issues

### 7.1 README claims 7 packages but only 6 exist

**File:** `README.md`, line 7

> "decomposed into 7 focused sub-packages"

The table on lines 13-20 lists only 6 packages. `strata_navigation` is missing.

**Severity: Medium.** Misleading documentation.

### 7.2 No package-level README files

None of the sub-packages have their own `README.md` files. Consumers who depend on a single sub-package (e.g., `strata_core` only) have no documentation for that package's API.

**Severity: Medium.** Discoverability concern.

### 7.3 GLOSSARY is incomplete

**File:** `GLOSSARY.md` (69 lines)

The GLOSSARY covers many terms but is missing entries for:
- `NetworkExceptionMapperInterface`
- `PaginationCacheAdapterInterface`
- `PaginationCachePolicy`
- `StrataPaginationConfig`
- `StrataScrollableContentWithFab`
- `ValueSelectorCubit` / `SingleSelectorCubit` / `MultiSelectorCubit`
- `NetworkStatusCubit`
- `CoreBlocObserver`

**Severity: Low.** The GLOSSARY is a living document but should be more comprehensive.

---

## 8. What the Packages Are Doing Well

### 8.1 Clean domain modeling in `strata_core`

The `AsyncState<T>` sealed union (`async_state.dart`) is well-designed:
- Immutable with `Equatable`
- Pattern matching with `when` and `maybeWhen`
- `Option<T>` and `Option<Failure>` getters for safe access
- `retryFunction` callback for retry semantics

### 8.2 Consistent use of `Either` for error handling

The `ResultFuture<T>` typedef (`result_typedefs.dart`) and consistent use of `Either<Failure, T>` across all packages is excellent. The `DioExceptionMapper` cleanly maps Dio exceptions to domain failures.

### 8.3 Well-designed pagination system

The `PaginationStrategy` hierarchy (`pagination_strategy.dart`) with `PagePaginationStrategy`, `SkipPaginationStrategy`, and `CursorPaginationStrategy` is a clean, pure-function approach to pagination. The `StrataPaginationBloc` with its event-driven architecture and concurrency transformers (`restartable()`, `droppable()`) is well-implemented.

### 8.4 Good separation of concerns in `strata_network`

The interceptor chain (retry, token injection, token refresh) is well-designed with clear interfaces. The `TokenRefreshInterceptorInterface` with its mutex-based queuing and pending request replay is sophisticated and handles edge cases well.

### 8.5 Comprehensive `strata_storage` helpers

The `StorageEncryptionKeyHelper` with key rotation support and `StorageDirectoryHelper` with directory type resolution are practical, well-documented utilities.

### 8.6 Strong package boundary tests

Each package has a `package_dependency_test.dart` that audits imports and pubspec dependencies. This is a good practice that catches boundary violations at test time.

---

## 9. Summary of Issues by Severity

| Severity | Count | Key Issues |
|----------|-------|------------|
| **Critical** | 1 | `strata_core` depends on Flutter via `talker` |
| **High** | 3 | Missing `strata_navigation` package; `AsyncBuilder` UI widget in `strata_state`; `skeletonizer` UI dependency in `strata_state` |
| **Medium** | 8 | `strata_ui` → `strata_state` coupling; `talker_dio_logger` type leakage; hidden public API types in meta-package; `Identifiable` uses `dynamic`; `StrataPaginationBloc` dynamic typing; missing extension tests; missing package READMEs; README package count wrong |
| **Low** | 7 | `PlatformServiceImpl` naming; `CoreBlocObserver` naming; empty `strata_ui_di`; `library;` without name; `ValueSelectorCubit` over-engineering; `PaginationCachePolicy` over-abstraction; `UseCase` marker class; incomplete GLOSSARY |

---

## 10. Recommendations

1. **Remove `talker` from `strata_core`** — Make `TalkerStrataLogger` an optional implementation that lives in a separate package or in `strata_ui`. The `StrataLoggerInterface` and `NoOpStrataLogger` are sufficient for the core package.

2. **Move `AsyncBuilder` to `strata_ui`** — It's a UI widget that belongs with other UI components.

3. **Remove `skeletonizer` from `strata_state`** — The `AsyncBuilder` should be in `strata_ui` where `skeletonizer` is an appropriate dependency.

4. **Create `strata_navigation` or update the spec** — Either build the missing package or update the spec and README to reflect the actual 6-package architecture.

5. **Fix the meta-package exports** — Stop hiding `SkipPaginationParams` and `CursorPaginationParams` from consumers.

6. **Add package-level READMEs** — Each sub-package should have a brief README explaining its purpose and key APIs.

7. **Add tests for `strata_core` extensions** — The string and datetime extensions are pure functions that should have comprehensive tests.

8. **Fix `Identifiable` to use `Object?` or generics** — Avoid `dynamic` for type safety.

9. **Rename `PlatformServiceImpl` and `CoreBlocObserver`** — Follow the project's own naming conventions.

10. **Decompose `StrataPaginationWidget`** — Break the 791-line god widget into smaller, testable components.

---

## 11. Missing Functionality (Not Built at All)

Beyond the architectural issues above, the framework is missing entire categories of functionality that a complete Flutter app framework needs:

### 11.1 Navigation / Routing

**Status:** Spec'd as `strata_navigation` in `ai_specs/0001-strata-framework-migration/spec.md` but never built.

**What's missing:**
- Router abstraction (no `StrataRouter`, no route definitions)
- Deep-link handling
- Route guards / middleware
- Typed route arguments

**Impact:** Every consumer must bring their own routing solution (GoRouter, AutoRoute, Navigator 2.0). The framework has no answer for "how do I navigate between screens?"

### 11.2 Theming / Styling System

**Status:** Does not exist.

**What's missing:**
- Theme tokens (colors, spacing, typography, radii, shadows)
- `StrataTheme` or equivalent centralized theme object
- Dark mode / light mode switching
- Component-level theme overrides
- Design system documentation

**Impact:** `strata_ui` widgets exist but have no centralized styling. Each app must define its own visual language from scratch.

### 11.3 Form Validation Framework

**Status:** Does not exist.

**What's missing:**
- `Validator<T>` abstraction
- `FormState` / form-level error handling
- Field-level validation contracts
- Async validation support
- Cross-field validation

**Impact:** `StrataTextField` exists but there's no validation layer. Consumers must build their own validation logic for every form.

### 11.4 Centralized DI Configuration

**Status:** Partial — each package has a `*_di.dart` extension, but no composition root.

**What's missing:**
- Top-level `configureDependencies()` that wires all packages together
- Environment-specific DI configurations
- Testing DI overrides

**Impact:** Consumers must manually wire each package's DI extensions together. No single entry point for "set up the framework."

### 11.5 Environment / Config Management

**Status:** Does not exist.

**What's missing:**
- `StrataConfig` or environment abstraction
- Dev/staging/prod environment flags
- Feature toggles
- API base URL management
- Build-time vs. runtime config

**Impact:** No standardized way to manage environment-specific settings.

### 11.6 Internationalization (i18n)

**Status:** Does not exist.

**What's missing:**
- Localization infrastructure
- `StrataLocalizations` or equivalent
- Locale switching
- Pluralization / gender / date formatting
- ARB file integration or equivalent

**Impact:** No answer for multi-language apps.

### 11.7 What's NOT Missing (Intentionally Out of Scope)

- **Auth flows** — token refresh interceptor already handles the hard part
- **Offline/sync** — out of scope for a UI framework
- **Push notifications** — app-level concern, not framework-level
- **Analytics** — app-level concern

### 11.8 Priority Ranking

| Priority | Feature | Reason |
|----------|---------|--------|
| **1** | Navigation / Routing | Spec'd but missing; every app needs it |
| **2** | Theming / Styling | `strata_ui` widgets need a design system |
| **3** | Form Validation | `StrataTextField` is useless without it |
| **4** | Centralized DI | Composition root ties everything together |
| **5** | Environment Config | Needed for any real app |
| **6** | i18n | Important but can be added later |
