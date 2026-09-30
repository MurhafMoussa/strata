# 01: Cleanup & renames

**What to build:** Codebase aligned with GLOSSARY conventions — no unnecessary `library;` directives, no empty marker class, no hidden meta-package exports, no leaked `talker_dio_logger` types, and consistent naming for cancel-request-manager and bloc-observer types.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Remove `library;` directive from `strata_storage.dart` and `strata.dart`
- [x] Remove `UseCase` marker class from `strata_core`; update `ResultFutureUseCase`, `ResultStreamUseCase`, `UnawaitedUseCase` to stand on their own (no `extends UseCase`)
- [x] Remove `hide SkipPaginationParams, CursorPaginationParams` from `strata.dart` meta-package export
- [x] Remove `export 'package:talker_dio_logger/talker_dio_logger.dart'` from `strata_network.dart`
- [x] Rename `PaginatedCancelManagerInterface` → `CancelRequestManagerInterface` in `strata_core`; update `strata_network` to extend it; update all references
- [x] Rename `CoreBlocObserver` → `StrataBlocObserver`; update all references
- [x] Update all affected tests to use new names
- [x] Run `dart analyze` and `dart test` in each modified sub-package
