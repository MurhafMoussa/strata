# 07: Add `PaginationParamsInterface`

**What to build:** Type-safe pagination parameters — a `PaginationParamsInterface` with `String get requestId` that constrains the pagination bloc's generic parameter, eliminating `dynamic` typing in `_generateRequestId`.

**Blocked by:** 03 (Make `Identifiable<T>` generic)

**Status:** completed

- [x] Define `PaginationParamsInterface` in `strata_core` with `String get requestId`
- [x] Constrain `P extends PaginationParamsInterface` in `StrataPaginationBloc` (replacing `P extends Object`)
- [x] Update `_generateRequestId` to use `params.requestId` directly instead of dynamic reflection
- [x] Update `PaginationStrategy` and all param classes to implement `PaginationParamsInterface`
- [x] Update all affected tests
- [x] Run `dart analyze` and `dart test` in `strata_core` and `strata_state`
