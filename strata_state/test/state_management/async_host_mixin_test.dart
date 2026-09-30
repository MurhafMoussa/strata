import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_state/strata_state.dart';

class MockCancelRequestManager extends Mock
    implements CancelRequestManagerInterface {}

class TestCubitState {
  const TestCubitState({
    required this.userState,
  });

  final AsyncState<String> userState;

  TestCubitState copyWith({
    AsyncState<String>? userState,
  }) {
    return TestCubitState(
      userState: userState ?? this.userState,
    );
  }
}

class TestCubit extends Cubit<TestCubitState>
    with AsyncHostMixin<TestCubitState> {
  TestCubit({
    CancelRequestManagerInterface? cancelRequestManager,
    String? defaultRequestId,
  }) : super(const TestCubitState(userState: AsyncState.initial())) {
    userHandler = createAsyncHandler(
      getAsyncState: (state) => state.userState,
      setAsyncState: (state, asyncState) =>
          state.copyWith(userState: asyncState),
      cancelRequestManager: cancelRequestManager,
      defaultRequestId: defaultRequestId,
    );
  }

  late final AsyncHandler<TestCubitState, String> userHandler;

  Future<void> fetchUser(
    String id, {
    bool force = false,
    String? requestId,
  }) async {
    await userHandler.handleAsync(
      asyncCall: (params) async => right('User: $params'),
      params: id,
      force: force,
      requestId: requestId,
    );
  }
}

void main() {
  late MockCancelRequestManager mockCancelManager;

  setUp(() {
    mockCancelManager = MockCancelRequestManager();
  });

  group('AsyncHostMixin Unit Tests', () {
    test(
      'creates handler and executes handleAsync updating cubit state',
      () async {
        final cubit = TestCubit();

        expect(cubit.state.userState, isA<AsyncStateInitial<String>>());

        await cubit.fetchUser('123');

        expect(cubit.state.userState, isA<AsyncStateSuccess<String>>());
        expect(cubit.state.userState.dataOrNull, equals('User: 123'));

        await cubit.close();
      },
    );

    test('closing cubit automatically disposes registered handlers and cancels active requests', () async {
      when(() => mockCancelManager.cancelRequest(any(), reason: any(named: 'reason')))
          .thenReturn(null);

      final cubit = TestCubit(
        cancelRequestManager: mockCancelManager,
        defaultRequestId: 'cubit_default_id',
      );

      // Start an uncompleted async call
      cubit.userHandler.handleAsync<String>(
        asyncCall: (params) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return right('User');
        },
        params: '456',
      );

      expect(cubit.userHandler.currentRequestId, equals('cubit_default_id'));

      await cubit.close();

      verify(() => mockCancelManager.cancelRequest(
            'cubit_default_id',
            reason: 'AsyncHandler disposed',
          )).called(1);
      expect(cubit.userHandler.currentRequestId, isNull);
    });
  });
}
