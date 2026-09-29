import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../config/theme_config_entity.dart';

/// Persistent Hydrated Cubit for theme state management.
class ThemeCubit({
  ThemeConfigEntity? initialConfig,
}) extends HydratedCubit<ThemeConfigEntity> with WidgetsBindingObserver {
  this : super(initialConfig ?? ThemeConfigEntity.defaultConfig()) {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
  }

  /// Whether current active mode resolves to dark.
  bool get isDarkMode {
    if (state.themeMode == ThemeMode.dark) return true;
    if (state.themeMode == ThemeMode.light) return false;
    return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
  }

  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(
      themeMode: mode,
      enableAutoSwitch: mode == ThemeMode.system,
    ));
  }

  void setAutoSwitch(bool enable) {
    emit(state.copyWith(
      enableAutoSwitch: enable,
      themeMode: enable ? ThemeMode.system : state.themeMode,
    ));
  }

  void toggleTheme({Brightness? platformBrightness}) {
    final Brightness brightness = platformBrightness ??
        PlatformDispatcher.instance.platformBrightness;

    final bool isDark = switch (state.themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => brightness == Brightness.dark,
    };

    final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
    emit(state.copyWith(themeMode: nextMode, enableAutoSwitch: false));
  }

  @override
  void didChangePlatformBrightness() {
    if (state.enableAutoSwitch && !isClosed) {
      final brightness = PlatformDispatcher.instance.platformBrightness;
      final targetMode = brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light;
      if (state.themeMode != targetMode) {
        emit(state.copyWith(themeMode: targetMode));
      }
    }
  }

  @override
  Future<void> close() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    return super.close();
  }

  @override
  ThemeConfigEntity? fromJson(Map<String, dynamic> json) {
    try {
      return ThemeConfigEntity.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(ThemeConfigEntity state) {
    return state.toJson();
  }
}
