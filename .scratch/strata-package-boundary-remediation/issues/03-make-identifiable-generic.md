# 03: Make `Identifiable<T>` generic

**What to build:** Compile-time type safety for the pagination system — `Identifiable<T>` uses `T get id` instead of `dynamic get id`, enabling the pagination bloc's `findById` method to work with typed IDs.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Change `Identifiable` from `dynamic get id` to `T get id` in `strata_core`
- [x] Update all implementations of `Identifiable` across the codebase to specify their ID type
- [x] Update `StrataPaginationBloc`, `StrataPaginationState`, `StrataPaginationEvent`, `PaginationCacheAdapterInterface` to use `Identifiable<T>` with proper type parameters
- [x] Update `StrataPaginationWidget` type constraints from `T extends Identifiable` to `T extends Identifiable<T>`
- [x] Update `PaginationParams` and related network types
- [x] Update all affected tests
- [x] Run `dart analyze` and `dart test` in each modified sub-package
