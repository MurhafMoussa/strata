# 05: Move `PlatformCubit` and `PlatformServiceImpl` to `strata_ui`

**What to build:** `strata_state` remains portable (no platform-specific code); `PlatformCubit` and `DeviceInfoPlatformService` live in `strata_ui` with proper DI registration.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Rename `PlatformServiceImpl` → `DeviceInfoPlatformService` (avoid `*Impl` suffix per GLOSSARY)
- [x] Move `platform_cubit.dart` from `strata_state/lib/src/platform/` to `strata_ui/lib/src/platform/`
- [x] Move `platform_service_impl.dart` → `device_info_platform_service.dart` from `strata_state/lib/src/platform/` to `strata_ui/lib/src/platform/`
- [x] Update `strata_state.dart` barrel export to remove both types
- [x] Update `strata_ui.dart` barrel export to add both types
- [x] Remove `device_info_plus` and `package_info_plus` from `strata_state/pubspec.yaml`
- [x] Add `device_info_plus` and `package_info_plus` to `strata_ui/pubspec.yaml`
- [x] Fill `strata_ui_di.dart` with `PlatformCubit` and `DeviceInfoPlatformService` registration (replacing the empty `registerStrataUi()` extension)
- [x] Update `strata_state_di.dart` to remove `registerPlatformDependencies` (moved to `strata_ui`)
- [x] Update all imports across the codebase
- [x] Move and update `platform_cubit_test.dart` and `platform_service_impl_test.dart`
- [x] Run `dart analyze` and `dart test` in both `strata_state` and `strata_ui`
