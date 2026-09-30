# 05: Move `PlatformCubit` and `PlatformServiceImpl` to `strata_ui`

**What to build:** `strata_state` remains portable (no platform-specific code); `PlatformCubit` and `DeviceInfoPlatformService` live in `strata_ui` with proper DI registration.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Rename `PlatformServiceImpl` → `DeviceInfoPlatformService` (avoid `*Impl` suffix per GLOSSARY)
- [ ] Move `platform_cubit.dart` from `strata_state/lib/src/platform/` to `strata_ui/lib/src/platform/`
- [ ] Move `platform_service_impl.dart` → `device_info_platform_service.dart` from `strata_state/lib/src/platform/` to `strata_ui/lib/src/platform/`
- [ ] Update `strata_state.dart` barrel export to remove both types
- [ ] Update `strata_ui.dart` barrel export to add both types
- [ ] Remove `device_info_plus` and `package_info_plus` from `strata_state/pubspec.yaml`
- [ ] Add `device_info_plus` and `package_info_plus` to `strata_ui/pubspec.yaml`
- [ ] Fill `strata_ui_di.dart` with `PlatformCubit` and `DeviceInfoPlatformService` registration (replacing the empty `registerStrataUi()` extension)
- [ ] Update `strata_state_di.dart` to remove `registerPlatformDependencies` (moved to `strata_ui`)
- [ ] Update all imports across the codebase
- [ ] Move and update `platform_cubit_test.dart` and `platform_service_impl_test.dart`
- [ ] Run `dart analyze` and `dart test` in both `strata_state` and `strata_ui`
