# 06: Move string/datetime extensions and `ValueTester` to `strata_ui`

**What to build:** `strata_core` stays focused on domain entities and contracts; UI-adjacent utilities (file type checks for display, date formatting for presentation, value testing) live in `strata_ui`.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Move `strata_string_extensions.dart` from `strata_core/lib/src/extensions/` to `strata_ui/lib/src/extensions/`
- [x] Move `strata_datetime_extensions.dart` from `strata_core/lib/src/extensions/` to `strata_ui/lib/src/extensions/`
- [x] Move `value_tester.dart` from `strata_core/lib/src/utils/` to `strata_ui/lib/src/utils/`
- [x] Update `strata_core.dart` barrel export to remove all three
- [x] Update `strata_ui.dart` barrel export to add all three
- [x] Update all imports across the codebase
- [x] Move and update associated tests
- [x] Run `dart analyze` and `dart test` in both `strata_core` and `strata_ui`
