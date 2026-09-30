import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_state/strata_state.dart';

class MockNetworkStatusInterface extends Mock
    implements NetworkStatusInterface {}

void main() {
  late MockNetworkStatusInterface mockNetworkStatus;
  late StreamController<ConnectionStatus> streamController;

  setUp(() {
    mockNetworkStatus = MockNetworkStatusInterface();
    streamController = StreamController<ConnectionStatus>.broadcast();
    when(() => mockNetworkStatus.connectionStream)
        .thenAnswer((_) => streamController.stream);
    when(() => mockNetworkStatus.isConnected).thenAnswer((_) async => true);
    when(() => mockNetworkStatus.dispose()).thenAnswer((_) async {});
  });

  tearDown(() {
    streamController.close();
  });

  group('NetworkStatusCubit', () {
    test('initial state is unknown and resolves to connected', () async {
      final cubit = NetworkStatusCubit(networkStatus: mockNetworkStatus);
      expect(cubit.state, equals(ConnectionStatus.unknown));
      expect(cubit.isUnknown, isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, equals(ConnectionStatus.connected));
      expect(cubit.isConnected, isTrue);
      expect(cubit.isDisconnected, isFalse);
      expect(cubit.isUnknown, isFalse);

      streamController.add(ConnectionStatus.disconnected);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, equals(ConnectionStatus.disconnected));
      expect(cubit.isConnected, isFalse);
      expect(cubit.isDisconnected, isTrue);

      streamController.add(ConnectionStatus.connected);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, equals(ConnectionStatus.connected));

      await cubit.close();
      verifyNever(() => mockNetworkStatus.dispose());
    });

    test('resolves to disconnected on startup when isConnected is false',
        () async {
      when(() => mockNetworkStatus.isConnected).thenAnswer((_) async => false);

      final cubit = NetworkStatusCubit(networkStatus: mockNetworkStatus);
      expect(cubit.state, equals(ConnectionStatus.unknown));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, equals(ConnectionStatus.disconnected));
      expect(cubit.isConnected, isFalse);
      expect(cubit.isDisconnected, isTrue);

      await cubit.close();
    });

    test('retains initial state when isConnected check throws', () async {
      when(() => mockNetworkStatus.isConnected)
          .thenThrow(Exception('Probe failed'));

      final cubit = NetworkStatusCubit(
        networkStatus: mockNetworkStatus,
        initialStatus: ConnectionStatus.connected,
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, equals(ConnectionStatus.connected));
      await cubit.close();
    });

    test('checkConnection triggers manual check and emits updated status',
        () async {
      when(() => mockNetworkStatus.isConnected).thenAnswer((_) async => true);

      final cubit = NetworkStatusCubit(
        networkStatus: mockNetworkStatus,
        initialStatus: ConnectionStatus.disconnected,
      );

      final status = await cubit.checkConnection();
      expect(status, equals(ConnectionStatus.connected));
      expect(cubit.state, equals(ConnectionStatus.connected));

      await cubit.close();
    });

    test('checkConnection catches exceptions and retains current state',
        () async {
      when(() => mockNetworkStatus.isConnected)
          .thenThrow(Exception('Network error'));

      final cubit = NetworkStatusCubit(
        networkStatus: mockNetworkStatus,
        initialStatus: ConnectionStatus.connected,
      );

      final status = await cubit.checkConnection();
      expect(status, equals(ConnectionStatus.connected));
      expect(cubit.state, equals(ConnectionStatus.connected));

      await cubit.close();
    });
  });
}
