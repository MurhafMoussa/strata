import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_state/strata_state.dart';

class MockStorage extends Mock implements Storage {}

class MockNetworkStatusInterface extends Mock
    implements NetworkStatusInterface {}

void main() {
  late Storage storage;
  late MockNetworkStatusInterface mockNetworkStatus;

  setUp(() {
    storage = MockStorage();
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.delete(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = storage;

    mockNetworkStatus = MockNetworkStatusInterface();
    when(() => mockNetworkStatus.connectionStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockNetworkStatus.isConnected).thenAnswer((_) async => true);
    when(() => mockNetworkStatus.dispose()).thenAnswer((_) async {});
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('Wrapper Widgets Tests in strata_state', () {
    testWidgets('ThemeWrapper provides ThemeCubit and does not close it on unmount',
        (tester) async {
      final themeCubit = ThemeCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: ThemeWrapper(
            themeCubit: themeCubit,
            builder: (context, themeConfig) {
              return Text('ThemeMode: ${themeConfig.themeMode}');
            },
          ),
        ),
      );

      expect(find.text('ThemeMode: ThemeMode.light'), findsOneWidget);

      // Unmount the widget tree
      await tester.pumpWidget(const SizedBox.shrink());

      // Cubit must remain open (not closed by unmount)
      expect(themeCubit.isClosed, isFalse);
      themeCubit.setThemeMode(ThemeMode.dark);
      expect(themeCubit.state.themeMode, equals(ThemeMode.dark));

      await themeCubit.close();
    });

    testWidgets('ThemeWrapper resolves ThemeCubit from GetIt when not passed',
        (tester) async {
      final cubit = ThemeCubit();
      GetIt.I.registerSingleton<ThemeCubit>(cubit);

      await tester.pumpWidget(
        MaterialApp(
          home: ThemeWrapper(
            builder: (context, themeConfig) {
              return Text('ThemeMode: ${themeConfig.themeMode}');
            },
          ),
        ),
      );

      expect(find.text('ThemeMode: ThemeMode.light'), findsOneWidget);
      await cubit.close();
    });

    testWidgets(
        'LocalizationWrapper provides LocalizationCubit and does not close it on unmount',
        (tester) async {
      const config = LocalizationConfigEntity(
        supportedLocales: [Locale('en'), Locale('ar')],
        localizationsDelegates: [],
        defaultLocale: Locale('en'),
      );
      final localizationCubit = LocalizationCubit(config: config);

      await tester.pumpWidget(
        MaterialApp(
          home: LocalizationWrapper(
            localizationCubit: localizationCubit,
            builder: (context, locale) {
              return Text('Locale: ${locale.languageCode}');
            },
          ),
        ),
      );

      expect(find.text('Locale: en'), findsOneWidget);

      // Unmount the widget tree
      await tester.pumpWidget(const SizedBox.shrink());

      // Cubit must remain open
      expect(localizationCubit.isClosed, isFalse);
      await localizationCubit.changeLanguage(const Locale('ar'));
      expect(localizationCubit.state.languageCode, equals('ar'));

      await localizationCubit.close();
    });

    testWidgets(
        'LocalizationWrapper resolves LocalizationCubit from GetIt when not passed',
        (tester) async {
      const config = LocalizationConfigEntity(
        supportedLocales: [Locale('en'), Locale('ar')],
        localizationsDelegates: [],
        defaultLocale: Locale('en'),
      );
      final localizationCubit = LocalizationCubit(config: config);
      GetIt.I.registerSingleton<LocalizationCubit>(localizationCubit);

      await tester.pumpWidget(
        MaterialApp(
          home: LocalizationWrapper(
            builder: (context, locale) {
              return Text('Locale: ${locale.languageCode}');
            },
          ),
        ),
      );

      expect(find.text('Locale: en'), findsOneWidget);
      await localizationCubit.close();
    });

    testWidgets(
        'NetworkStatusWrapper provides NetworkStatusCubit, invokes builder, and does not close it on unmount',
        (tester) async {
      final streamController = StreamController<ConnectionStatus>.broadcast();
      when(() => mockNetworkStatus.connectionStream)
          .thenAnswer((_) => streamController.stream);

      var connectedCalled = 0;
      var disconnectedCalled = 0;
      ConnectionStatus? latestStatus;

      final networkCubit = NetworkStatusCubit(
        networkStatus: mockNetworkStatus,
        initialStatus: ConnectionStatus.connected,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NetworkStatusWrapper(
            networkStatusCubit: networkCubit,
            onConnect: () => connectedCalled++,
            onDisconnect: () => disconnectedCalled++,
            onStatusChange: (status) => latestStatus = status,
            builder: (context, status, child) {
              return Column(
                children: [
                  Text('Status: ${status.name}'),
                  child,
                ],
              );
            },
            child: const Text('App Main Screen'),
          ),
        ),
      );

      expect(find.text('App Main Screen'), findsOneWidget);
      expect(find.text('Status: connected'), findsOneWidget);

      // Emit disconnected
      streamController.add(ConnectionStatus.disconnected);
      await tester.pumpAndSettle();

      expect(disconnectedCalled, equals(1));
      expect(latestStatus, equals(ConnectionStatus.disconnected));
      expect(find.text('Status: disconnected'), findsOneWidget);

      // Emit connected
      streamController.add(ConnectionStatus.connected);
      await tester.pumpAndSettle();

      expect(connectedCalled, equals(1));
      expect(latestStatus, equals(ConnectionStatus.connected));
      expect(find.text('Status: connected'), findsOneWidget);

      // Unmount
      await tester.pumpWidget(const SizedBox.shrink());
      expect(networkCubit.isClosed, isFalse);

      await networkCubit.close();
      await streamController.close();
    });

    testWidgets(
        'NetworkStatusWrapper resolves NetworkStatusCubit from GetIt when not passed',
        (tester) async {
      final networkCubit = NetworkStatusCubit(networkStatus: mockNetworkStatus);
      GetIt.I.registerSingleton<NetworkStatusCubit>(networkCubit);

      await tester.pumpWidget(
        MaterialApp(
          home: NetworkStatusWrapper(
            child: const Text('From GetIt'),
          ),
        ),
      );

      expect(find.text('From GetIt'), findsOneWidget);
      await networkCubit.close();
    });
  });
}
