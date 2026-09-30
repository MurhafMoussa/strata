# 08: Decompose `StrataPaginationWidget`

**What to build:** Each piece of the pagination widget is independently testable — skeleton loader, error view, empty view, offline badge, and scroll-to-top FAB extracted into separate components.

**Blocked by:** 03 (Make `Identifiable<T>` generic)

**Status:** completed

- [x] Extract `_DefaultEmptyState` into a public `StrataEmptyState` widget
- [x] Extract `_DefaultOfflineBadge` into a public `StrataOfflineBadge` widget
- [x] Extract `_DefaultBottomLoader` into a public `StrataBottomLoader` widget
- [x] Extract `_DefaultBottomRetryBar` into a public `StrataBottomRetryBar` widget
- [x] Extract `_DefaultErrorWidget` into a public `StrataErrorView` widget
- [x] Update `StrataPaginationWidget` to use the extracted components
- [x] Update `strata_ui.dart` barrel export to include new public components
- [x] Write independent tests for each extracted component
- [x] Run `dart analyze` and `dart test` in `strata_ui`
