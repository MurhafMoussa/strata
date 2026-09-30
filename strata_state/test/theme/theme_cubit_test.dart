import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_state/strata_state.dart';

class MockStorage extends Mock implements Storage {}

void main() {
  late Storage storage;

  setUp(() {
    storage = MockStorage();
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.delete(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  group('ThemeConfigEntity', () {
    test(
        'defaultConfig should have light themeMode and false enableAutoSwitch',
        () {
      final config = ThemeConfigEntity.defaultConfig();
      expect(config.themeMode, equals(ThemeMode.light));
      expect(config.enableAutoSwitch, isFalse);
    });

    test('toJson and fromJson should serialize correctly', () {
      const config = ThemeConfigEntity(
        themeMode: ThemeMode.dark,
        enableAutoSwitch: true,
      );
      final json = config.toJson();
      final restored = ThemeConfigEntity.fromJson(json);

      expect(restored, equals(config));
    });
  });

  group('ThemeCubit', () {
    test('initial state defaults to defaultConfig', () {
      final cubit = ThemeCubit();
      expect(cubit.state, equals(ThemeConfigEntity.defaultConfig()));
      expect(cubit.isDarkMode, isFalse);
      cubit.close();
    });

    test('setThemeMode updates state correctly and adjusts autoSwitch', () {
      final cubit = ThemeCubit();
      cubit.setThemeMode(ThemeMode.dark);
      expect(cubit.state.themeMode, equals(ThemeMode.dark));
      expect(cubit.state.enableAutoSwitch, isFalse);
      expect(cubit.isDarkMode, isTrue);

      cubit.setThemeMode(ThemeMode.system);
      expect(cubit.state.themeMode, equals(ThemeMode.system));
      expect(cubit.state.enableAutoSwitch, isTrue);

      cubit.close();
    });

    test('setAutoSwitch updates state correctly', () {
      final cubit = ThemeCubit();
      cubit.setAutoSwitch(true);
      expect(cubit.state.enableAutoSwitch, isTrue);
      expect(cubit.state.themeMode, equals(ThemeMode.system));

      cubit.setAutoSwitch(false);
      expect(cubit.state.enableAutoSwitch, isFalse);
      cubit.close();
    });

    test('toggleTheme toggles light and dark modes', () {
      final cubit = ThemeCubit();
      expect(cubit.state.themeMode, equals(ThemeMode.light));

      cubit.toggleTheme();
      expect(cubit.state.themeMode, equals(ThemeMode.dark));

      cubit.toggleTheme();
      expect(cubit.state.themeMode, equals(ThemeMode.light));
      cubit.close();
    });

    test(
        'toggleTheme from system mode resolves against platform brightness',
        () {
      final cubit = ThemeCubit(
        initialConfig: const ThemeConfigEntity(
          themeMode: ThemeMode.system,
          enableAutoSwitch: true,
        ),
      );

      // System currently dark -> toggling sets light
      cubit.toggleTheme(platformBrightness: Brightness.dark);
      expect(cubit.state.themeMode, equals(ThemeMode.light));
      expect(cubit.state.enableAutoSwitch, isFalse);

      cubit.setThemeMode(ThemeMode.system);
      // System currently light -> toggling sets dark
      cubit.toggleTheme(platformBrightness: Brightness.light);
      expect(cubit.state.themeMode, equals(ThemeMode.dark));

      cubit.close();
    });

    test('didChangePlatformBrightness responds when enableAutoSwitch is true',
        () {
      final cubit = ThemeCubit(
        initialConfig: const ThemeConfigEntity(
          themeMode: ThemeMode.light,
          enableAutoSwitch: true,
        ),
      );

      cubit.didChangePlatformBrightness();
      expect(cubit.state.enableAutoSwitch, isTrue);

      cubit.close();
    });

    test('toJson and fromJson for cubit state persistence', () {
      final cubit = ThemeCubit();
      const config = ThemeConfigEntity(
        themeMode: ThemeMode.dark,
        enableAutoSwitch: false,
      );
      final json = cubit.toJson(config);
      final restored = cubit.fromJson(json!);

      expect(restored, equals(config));
      cubit.close();
    });

    test('fromJson returns null on malformed json', () {
      final cubit = ThemeCubit();
      final restored = cubit.fromJson({'themeMode': 123});
      expect(restored, isNull);
      cubit.close();
    });
  });
}
