# 03: Make `Identifiable<T>` generic

**What to build:** Compile-time type safety for the pagination system — `Identifiable<T>` uses `T get id` instead of `dynamic get id`, enabling the pagination bloc's `findById` method to work with typed IDs.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Change `Identifiable` from `dynamic get id` to `T get id` in `strata_core`
- [ ] Update all implementations of `Identifiable` across the codebase to specify their ID type
- [ ] Update `StrataPaginationBloc`, `StrataPaginationState`, `StrataPaginationEvent`, `PaginationCacheAdapterInterface` to use `Identifiable<T>` with proper type parameters
- [ ] Update `StrataPaginationWidget` type constraints from `T extends Identifiable` to `T extends Identifiable<T>`
- [ ] Update `PaginationParams` and related network types
- [ ] Update all affected tests
- [ ] Run `dart analyze` and `dart test` in each modified sub-package
