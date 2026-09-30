import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_state/strata_state.dart';

class MockCancelRequestManager extends Mock
    implements CancelRequestManagerInterface {}

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

class TestPaginationParams implements PaginationParamsInterface {
  const TestPaginationParams(this.requestId);

  @override
  final String requestId;
}

void main() {
  late MockCancelRequestManager mockCancelManager;
  late TestCompositeState currentState;
  late List<TestCompositeState> emittedStates;
  late bool isClosed;

  late AsyncHandler<TestCompositeState, String> handler;

  setUp(() async {
    await GetIt.I.reset();
    mockCancelManager = MockCancelRequestManager();
    currentState = const TestCompositeState(dataState: AsyncState.initial());
    emittedStates = [];
    isClosed = false;

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
      cancelRequestManager: mockCancelManager,
      defaultRequestId: 'default_handler_id',
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

    test('execute convenience method executes parameterless async call', () async {
      String? successData;

      await handler.execute(
        asyncCall: () async => right('Executed Data'),
        onSuccess: (data) => successData = data,
      );

      expect(emittedStates.length, equals(2));
      expect(emittedStates[0].dataState, isA<AsyncStateLoading<String>>());
      expect(emittedStates[1].dataState, isA<AsyncStateSuccess<String>>());
      expect(currentState.dataState.dataOrNull, equals('Executed Data'));
      expect(successData, equals('Executed Data'));
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

    test('handleAsync(force: false) skips execution during isLoading state', () async {
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
    });

    test('handleAsync(force: true) executes async call during isLoading state and cancels prior request', () async {
      currentState = const TestCompositeState(dataState: AsyncState.loading());
      var executed = false;

      when(() => mockCancelManager.cancelRequest(any(), reason: any(named: 'reason')))
          .thenReturn(null);

      // Start an in-flight uncompleted request
      handler.handleAsync<String>(
        asyncCall: (params) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return right('slow data');
        },
        params: 'param',
        requestId: 'in_flight_123',
        force: true,
      );

      expect(handler.currentRequestId, equals('in_flight_123'));

      // New forced call supersedes the in-flight one
      await handler.handleAsync<String>(
        asyncCall: (params) async {
          executed = true;
          return right('Force Loaded Data');
        },
        params: 'param',
        requestId: 'new_req_456',
        force: true,
      );

      expect(executed, isTrue);
      expect(currentState.dataState.dataOrNull, equals('Force Loaded Data'));
      verify(() => mockCancelManager.cancelRequest(
            'in_flight_123',
            reason: 'Superseded by new async call',
          )).called(1);
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

    test('handleAsync defaults to defaultRequestId when no explicit requestId is passed', () async {
      await handler.handleAsync<String>(
        asyncCall: (params) async {
          expect(handler.currentRequestId, equals('default_handler_id'));
          return right('data');
        },
        params: 'param',
      );

      expect(handler.currentRequestId, isNull);
    });

    test('handleAsync extracts requestId from PaginationParamsInterface when requestId is null', () async {
      final noDefaultHandler = AsyncHandler<TestCompositeState, String>(
        emit: (s) => currentState = s,
        getState: () => currentState,
        isClosed: () => isClosed,
        getAsyncState: (s) => s.dataState,
        setAsyncState: (s, asyncState) => s.copyWith(dataState: asyncState),
        cancelRequestManager: mockCancelManager,
      );

      const paginationParams = TestPaginationParams('page_req_999');

      await noDefaultHandler.handleAsync<TestPaginationParams>(
        asyncCall: (params) async {
          expect(noDefaultHandler.currentRequestId, equals('page_req_999'));
          return right('data');
        },
        params: paginationParams,
      );

      expect(noDefaultHandler.currentRequestId, isNull);
    });

    test('handleAsync allows execution when effective requestId is null', () async {
      final noIdHandler = AsyncHandler<TestCompositeState, String>(
        emit: (s) => currentState = s,
        getState: () => currentState,
        isClosed: () => isClosed,
        getAsyncState: (s) => s.dataState,
        setAsyncState: (s, asyncState) => s.copyWith(dataState: asyncState),
      );

      await noIdHandler.handleAsync<String>(
        asyncCall: (params) async {
          expect(noIdHandler.currentRequestId, isNull);
          return right('data');
        },
        params: 'param',
      );

      expect(noIdHandler.currentRequestId, isNull);
    });

    test('cancelRequest invokes cancelRequestManager and clears currentRequestId', () async {
      when(() => mockCancelManager.cancelRequest(any(), reason: any(named: 'reason')))
          .thenReturn(null);

      handler.handleAsync<String>(
        asyncCall: (params) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return right('data');
        },
        params: 'param',
        requestId: 'request_456',
      );

      expect(handler.currentRequestId, equals('request_456'));
      handler.cancelRequest(reason: 'User left screen');

      verify(() => mockCancelManager.cancelRequest(
            'request_456',
            reason: 'User left screen',
          )).called(1);
      expect(handler.currentRequestId, isNull);
    });

    test('cancelRequest does nothing if currentRequestId is null', () {
      handler.cancelRequest();
      verifyNever(() => mockCancelManager.cancelRequest(any(), reason: any(named: 'reason')));
    });

    test('dispose invokes cancelRequest with default disposed reason', () {
      when(() => mockCancelManager.cancelRequest(any(), reason: any(named: 'reason')))
          .thenReturn(null);

      handler.handleAsync<String>(
        asyncCall: (params) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return right('data');
        },
        params: 'param',
        requestId: 'request_789',
      );

      handler.dispose();
      verify(() => mockCancelManager.cancelRequest(
            'request_789',
            reason: 'AsyncHandler disposed',
          )).called(1);
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

    test('falls back to GetIt CancelRequestManagerInterface if constructor manager is null', () async {
      GetIt.I.registerSingleton<CancelRequestManagerInterface>(mockCancelManager);
      when(() => mockCancelManager.cancelRequest(any(), reason: any(named: 'reason')))
          .thenReturn(null);

      final noManagerHandler = AsyncHandler<TestCompositeState, String>(
        emit: (s) => currentState = s,
        getState: () => currentState,
        isClosed: () => isClosed,
        getAsyncState: (s) => s.dataState,
        setAsyncState: (s, asyncState) => s.copyWith(dataState: asyncState),
      );

      noManagerHandler.handleAsync<String>(
        asyncCall: (params) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return right('data');
        },
        params: 'param',
        requestId: 'getit_req_1',
      );

      noManagerHandler.cancelRequest();
      verify(() => mockCancelManager.cancelRequest(
            'getit_req_1',
            reason: 'Request cancelled by AsyncHandler',
          )).called(1);
    });

    test('handles cancelRequest gracefully when no manager is provided or registered', () {
      final unmanagedHandler = AsyncHandler<TestCompositeState, String>(
        emit: (s) => currentState = s,
        getState: () => currentState,
        isClosed: () => isClosed,
        getAsyncState: (s) => s.dataState,
        setAsyncState: (s, asyncState) => s.copyWith(dataState: asyncState),
      );

      unmanagedHandler.handleAsync<String>(
        asyncCall: (params) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return right('data');
        },
        params: 'param',
        requestId: 'req_unmanaged',
      );

      expect(() => unmanagedHandler.cancelRequest(), returnsNormally);
      expect(unmanagedHandler.currentRequestId, isNull);
    });
  });
}
