import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_state/strata_state.dart';

class MockPlatformServiceInterface extends Mock
    implements PlatformServiceInterface {}

class MockNetworkStatusInterface extends Mock
    implements NetworkStatusInterface {}

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

  group('StrataStateDiExtension Tests', () {
    test('registerStrataState executes without error', () {
      final getIt = GetIt.asNewInstance();
      getIt.registerStrataState();
      expect(getIt, isNotNull);
      expect(getIt.isRegistered<ThemeCubit>(), isTrue);
    });

    test('registerStrataState registers theme and localization configurations',
        () {
      final getIt = GetIt.asNewInstance();
      const themeConfig = ThemeConfigEntity(
        themeMode: ThemeMode.dark,
        enableAutoSwitch: true,
      );
      const locConfig = LocalizationConfigEntity(
        supportedLocales: [Locale('en'), Locale('ar')],
        localizationsDelegates: [],
        defaultLocale: Locale('en'),
      );

      getIt.registerStrataState(
        themeConfig: themeConfig,
        localizationConfig: locConfig,
      );

      expect(getIt.isRegistered<ThemeCubit>(), isTrue);
      expect(getIt.isRegistered<LocalizationCubit>(), isTrue);
      expect(getIt<ThemeCubit>().state.themeMode, equals(ThemeMode.dark));
      expect(getIt<LocalizationCubit>().state, equals(const Locale('en')));
    });

    test(
        'registerStrataState registers platform dependencies when service is provided',
        () {
      final getIt = GetIt.asNewInstance();
      final mockService = MockPlatformServiceInterface();

      getIt.registerStrataState(platformService: mockService);

      expect(getIt.isRegistered<PlatformServiceInterface>(), isTrue);
      expect(getIt.isRegistered<PlatformCubit>(), isTrue);
      expect(getIt.get<PlatformServiceInterface>(), equals(mockService));
    });

    test(
        'registerStrataState registers network dependencies when service is provided',
        () {
      final getIt = GetIt.asNewInstance();
      final mockNetwork = MockNetworkStatusInterface();
      when(() => mockNetwork.connectionStream)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);

      getIt.registerStrataState(networkStatus: mockNetwork);

      expect(getIt.isRegistered<NetworkStatusInterface>(), isTrue);
      expect(getIt.isRegistered<NetworkStatusCubit>(), isTrue);
      expect(getIt.get<NetworkStatusInterface>(), equals(mockNetwork));
    });

    test(
        'registerPlatformDependencies registers PlatformServiceInterface and PlatformCubit',
        () {
      final getIt = GetIt.asNewInstance();

      getIt.registerPlatformDependencies();

      expect(getIt.isRegistered<PlatformServiceInterface>(), isTrue);
      expect(getIt.isRegistered<PlatformCubit>(), isTrue);
      expect(getIt.get<PlatformServiceInterface>(), isA<PlatformServiceImpl>());
    });
  });
}
