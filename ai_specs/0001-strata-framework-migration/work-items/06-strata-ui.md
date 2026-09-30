---
type: Work Item
title: Create strata_ui decoupled component package
parent: ../spec.md
---

## What to build
Implement `strata_ui` containing reusable UI components (`StrataPaginationWidget`, custom form fields `StrataTextField` / `StrataPinCodeField`, `StrataImage`) completely isolated from `flutter_bloc` and `go_router` via standard Flutter callback closures.

## Required context
- Depends on `strata_core` and `flutter`.
- MUST NOT depend on `flutter_bloc` or `go_router`.
- Navigation and state actions are handled by passing callbacks (`onItemTap`, `onRefresh`, etc.).

## Acceptance criteria
- [x] `strata_ui` sub-package is created.
- [x] UI components (`StrataPaginationWidget`, custom form fields, `StrataImage`) are extracted.
- [x] Package dependency check confirms zero references to `flutter_bloc` or `go_router`.
- [x] Widget tests verify component rendering and event callback triggers.

## Covers
- User Stories: 1
- Requirements: 1, 4
- Testing Strategy: 5
- Technical Decisions: 4
- Interview Ledger: L9

## Blocked by
01-strata-core.md
