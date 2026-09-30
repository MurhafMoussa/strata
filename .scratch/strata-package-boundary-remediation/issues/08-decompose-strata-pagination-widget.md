# 08: Decompose `StrataPaginationWidget`

**What to build:** Each piece of the pagination widget is independently testable — skeleton loader, error view, empty view, offline badge, and scroll-to-top FAB extracted into separate components.

**Blocked by:** 03 (Make `Identifiable<T>` generic)

**Status:** ready-for-agent

- [ ] Extract `_DefaultEmptyState` into a public `StrataEmptyState` widget
- [ ] Extract `_DefaultOfflineBadge` into a public `StrataOfflineBadge` widget
- [ ] Extract `_DefaultBottomLoader` into a public `StrataBottomLoader` widget
- [ ] Extract `_DefaultBottomRetryBar` into a public `StrataBottomRetryBar` widget
- [ ] Extract `_DefaultErrorWidget` into a public `StrataErrorView` widget
- [ ] Update `StrataPaginationWidget` to use the extracted components
- [ ] Update `strata_ui.dart` barrel export to include new public components
- [ ] Write independent tests for each extracted component
- [ ] Run `dart analyze` and `dart test` in `strata_ui`
