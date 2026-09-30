# 10: Add comprehensive tests for coverage gaps

**What to build:** 100% test coverage across all public APIs per AGENTS.md — all flagged coverage gaps filled with tests that verify external behavior, not implementation details.

**Blocked by:** 01, 02, 03, 04, 05, 06, 07, 08, 09

**Status:** ready-for-agent

- [ ] Add tests for `strata_core` extensions (string, datetime) — move from `strata_core` to `strata_ui` if not already done
- [ ] Add tests for `DioApiHandler._handleResponse` covering List, Map, String, and invalid response data paths
- [ ] Add tests for `StrataImage` covering network, file, asset, and SVG construction paths
- [ ] Add tests for `FlutterSecureSensitiveStorage` using `TestDefaultBinaryMessengerBinding` for platform channel mocking
- [ ] Add tests for any other coverage gaps identified by `dart test --coverage`
- [ ] Verify 100% coverage across all sub-packages
- [ ] Run `melos run test` to confirm all tests pass
