# 09: Fix `ValueSelectorCubit` immutability

**What to build:** Immutable state updates in the value selector hierarchy — `updateAvailableValues` returns a new list instead of mutating in place, and the callback pattern is simplified.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Fix `ValueSelectorCubit.updateAvailableValues` to replace the `values` list reference instead of calling `clear()` / `addAll()` in place
- [ ] Simplify the callback pattern (remove `valueSetter` callback if it causes side effects, or make it explicit)
- [ ] Update `SingleSelectorCubit` and `MultiSelectorCubit` if they override `updateAvailableValues`
- [ ] Update tests to verify immutability (original list reference unchanged after update)
- [ ] Run `dart analyze` and `dart test` in `strata_state`
