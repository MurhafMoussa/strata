import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_state/strata_state.dart';

class MockStrataLogger extends Mock implements StrataLoggerInterface {}

class TestCompositeState {
  const TestCompositeState({
    required this.dataState,
  });

  final AsyncState<String> dataState;

  TestCompositeState copyWith({
    AsyncState<String>? dataState,
  }) {
    return TestCompositeState(
      dataState: dataState ?? this.dataState,
    );
  }
}

void main() {
  late MockStrataLogger mockLogger;
  late TestCompositeState currentState;
  late List<TestCompositeState> emittedStates;
  late bool isClosed;
  late String? cancelledRequestId;

  late AsyncHandler<TestCompositeState, String> handler;

  setUp(() async {
    await GetIt.I.reset();
    mockLogger = MockStrataLogger();
    currentState = const TestCompositeState(dataState: AsyncState.initial());
    emittedStates = [];
    isClosed = false;
    cancelledRequestId = null;

    handler = AsyncHandler<TestCompositeState, String>(
      emit: (state) {
        currentState = state;
        emittedStates.add(state);
      },
      getState: () => currentState,
      isClosed: () => isClosed,
      getAsyncState: (state) => state.dataState,
      setAsyncState: (state, asyncState) =>
          state.copyWith(dataState: asyncState),
      logger: mockLogger,
      onCancelRequest: (reqId) {
        cancelledRequestId = reqId;
      },
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('AsyncHandler Unit Tests', () {
    test('handleAsync executes successfully and emits loading then success', () async {
      String? successData;

      await handler.handleAsync<String>(
        asyncCall: (params) async => right('Fetched Data: $params'),
        params: 'test_param',
        onSuccess: (data) => successData = data,
      );

      expect(emittedStates.length, equals(2));
      expect(emittedStates[0].dataState, isA<AsyncStateLoading<String>>());
      expect(emittedStates[1].dataState, isA<AsyncStateSuccess<String>>());
      expect(currentState.dataState.dataOrNull, equals('Fetched Data: test_param'));
      expect(successData, equals('Fetched Data: test_param'));
    });

    test('handleAsyncCall alias executes identically to handleAsync', () async {
      String? successData;

      await handler.handleAsyncCall<String>(
        asyncCall: (params) async => right('Fetched Data: $params'),
        params: 'test_param',
        onSuccess: (data) => successData = data,
      );

      expect(emittedStates.length, equals(2));
      expect(emittedStates[0].dataState, isA<AsyncStateLoading<String>>());
      expect(emittedStates[1].dataState, isA<AsyncStateSuccess<String>>());
      expect(currentState.dataState.dataOrNull, equals('Fetched Data: test_param'));
      expect(successData, equals('Fetched Data: test_param'));
    });

    test('handleAsync handles failure, emits failure, and provides working retryFunction', () async {
      Failure? capturedFailure;
      const failure = ServerFailure(message: 'Server Error', statusCode: 500);

      await handler.handleAsync<String>(
        asyncCall: (params) async => left(failure),
        params: 'test_param',
        onFailure: (f) => capturedFailure = f,
      );

      expect(emittedStates.length, equals(2));
      expect(emittedStates[0].dataState, isA<AsyncStateLoading<String>>());
      expect(emittedStates[1].dataState, isA<AsyncStateFailure<String>>());
      expect(capturedFailure, equals(failure));

      final failureState = currentState.dataState as AsyncStateFailure<String>;
      expect(failureState.retryFunction, isNotNull);

      // Reset currentState for retry
      currentState = const TestCompositeState(dataState: AsyncState.initial());
      emittedStates.clear();

      failureState.retryFunction!();
      await Future<void>.delayed(Duration.zero);

      expect(emittedStates.length, equals(2));
      expect(emittedStates[1].dataState, isA<AsyncStateFailure<String>>());
    });

    test('handleAsync(force: false) skips execution during isLoading state and logs diagnostic warning', () async {
      currentState = const TestCompositeState(dataState: AsyncState.loading());
      var executed = false;

      await handler.handleAsync<String>(
        asyncCall: (params) async {
          executed = true;
          return right('data');
        },
        params: 'param',
        force: false,
      );

      expect(executed, isFalse);
      expect(emittedStates, isEmpty);
      verify(() => mockLogger.warning(any(that: contains('skipped because state is already loading')))).called(1);
    });

    test('handleAsync(force: true) executes async call even during isLoading state', () async {
      currentState = const TestCompositeState(dataState: AsyncState.loading());
      var executed = false;

      await handler.handleAsync<String>(
        asyncCall: (params) async {
          executed = true;
          return right('Force Loaded Data');
        },
        params: 'param',
        force: true,
      );

      expect(executed, isTrue);
      expect(emittedStates.length, equals(2));
      expect(currentState.dataState.dataOrNull, equals('Force Loaded Data'));
      verifyNever(() => mockLogger.warning(any()));
    });

    test('handleAsync tracks requestId and cleans up after completion', () async {
      await handler.handleAsync<String>(
        asyncCall: (params) async {
          expect(handler.currentRequestId, equals('request_123'));
          return right('data');
        },
        params: 'param',
        requestId: 'request_123',
      );

      expect(handler.currentRequestId, isNull);
    });

    test('cancelRequest invokes onCancelRequest and clears currentRequestId', () async {
      handler.handleAsync<String>(
        asyncCall: (params) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return right('data');
        },
        params: 'param',
        requestId: 'request_456',
      );

      expect(handler.currentRequestId, equals('request_456'));
      handler.cancelRequest();

      expect(cancelledRequestId, equals('request_456'));
      expect(handler.currentRequestId, isNull);
    });

    test('dispose invokes cancelRequest', () {
      handler.handleAsync<String>(
        asyncCall: (params) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return right('data');
        },
        params: 'param',
        requestId: 'request_789',
      );

      handler.dispose();
      expect(cancelledRequestId, equals('request_789'));
    });

    test('does not emit state if isClosed returns true when asyncCall resolves', () async {
      await handler.handleAsync<String>(
        asyncCall: (params) async {
          isClosed = true;
          return right('data');
        },
        params: 'param',
      );

      expect(emittedStates.length, equals(1)); // Only loading emitted before asyncCall completed
      expect(emittedStates[0].dataState, isA<AsyncStateLoading<String>>());
    });

    test('falls back to GetIt logger if constructor logger is null', () async {
      GetIt.I.registerSingleton<StrataLoggerInterface>(mockLogger);

      final noLoggerHandler = AsyncHandler<TestCompositeState, String>(
        emit: (s) => currentState = s,
        getState: () => currentState,
        isClosed: () => isClosed,
        getAsyncState: (s) => s.dataState,
        setAsyncState: (s, asyncState) => s.copyWith(dataState: asyncState),
      );

      currentState = const TestCompositeState(dataState: AsyncState.loading());

      await noLoggerHandler.handleAsync<String>(
        asyncCall: (params) async => right('data'),
        params: 'param',
        force: false,
      );

      verify(() => mockLogger.warning(any(that: contains('skipped because state is already loading')))).called(1);
    });
  });
}
