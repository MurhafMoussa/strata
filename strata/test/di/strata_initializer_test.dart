import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:strata/strata.dart';

class _TestErrorResponseModel extends BaseErrorResponseModel {
  _TestErrorResponseModel()
      : super(
          status: 500,
          developerMessage: 'Error',
          timestamp: DateTime.now(),
        );

  @override
  Map<String, String> get validationErrors => {};
}

_TestErrorResponseModel _testErrorParser(dynamic response) =>
    _TestErrorResponseModel();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StrataInitializer', () {
    late GetIt getIt;

    setUp(() async {
      getIt = GetIt.asNewInstance();
    });

    tearDown(() async {
      await StrataInitializer.reset(getIt: getIt);
    });

    test('initialize registers sub-package dependencies and awaits allReady', () async {
      const networkConfig = NetworkConfigEntity(
        baseUrl: 'https://api.example.com',
        excludedPaths: ['/login'],
        refreshTokenApiEndpoint: '/refresh',
        accessTokenKey: 'access_token',
        refreshTokenKey: 'refresh_token',
      );

      const config = StrataConfigEntity(
        networkConfig: networkConfig,
        themeConfig: ThemeConfigEntity(
          themeMode: ThemeMode.system,
          enableAutoSwitch: false,
        ),
        localizationConfig: LocalizationConfigEntity(
          defaultLocale: Locale('en'),
          supportedLocales: [Locale('en')],
          localizationsDelegates: [],
        ),
        errorParser: _testErrorParser,
      );

      var isReadyResolved = false;

      // Register an async ready signal in getIt to test allReady awaiting
      getIt.registerSingletonAsync<bool>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        isReadyResolved = true;
        return true;
      });

      await StrataInitializer.initialize(config, getIt: getIt);

      expect(isReadyResolved, isTrue);
      expect(getIt.isRegistered<SensitiveStorageInterface>(), isTrue);
      expect(getIt.isRegistered<NetworkConfigEntity>(), isTrue);
      expect(getIt.isRegistered<ApiHandlerInterface>(), isTrue);
    });

    test('reset cleans up GetIt registrations between runs', () async {
      const config = StrataConfigEntity(
        networkConfig: NetworkConfigEntity(
          baseUrl: 'https://api.example.com',
          excludedPaths: [],
          refreshTokenApiEndpoint: '/refresh',
          accessTokenKey: 'access_token',
          refreshTokenKey: 'refresh_token',
        ),
        themeConfig: ThemeConfigEntity(
          themeMode: ThemeMode.system,
          enableAutoSwitch: false,
        ),
        localizationConfig: LocalizationConfigEntity(
          defaultLocale: Locale('en'),
          supportedLocales: [Locale('en')],
          localizationsDelegates: [],
        ),
        errorParser: _testErrorParser,
      );

      await StrataInitializer.initialize(config, getIt: getIt);
      expect(getIt.isRegistered<SensitiveStorageInterface>(), isTrue);

      await StrataInitializer.reset(getIt: getIt);
      expect(getIt.isRegistered<SensitiveStorageInterface>(), isFalse);
    });

    test('StrataConfigEntity supports equality comparison', () {
      const config1 = StrataConfigEntity(
        networkConfig: NetworkConfigEntity(
          baseUrl: 'https://api.example.com',
          excludedPaths: [],
          refreshTokenApiEndpoint: '/refresh',
          accessTokenKey: 'access_token',
          refreshTokenKey: 'refresh_token',
        ),
        themeConfig: ThemeConfigEntity(
          themeMode: ThemeMode.system,
          enableAutoSwitch: false,
        ),
        localizationConfig: LocalizationConfigEntity(
          defaultLocale: Locale('en'),
          supportedLocales: [Locale('en')],
          localizationsDelegates: [],
        ),
        errorParser: _testErrorParser,
      );
      const config2 = StrataConfigEntity(
        networkConfig: NetworkConfigEntity(
          baseUrl: 'https://api.example.com',
          excludedPaths: [],
          refreshTokenApiEndpoint: '/refresh',
          accessTokenKey: 'access_token',
          refreshTokenKey: 'refresh_token',
        ),
        themeConfig: ThemeConfigEntity(
          themeMode: ThemeMode.system,
          enableAutoSwitch: false,
        ),
        localizationConfig: LocalizationConfigEntity(
          defaultLocale: Locale('en'),
          supportedLocales: [Locale('en')],
          localizationsDelegates: [],
        ),
        errorParser: _testErrorParser,
      );

      expect(config1, equals(config2));
      expect(config1.props, isNotEmpty);
    });

    test('initialize and reset work with default GetIt.instance', () async {
      const config = StrataConfigEntity(
        networkConfig: NetworkConfigEntity(
          baseUrl: 'https://api.example.com',
          excludedPaths: [],
          refreshTokenApiEndpoint: '/refresh',
          accessTokenKey: 'access_token',
          refreshTokenKey: 'refresh_token',
        ),
        themeConfig: ThemeConfigEntity(
          themeMode: ThemeMode.system,
          enableAutoSwitch: false,
        ),
        localizationConfig: LocalizationConfigEntity(
          defaultLocale: Locale('en'),
          supportedLocales: [Locale('en')],
          localizationsDelegates: [],
        ),
        errorParser: _testErrorParser,
      );

      await StrataInitializer.reset();
      await StrataInitializer.initialize(config);
      expect(GetIt.instance.isRegistered<SensitiveStorageInterface>(), isTrue);
      await StrataInitializer.reset();
      expect(GetIt.instance.isRegistered<SensitiveStorageInterface>(), isFalse);
    });
  });
}
