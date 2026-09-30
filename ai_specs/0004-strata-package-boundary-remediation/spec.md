# Strata Package Boundary Remediation

## Problem Statement

The Strata framework monorepo has architectural boundary violations and design inconsistencies that undermine its core value proposition of a modular, decoupled Flutter/Dart framework. A package assessment report identified 1 Critical, 3 High, and 8 Medium severity issues, plus missing functionality and code smells. After a grilling session, several findings were confirmed as real issues while others were identified as false positives.

## Solution

Remediate the confirmed architectural issues across the Strata monorepo by:

1. **Preserving pure-Dart integrity** — `strata_core` stays pure Dart (the `talker` dependency is pure Dart, not Flutter — the assessment report was wrong)
2. **Enforcing strict package boundaries** — UI widgets belong in `strata_ui`, state management in `strata_state`, domain entities in `strata_core`
3. **Eliminating type safety holes** — Replace `dynamic` with generics and interfaces
4. **Aligning code with documented conventions** — Fix naming violations of the GLOSSARY
5. **Completing the domain model** — Update GLOSSARY with all new and renamed terms
6. **Maintaining intentional scope boundaries** — No theming, no form validation framework, no env config, no i18n, no navigation package

## User Stories

1. As a Flutter developer using Riverpod, I want to import `strata_core` for `AsyncState<T>` without compiling Flutter, so that my application stays lean
2. As a consumer of `strata_state`, I want the package to contain only state management logic (no UI widgets), so that I don't transitively depend on UI rendering libraries
3. As a consumer of `strata_ui`, I want the package to contain all UI components including `AsyncBuilder`, so that I have a single import for UI needs
4. As a consumer of the `strata` meta-package, I want all public API types exported (no hidden types), so that I can use any pagination strategy without importing sub-packages directly
5. As a consumer of `strata_network`, I want the package to stop leaking `talker_dio_logger` types, so that my namespace stays clean
6. As a consumer of `strata_state`, I want platform-specific code (`PlatformCubit`, `PlatformServiceImpl`) moved to `strata_ui`, so that `strata_state` remains portable
7. As a developer reading the GLOSSARY, I want all framework terms documented, so that I have a shared vocabulary with the framework
8. As a developer using the pagination system, I want type-safe `Identifiable<T>` and `PaginationParamsInterface`, so that I get compile-time guarantees instead of runtime errors
9. As a consumer of the meta-package, I want a `StrataInitializer` composition root, so that I don't need to know the correct DI registration order
10. As a developer maintaining `StrataPaginationWidget`, I want it decomposed into smaller components, so that each piece is independently testable
11. As a developer using `ValueSelectorCubit`, I want the hierarchy to use immutable state updates, so that I don't get side effects from in-place mutations
12. As a consumer of `strata_core`, I want string/datetime extensions moved to `strata_ui`, so that `strata_core` stays focused on domain entities and contracts
13. As a developer, I want the spec updated to remove `strata_navigation`, so that documentation matches reality
14. As a developer, I want the README to say "6 sub-packages" instead of "7", so that I'm not looking for a package that doesn't exist
15. As a developer, I want comprehensive tests for all coverage gaps, so that the 100% coverage requirement is met
16. As a consumer, I want the framework to stay minimal (no theming, no form validation, no env config, no i18n), so that I can bring my own solutions

## Implementation Decisions

### Package Boundary Fixes

1. **Keep `talker` in `strata_core`** — The `talker` package is pure Dart (depends only on `talker_logger` → `ansicolor` + `web`). The assessment report's CRITICAL severity was a false positive. `TalkerStrataLogger` is a legitimate pure-Dart implementation of `StrataLoggerInterface`.

2. **Remove `strata_navigation` from spec** — Navigation is an app-level concern. Update `ai_specs/0001-strata-framework-migration/spec.md` to remove the `strata_navigation` package definition. Update README to say "6 sub-packages" instead of "7".

3. **Move `AsyncBuilder` to `strata_ui`** — `AsyncBuilder` is a `StatelessWidget` using `BlocBuilder` and `Skeletonizer`. It belongs in `strata_ui` where `skeletonizer` is already a dependency. Remove `skeletonizer` from `strata_state/pubspec.yaml`.

4. **Accept `strata_ui` → `strata_state` dependency** — This is legitimate architectural layering. UI widgets naturally consume state types. The spec's "MUST NOT depend on `flutter_bloc`" refers to direct dependency, which is satisfied.

5. **Remove `hide` clause from meta-package** — Export all three pagination params (`SkipPaginationParams`, `CursorPaginationParams`, `PagePaginationParams`) from the `strata` meta-package.

6. **Stop exporting `talker_dio_logger` types from `strata_network`** — Remove the `export 'package:talker_dio_logger/...'` line. Consumers add Talker integration themselves.

7. **Move `PlatformCubit` and `PlatformServiceImpl` to `strata_ui`** — Platform-specific code belongs in the UI package. Remove `device_info_plus` and `package_info_plus` from `strata_state/pubspec.yaml`.

