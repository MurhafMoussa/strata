# 07: Add `PaginationParamsInterface`

**What to build:** Type-safe pagination parameters — a `PaginationParamsInterface` with `String get requestId` that constrains the pagination bloc's generic parameter, eliminating `dynamic` typing in `_generateRequestId`.

**Blocked by:** 03 (Make `Identifiable<T>` generic)

**Status:** ready-for-agent

- [ ] Define `PaginationParamsInterface` in `strata_core` with `String get requestId`
- [ ] Constrain `P extends PaginationParamsInterface` in `StrataPaginationBloc` (replacing `P extends Object`)
- [ ] Update `_generateRequestId` to use `params.requestId` directly instead of dynamic reflection
- [ ] Update `PaginationStrategy` and all param classes to implement `PaginationParamsInterface`
- [ ] Update all affected tests
- [ ] Run `dart analyze` and `dart test` in `strata_core` and `strata_state`
