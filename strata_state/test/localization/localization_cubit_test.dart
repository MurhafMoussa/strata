import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_state/strata_state.dart';

class MockStorage extends Mock implements Storage {}

void main() {
  late Storage storage;
  late LocalizationConfigEntity config;

  setUp(() {
    storage = MockStorage();
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.delete(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = storage;

    config = const LocalizationConfigEntity(
      supportedLocales: [Locale('en'), Locale('ar')],
      localizationsDelegates: [],
      defaultLocale: Locale('en'),
    );
  });

  group('LocalizationConfigEntity', () {
    test('findSupportedLocale and isSupported match exact and language codes',
        () {
      expect(config.findSupportedLocale(const Locale('en')),
          equals(const Locale('en')));
      expect(config.findSupportedLocale(const Locale('ar', 'EG')),
          equals(const Locale('ar', 'EG')));
      expect(config.isSupported(const Locale('ar')), isTrue);
      expect(config.isSupported(const Locale('ar', 'SA')), isTrue);
      expect(config.isSupported(const Locale('de')), isFalse);
    });
  });

  group('LocalizationCubit', () {
    test('initial state defaults to config defaultLocale', () {
      final cubit = LocalizationCubit(config: config);
      expect(cubit.state, equals(const Locale('en')));
      expect(cubit.delegates, equals(config.localizationsDelegates));
      expect(cubit.supportedLocales, equals(config.supportedLocales));
      expect(cubit.isRtl, isFalse);
      expect(cubit.textDirection, equals(TextDirection.ltr));
    });

    test('initial state uses supported initialLocale when provided', () {
      final cubit = LocalizationCubit(
        config: config,
        initialLocale: const Locale('ar'),
      );
      expect(cubit.state, equals(const Locale('ar')));
      expect(cubit.isRtl, isTrue);
      expect(cubit.textDirection, equals(TextDirection.rtl));
    });

    test('initial state falls back to defaultLocale if initialLocale unsupported',
        () {
      final cubit = LocalizationCubit(
        config: config,
        initialLocale: const Locale('de'),
      );
      expect(cubit.state, equals(const Locale('en')));
    });

    test('changeLanguage updates locale when supported', () async {
      final cubit = LocalizationCubit(config: config);
      await cubit.changeLanguage(const Locale('ar'));
      expect(cubit.state, equals(const Locale('ar')));
      expect(cubit.isRtl, isTrue);
      expect(cubit.textDirection, equals(TextDirection.rtl));
    });

    test('changeLanguage matches language code fallback for dialects', () async {
      final cubit = LocalizationCubit(config: config);
      await cubit.changeLanguage(const Locale('ar', 'EG'));
      expect(cubit.state, equals(const Locale('ar', 'EG')));
    });

    test('changeLanguage ignores unsupported locales', () async {
      final cubit = LocalizationCubit(config: config);
      await cubit.changeLanguage(const Locale('fr'));
      expect(cubit.state, equals(const Locale('en')));
    });

    test('changeLanguage ignores when already in requested state', () async {
      final cubit = LocalizationCubit(config: config);
      await cubit.changeLanguage(const Locale('en'));
      expect(cubit.state, equals(const Locale('en')));
    });

    test('resolveDeviceLocale matches system locale or falls back', () {
      final resolved = LocalizationCubit.resolveDeviceLocale(
        config,
        const Locale('ar', 'AE'),
      );
      expect(resolved, equals(const Locale('ar', 'AE')));

      final fallback = LocalizationCubit.resolveDeviceLocale(
        config,
        const Locale('ja'),
      );
      expect(fallback, equals(const Locale('en')));
    });

    test('toJson and fromJson for locale persistence', () {
      final cubit = LocalizationCubit(config: config);
      const locale = Locale('ar', 'SA');
      final json = cubit.toJson(locale);
      final restored = cubit.fromJson(json!);

      expect(restored, equals(locale));
    });

    test('fromJson returns null for malformed locale data', () {
      final cubit = LocalizationCubit(config: config);
      expect(cubit.fromJson({}), isNull);
      expect(cubit.fromJson({'languageCode': ''}), isNull);
    });
  });
}
