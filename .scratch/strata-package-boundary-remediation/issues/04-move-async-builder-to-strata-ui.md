# 04: Move `AsyncBuilder` to `strata_ui`

**What to build:** `strata_state` contains only state management logic (no UI widgets); `strata_ui` contains all UI components including `AsyncBuilder`.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Move `async_builder.dart` from `strata_state/lib/src/state_management/` to `strata_ui/lib/src/state_management/`
- [x] Update `strata_state.dart` barrel export to remove `AsyncBuilder`
- [x] Update `strata_ui.dart` barrel export to add `AsyncBuilder`
- [x] Remove `skeletonizer` from `strata_state/pubspec.yaml` (already present in `strata_ui`)
- [x] Update all imports across the codebase
- [x] Move and update `async_builder_test.dart`
- [x] Run `dart analyze` and `dart test` in both `strata_state` and `strata_ui`
