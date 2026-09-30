# 06: Move string/datetime extensions and `ValueTester` to `strata_ui`

**What to build:** `strata_core` stays focused on domain entities and contracts; UI-adjacent utilities (file type checks for display, date formatting for presentation, value testing) live in `strata_ui`.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Move `strata_string_extensions.dart` from `strata_core/lib/src/extensions/` to `strata_ui/lib/src/extensions/`
- [ ] Move `strata_datetime_extensions.dart` from `strata_core/lib/src/extensions/` to `strata_ui/lib/src/extensions/`
- [ ] Move `value_tester.dart` from `strata_core/lib/src/utils/` to `strata_ui/lib/src/utils/`
- [ ] Update `strata_core.dart` barrel export to remove all three
- [ ] Update `strata_ui.dart` barrel export to add all three
- [ ] Update all imports across the codebase
- [ ] Move and update associated tests
- [ ] Run `dart analyze` and `dart test` in both `strata_core` and `strata_ui`