8. **Fix naming inconsistencies**:
   - Rename `PaginatedCancelManagerInterface` → `CancelRequestManagerInterface` in `strata_core` (and update the network one to extend it)
   - Rename `PlatformServiceImpl` → `DeviceInfoPlatformService` (avoid `*Impl` suffix per GLOSSARY)
   - Rename `CoreBlocObserver` → `StrataBlocObserver` (avoid `Core*` prefix per GLOSSARY)

### Core Package Scope

9. **Move string/datetime extensions and `ValueTester` to `strata_ui`** — These are UI-adjacent utilities (file type checks for display, date formatting for presentation). Keeps `strata_core` focused on domain entities and contracts.

10. **Add `StrataInitializer` to meta-package** — Composition root that calls all sub-package DI extensions in dependency order and awaits `getIt.allReady()`.

11. **All "missing functionality" is intentionally out of scope** — No theming/design system, no form validation framework, no environment config, no i18n, no navigation package. These are app-level concerns.

### Type Safety

12. **Make `Identifiable<T>` generic** — Change from `dynamic get id` to `T get id`. Enables compile-time type safety for the pagination bloc's `findById` method.

13. **Add `PaginationParamsInterface`** — Define interface with `String get requestId`. Constrain `P extends PaginationParamsInterface` in `StrataPaginationBloc`. Eliminates `dynamic` typing in `_generateRequestId`.

### Code Quality

14. **Remove `UseCase` marker class** — It's a marker with no behavior. Sub-classes (`ResultFutureUseCase`, `ResultStreamUseCase`, `UnawaitedUseCase`) stand on their own.

15. **Fill `strata_ui_di.dart` with `PlatformCubit` registration** — Since `PlatformCubit` moves to `strata_ui`, its DI registration goes here. The extension gains real content.

16. **Remove `library;` directive** — Remove from `strata_storage.dart` and `strata.dart`. Without `part` files, it's noise.

17. **Decompose `StrataPaginationWidget`** — Extract skeleton loader, error view, empty view, offline badge, and scroll-to-top FAB into separate, testable components.

18. **Keep `StrataTextField` as-is** — 99 optional named parameters is acceptable. Consumers only pass what they need.

19. **Add comprehensive tests** — Cover all flagged gaps: `strata_core` extensions, `DioApiHandler._handleResponse`, `StrataImage`, `FlutterSecureSensitiveStorage`. Use `TestDefaultBinaryMessengerBinding` for platform channel mocking.

20. **Keep `ValueSelectorCubit` hierarchy, fix immutability** — Keep the class hierarchy (selection type is a genuine domain axis). Fix `updateAvailableValues` to return a new list instead of mutating in place. Simplify the callback pattern.

21. **Keep `PaginationCachePolicy` enum** — Named enums are more self-documenting than boolean flags.

22. **Update GLOSSARY with all missing entries** — Add: `NetworkExceptionMapperInterface`, `PaginationCacheAdapterInterface`, `PaginationCachePolicy`, `StrataPaginationConfig`, `StrataScrollableContentWithFab`, `ValueSelectorCubit` / `SingleSelectorCubit` / `MultiSelectorCubit`, `NetworkStatusCubit`, `StrataBlocObserver`, `Identifiable<T>`, `PaginationParamsInterface`.

## Testing Decisions

- **Test external behavior, not implementation details** — Test what a widget renders, what a bloc emits, what an interface guarantees. Don't test private methods or internal state.
- **Use existing test seams** — `bloc_test` for state management, `flutter_test` for widgets, `test` for pure Dart. Mock platform channels with `TestDefaultBinaryMessengerBinding`.
- **Prior art** — Follow existing `package_dependency_test.dart` patterns for boundary audits. Follow existing `*_test_helpers.dart` patterns for shared test utilities.
- **Coverage requirement** — 100% coverage across all public APIs per AGENTS.md. All sub-packages must achieve and maintain this.

## Out of Scope

1. **Theming / design system** — Consumers bring their own design
2. **Form validation framework** — Consumers use `typed_form_fields` or similar
3. **Environment config** — App-level concern, each app defines its own environments
4. **Internationalization (i18n)** — App-level concern, consumers have their own localization cubits
5. **Navigation / routing** — App-level concern, consumers bring their own routing solution
6. **Auth flows** — Token refresh interceptor already handles the hard part
7. **Offline/sync** — Out of scope for a UI framework
8. **Push notifications** — App-level concern
9. **Analytics** — App-level concern

## Further Notes

- The assessment report (`ai_specs/package_assessment.md`) had 3 false positives: (1) `talker` is pure Dart not Flutter, (2) "missing functionality" is intentionally out of scope, (3) navigation is an app-level concern
- The framework's philosophy is **minimalism**: provide behavior and structure, consumers provide design, environment config, and localization
- The `strata` meta-package serves as both a barrel export and a composition root (`StrataInitializer`)
- All decisions were validated through a 22-question grilling session with the user
