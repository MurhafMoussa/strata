import 'package:fpdart/fpdart.dart';
import 'package:strata_core/strata_core.dart';
import 'package:test/test.dart';

void main() {
  group('AsyncState<T>', () {
    test('initial state assertions and getters', () {
      const state = AsyncState<String>.initial();

      expect(state.isInitial, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isFailure, isFalse);

      expect(state.data, equals(none<String>()));
      expect(state.dataOrNull, isNull);
      expect(state.failureObject, equals(none<Failure>()));
      expect(state.failureOrNull, isNull);
      expect(state.retryFunction, isNull);

      expect(state.props, isEmpty);
    });

    test('loading state assertions and getters', () {
      const state = AsyncState<String>.loading();

      expect(state.isInitial, isFalse);
      expect(state.isLoading, isTrue);
      expect(state.isSuccess, isFalse);
      expect(state.isFailure, isFalse);

      expect(state.data, equals(none<String>()));
      expect(state.dataOrNull, isNull);
      expect(state.failureObject, equals(none<Failure>()));
      expect(state.retryFunction, isNull);

      expect(state.props, isEmpty);
    });

    test('success state assertions and getters', () {
      const state = AsyncState<String>.success('Hello World');

      expect(state.isInitial, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isTrue);
      expect(state.isFailure, isFalse);

      expect(state.data, equals(some('Hello World')));
      expect(state.dataOrNull, equals('Hello World'));
      expect(state.failureObject, equals(none<Failure>()));
      expect(state.retryFunction, isNull);

      expect(state.props, equals(['Hello World']));
    });

    test('failure state assertions and getters', () {
      void dummyRetry() {}
      const failure = StorageFailure(message: 'Disk error');
      final state = AsyncState<String>.failure(failure, retryFunction: dummyRetry);

      expect(state.isInitial, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isFailure, isTrue);

      expect(state.data, equals(none<String>()));
      expect(state.dataOrNull, isNull);
      expect(state.failureObject, equals(some(failure)));
      expect(state.failureOrNull, equals(failure));
      expect(state.retryFunction, equals(dummyRetry));

      expect(state.props, equals([failure, dummyRetry]));
    });

    group('pattern matching (when / maybeWhen)', () {
      test('when invokes matching callback for all cases', () {
        const initial = AsyncState<int>.initial();
        const loading = AsyncState<int>.loading();
        const success = AsyncState<int>.success(42);
        const failure = AsyncState<int>.failure(UnknownFailure(message: 'err'));

        String evaluate(AsyncState<int> state) {
          return state.when(
            initial: () => 'initial',
            loading: () => 'loading',
            success: (d) => 'success:$d',
            failure: (f, fn) => 'failure:${f.message}',
          );
        }

        expect(evaluate(initial), equals('initial'));
        expect(evaluate(loading), equals('loading'));
        expect(evaluate(success), equals('success:42'));
        expect(evaluate(failure), equals('failure:err'));
      });

      test('maybeWhen falls back to orElse or executes specified callback', () {
        const success = AsyncState<int>.success(100);
        const loading = AsyncState<int>.loading();

        final resultSuccess = success.maybeWhen(
          success: (d) => d * 2,
          orElse: () => -1,
        );
        final resultLoading = loading.maybeWhen(
          success: (d) => d * 2,
          orElse: () => -1,
        );

        expect(resultSuccess, equals(200));
        expect(resultLoading, equals(-1));
      });

      test('maybeWhen executes initial/loading/failure callbacks when supplied', () {
        const initial = AsyncState<int>.initial();
        const loading = AsyncState<int>.loading();
        const failure = AsyncState<int>.failure(UnknownFailure(message: 'err'));

        expect(
          initial.maybeWhen(initial: () => 'init', orElse: () => 'other'),
          equals('init'),
        );
        expect(
          loading.maybeWhen(loading: () => 'load', orElse: () => 'other'),
          equals('load'),
        );
        expect(
          failure.maybeWhen(
            failure: (f, r) => 'fail',
            orElse: () => 'other',
          ),
          equals('fail'),
        );
      });

      test('maybeWhen falls back to orElse for initial state', () {
        const initial = AsyncState<int>.initial();

        final result = initial.maybeWhen(
          orElse: () => 'orElse',
        );

        expect(result, equals('orElse'));
      });
    });
  });
}
