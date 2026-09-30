import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_ui/strata_ui.dart';

class TestBuilderState {
  const TestBuilderState({required this.asyncState});
  final AsyncState<String> asyncState;

  TestBuilderState copyWith({AsyncState<String>? asyncState}) =>
      TestBuilderState(asyncState: asyncState ?? this.asyncState);
}

class TestBuilderCubit extends Cubit<TestBuilderState> {
  TestBuilderCubit()
      : super(const TestBuilderState(asyncState: AsyncState.initial()));

  void setState(AsyncState<String> newState) =>
      emit(state.copyWith(asyncState: newState));
}

void main() {
  group('AsyncBuilder Widget Tests', () {
    late TestBuilderCubit cubit;

    setUp(() {
      cubit = TestBuilderCubit();
    });

    tearDown(() {
      cubit.close();
    });

    Widget createWidgetUnderTest({
      Widget Function(BuildContext)? initialBuilder,
      Widget Function(BuildContext)? loadingBuilder,
      Widget Function(BuildContext, Failure, void Function()?)? errorBuilder,
      String? emptyEntity,
    }) {
      return MaterialApp(
        theme: ThemeData(
          splashFactory: NoSplash.splashFactory,
        ),
        home: Scaffold(
          body: AsyncBuilder<TestBuilderState, String>(
            bloc: cubit,
            getAsyncState: (state) => state.asyncState,
            emptyEntity: emptyEntity,
            initialBuilder: initialBuilder,
            loadingBuilder: loadingBuilder,
            errorBuilder: errorBuilder,
            successBuilder: (context, data) => Text('Success: $data'),
          ),
        ),
      );
    }

    testWidgets('renders initialBuilder when provided on AsyncStateInitial', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialBuilder: (_) => const Text('Initial State'),
      ));

      expect(find.text('Initial State'), findsOneWidget);
    });

    testWidgets('renders SizedBox shrink on AsyncStateInitial when initialBuilder is null', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('triggers buildWhen on state transition', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      cubit.setState(const AsyncState.success('Dynamic Update'));
      await tester.pumpAndSettle();

      expect(find.text('Success: Dynamic Update'), findsOneWidget);
    });

    testWidgets('renders CircularProgressIndicator on AsyncStateLoading when no loadingBuilder or emptyEntity provided', (tester) async {
      cubit.setState(const AsyncState.loading());
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders skeletonizer on AsyncStateLoading when emptyEntity is provided', (tester) async {
      cubit.setState(const AsyncState.loading());
      await tester.pumpWidget(createWidgetUnderTest(emptyEntity: 'Dummy Placeholder'));

      expect(find.text('Success: Dummy Placeholder'), findsOneWidget);
    });

    testWidgets('renders successBuilder on AsyncStateSuccess', (tester) async {
      cubit.setState(const AsyncState.success('Hello World'));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Success: Hello World'), findsOneWidget);
    });

    testWidgets('renders default error widget with retry button on AsyncStateFailure', (tester) async {
      var retried = false;
      cubit.setState(AsyncState.failure(
        const ServerFailure(message: 'Network Failed', statusCode: 500),
        retryFunction: () => retried = true,
      ));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Network Failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('renders custom errorBuilder when provided on AsyncStateFailure', (tester) async {
      cubit.setState(const AsyncState.failure(
        ServerFailure(message: 'Custom Error Message', statusCode: 500),
      ));

      await tester.pumpWidget(createWidgetUnderTest(
        errorBuilder: (context, failure, retry) => Text('Custom Error: ${failure.message}'),
      ));

      expect(find.text('Custom Error: Custom Error Message'), findsOneWidget);
    });
  });
}
