## ACT Workflow

ACT workflow storage for new Specs is configured in `.act/config.yaml`.

ACT workflow semantics, Workflow Storage selection, artifact vocabulary, and domain-doc guidance are defined in `.act/workflow.md`.

## Multi-Package & Monorepo Rules
- **Sub-package Directory Commands**: Always run analysis and tests in the specific sub-package directory (e.g. `workdir: strata_core` using `dart analyze` and `dart test`).
- **Dependency Boundaries**: Sub-packages must adhere strictly to their defined boundaries. For example, `strata_core` must never import Flutter or third-party UI/network packages.
- **Boundary Verification**: Run package boundary audit tests (`package_dependency_test.dart`) whenever modifying package dependencies or imports.
- **100% Test Coverage Requirement**: All sub-packages (`strata_core`, `strata_network`, `strata_state`, `strata_ui`, etc.) must achieve and maintain 100% test coverage across all public APIs, BLoCs, cubits, state classes, strategies, and utilities using `bloc_test` and shared test helpers (`*_test_helpers.dart`).
- **Domain Conventions**: Refer to `GLOSSARY.md` for canonical naming (`AsyncState`, `SensitiveStorageInterface`, `*Interface` suffix rule).
