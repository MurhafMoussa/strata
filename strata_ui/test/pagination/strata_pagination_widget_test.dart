import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_state/strata_state.dart';
import 'package:strata_ui/strata_ui.dart';

class TestItem implements Identifiable<String> {
  const TestItem({required this.id, required this.title});
  @override
  final String id;
  final String title;

  static const empty = TestItem(id: '', title: '');
}

class TestMeta extends MetaModel {
  const TestMeta();

  @override
  List<Object?> get props => [];
}

void main() {
  group('StrataPaginationWidget Assertions & Construction', () {
    test('throws AssertionError when no layout builder is provided', () {
      expect(
        () => StrataPaginationWidget<TestItem, TestMeta>(
          emptyEntity: TestItem.empty,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws AssertionError when multiple layout builders are provided', () {
      expect(
        () => StrataPaginationWidget<TestItem, TestMeta>(
          emptyEntity: TestItem.empty,
          scrollableBuilder: (ctx, ctrl, items) => const SizedBox(),
          sliversBuilder: (ctx, ctrl, items) => const SizedBox(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('renders adaptive circular progress indicator on initial load when emptyEntity is omitted and no custom builder is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState<TestItem, TestMeta>.loading(),
              scrollableBuilder: (ctx, ctrl, items) => ListView(),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('strata_pagination_initial_loader')), findsOneWidget);
    });
  });

  group('StrataPaginationConfig Tests', () {
    testWidgets('provides configuration to descendant StrataPaginationWidget', (tester) async {
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Config Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationConfig<TestItem, TestMeta>(
              emptyEntity: TestItem.empty,
              scrollThreshold: 300.0,
              child: Builder(
                builder: (context) {
                  final config = StrataPaginationConfig.of<TestItem, TestMeta>(context);
                  expect(config, isNotNull);
                  expect(config.scrollThreshold, 300.0);
                  return StrataPaginationWidget<TestItem, TestMeta>(
                    state: const StrataPaginationState.succeeded(
                      paginatedResponseModel: model,
                      hasReachedMax: true,
                    ),
                    scrollableBuilder: (ctx, ctrl, items) {
                      return ListView.builder(
                        key: const Key('strata_pagination_list'),
                        controller: ctrl,
                        itemCount: items.length,
                        itemBuilder: (ctx, i) => Text(items[i].title),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Config Item'), findsOneWidget);
    });

    testWidgets('StrataPaginationConfig.of throws assertion error when missing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                expect(
                  () => StrataPaginationConfig.of<TestItem, TestMeta>(context),
                  throwsA(isA<AssertionError>()),
                );
                expect(
                  StrataPaginationConfig.maybeOf<TestItem, TestMeta>(context),
                  isNull,
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    test('StrataPaginationConfig.updateShouldNotify', () {
      const c1 = StrataPaginationConfig<TestItem, TestMeta>(
        child: SizedBox(),
      );
      const c2 = StrataPaginationConfig<TestItem, TestMeta>(
        scrollThreshold: 300.0,
        child: SizedBox(),
      );

      expect(c1.updateShouldNotify(c1), isFalse);
      expect(c1.updateShouldNotify(c2), isTrue);
    });
  });

  group('Layout Builders (scrollableBuilder, sliversBuilder, customBuilder)', () {
    testWidgets('scrollableBuilder renders ListView', (tester) async {
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Scrollable Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState.succeeded(
                paginatedResponseModel: model,
                hasReachedMax: true,
              ),
              emptyEntity: TestItem.empty,
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  key: const Key('strata_pagination_list'),
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('strata_pagination_list')), findsOneWidget);
      expect(find.text('Scrollable Item'), findsOneWidget);
    });

    testWidgets('sliversBuilder renders CustomScrollView', (tester) async {
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Sliver Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState.succeeded(
                paginatedResponseModel: model,
                hasReachedMax: true,
              ),
              emptyEntity: TestItem.empty,
              sliversBuilder: (ctx, ctrl, items) {
                return CustomScrollView(
                  key: const Key('strata_pagination_list'),
                  controller: ctrl,
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Text(items[i].title),
                        childCount: items.length,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('strata_pagination_list')), findsOneWidget);
      expect(find.text('Sliver Item'), findsOneWidget);
    });

    testWidgets('customBuilder renders horizontal list', (tester) async {
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Custom Horizontal Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState.succeeded(
                paginatedResponseModel: model,
                hasReachedMax: true,
              ),
              emptyEntity: TestItem.empty,
              scrollDirection: Axis.horizontal,
              customBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  key: const Key('strata_pagination_list'),
                  controller: ctrl,
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('strata_pagination_list')), findsOneWidget);
      expect(find.text('Custom Horizontal Item'), findsOneWidget);
    });
  });

  group('Sealed State Lifecycle Rendering', () {
    testWidgets('PaginationLoading renders Skeletonizer with emptyEntity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState<TestItem, TestMeta>.loading(),
              emptyEntity: TestItem.empty,
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text('Skeleton $i'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Skeleton 0'), findsOneWidget);
    });

    testWidgets('PaginationLoading renders custom loadingBuilder if provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState<TestItem, TestMeta>.loading(),
              loadingBuilder: (ctx) => const Text('Custom Loading Spinner'),
              scrollableBuilder: (ctx, ctrl, items) => ListView(),
            ),
          ),
        ),
      );

      expect(find.text('Custom Loading Spinner'), findsOneWidget);
    });

    testWidgets('PaginationLoading renders custom skeletonBuilder if provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState<TestItem, TestMeta>.loading(),
              skeletonBuilder: (ctx) => const Text('Custom Skeleton List'),
              scrollableBuilder: (ctx, ctrl, items) => ListView(),
            ),
          ),
        ),
      );

      expect(find.text('Custom Skeleton List'), findsOneWidget);
    });

    testWidgets('PaginationFailed renders error widget and retry button triggers onRetry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: StrataPaginationState<TestItem, TestMeta>.failed(
                failure: const ServerFailure(message: 'Connection failed', statusCode: 500),
                onRetry: () => retried = true,
              ),
              emptyEntity: TestItem.empty,
              scrollableBuilder: (ctx, ctrl, items) => ListView(),
            ),
          ),
        ),
      );

      expect(find.text('Connection failed'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('PaginationFailed renders custom errorBuilder if provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState<TestItem, TestMeta>.failed(
                failure: ServerFailure(message: 'Server error', statusCode: 500),
              ),
              errorBuilder: (ctx, failure, retry) => Text('Custom Error: ${failure.message}'),
              scrollableBuilder: (ctx, ctrl, items) => ListView(),
            ),
          ),
        ),
      );

      expect(find.text('Custom Error: Server error'), findsOneWidget);
    });

    testWidgets('PaginationSucceeded renders emptyBuilder when dataset is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState<TestItem, TestMeta>.succeeded(
                paginatedResponseModel: PaginationResponseModel(data: []),
                hasReachedMax: true,
              ),
              emptyBuilder: (ctx) => const Text('No products available'),
              scrollableBuilder: (ctx, ctrl, items) => ListView(),
            ),
          ),
        ),
      );

      expect(find.text('No products available'), findsOneWidget);
    });

    testWidgets('PaginationSucceeded default empty state renders when emptyBuilder is omitted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState<TestItem, TestMeta>.succeeded(
                paginatedResponseModel: PaginationResponseModel(data: []),
                hasReachedMax: true,
              ),
              scrollableBuilder: (ctx, ctrl, items) => ListView(),
            ),
          ),
        ),
      );

      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('renders offline badge when isFromCache or isOffline is true', (tester) async {
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Cached Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState.succeeded(
                paginatedResponseModel: model,
                hasReachedMax: true,
                isFromCache: true,
              ),
              showOfflineBadge: true,
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('strata_pagination_offline_badge')), findsOneWidget);
      expect(find.text('Viewing offline cached data'), findsOneWidget);
    });

    testWidgets('renders custom offlineBadgeBuilder when provided', (tester) async {
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Cached Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState.succeeded(
                paginatedResponseModel: model,
                hasReachedMax: true,
                isOffline: true,
              ),
              showOfflineBadge: true,
              offlineBadgeBuilder: (ctx) => const Text('Custom Offline Banner'),
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Custom Offline Banner'), findsOneWidget);
    });

    testWidgets('PaginationLoadingMore renders bottom loader tile', (tester) async {
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Page 1 Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState.loadingMore(
                paginatedResponseModel: model,
                hasReachedMax: false,
              ),
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('strata_pagination_bottom_loader')), findsOneWidget);
    });

    testWidgets('PaginationPageFetchFailure renders bottom retry bar and tapping retry triggers onRetryMore', (tester) async {
      var retryMoreCalled = false;
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Page 1 Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: StrataPaginationState.pageFetchFailure(
                failure: const ServerFailure(message: 'Failed page 2', statusCode: 500),
                paginatedResponseModel: model,
                hasReachedMax: false,
                onRetryMore: () => retryMoreCalled = true,
              ),
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('strata_pagination_retry_button')), findsOneWidget);
      expect(find.text('Failed page 2'), findsOneWidget);

      await tester.tap(find.byKey(const Key('strata_pagination_retry_button')));
      expect(retryMoreCalled, isTrue);
    });

    testWidgets('PaginationPageFetchFailure renders custom retryMoreBuilder if provided', (tester) async {
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Page 1 Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState.pageFetchFailure(
                failure: ServerFailure(message: 'Failed page 2', statusCode: 500),
                paginatedResponseModel: model,
                hasReachedMax: false,
              ),
              retryMoreBuilder: (ctx, failure, onRetryMore) =>
                  Text('Custom Retry Footer: ${failure.message}'),
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Custom Retry Footer: Failed page 2'), findsOneWidget);
    });
  });

  group('Interactive Mechanics (Pull-To-Refresh, Infinite Scroll, Desktop Shortcuts)', () {
    testWidgets('triggers onRefresh when pulled down', (tester) async {
      var refreshed = false;
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Item 1')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState.succeeded(
                paginatedResponseModel: model,
                hasReachedMax: false,
              ),
              onRefresh: () async => refreshed = true,
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => SizedBox(
                    height: 200,
                    child: Text(items[i].title),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('strata_pagination_refresh_indicator')), findsOneWidget);
      await tester.fling(find.text('Item 1'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });

    testWidgets('triggers onLoadMore when scrolling near the bottom', (tester) async {
      var loadMoreTriggered = false;
      final model = PaginationResponseModel<TestItem, TestMeta>(
        data: List.generate(20, (i) => TestItem(id: '$i', title: 'Item $i')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: StrataPaginationWidget<TestItem, TestMeta>(
                state: StrataPaginationState.succeeded(
                  paginatedResponseModel: model,
                  hasReachedMax: false,
                ),
                scrollThreshold: 100.0,
                onLoadMore: () async => loadMoreTriggered = true,
                scrollableBuilder: (ctx, ctrl, items) {
                  return ListView.builder(
                    controller: ctrl,
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => SizedBox(
                      height: 50,
                      child: Text(items[i].title),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Item 0'), const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(loadMoreTriggered, isTrue);
    });

    testWidgets('triggers onRefresh when Ctrl+R keyboard shortcut is pressed', (tester) async {
      var refreshed = false;
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Shortcut Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState.succeeded(
                paginatedResponseModel: model,
                hasReachedMax: false,
              ),
              enableDesktopShortcuts: true,
              onRefresh: () async => refreshed = true,
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                );
              },
            ),
          ),
        ),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });

    testWidgets('enableScrollToTop renders FAB and scrolls to top on tap', (tester) async {
      final model = PaginationResponseModel<TestItem, TestMeta>(
        data: List.generate(30, (i) => TestItem(id: '$i', title: 'Item $i')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: StrataPaginationWidget<TestItem, TestMeta>(
                state: StrataPaginationState.succeeded(
                  paginatedResponseModel: model,
                  hasReachedMax: false,
                ),
                enableScrollToTop: true,
                scrollableBuilder: (ctx, ctrl, items) {
                  return ListView.builder(
                    controller: ctrl,
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => SizedBox(
                      height: 50,
                      child: Text(items[i].title),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Item 0'), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('triggers onRefresh when Cmd+R keyboard shortcut is pressed', (tester) async {
      var refreshed = false;
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Shortcut Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState.succeeded(
                paginatedResponseModel: model,
                hasReachedMax: false,
              ),
              enableDesktopShortcuts: true,
              onRefresh: () async => refreshed = true,
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                );
              },
            ),
          ),
        ),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });

    testWidgets('does not trigger onRefresh when enableDesktopShortcuts is false', (tester) async {
      var refreshed = false;
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Shortcut Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState.succeeded(
                paginatedResponseModel: model,
                hasReachedMax: false,
              ),
              enableDesktopShortcuts: false,
              onRefresh: () async => refreshed = true,
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                );
              },
            ),
          ),
        ),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(refreshed, isFalse);
    });

    testWidgets('accepts external ScrollController without disposing it prematurely', (tester) async {
      final externalController = ScrollController();
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'External Ctrl Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              controller: externalController,
              state: const StrataPaginationState.succeeded(
                paginatedResponseModel: model,
                hasReachedMax: true,
              ),
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('External Ctrl Item'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      // External controller should still be valid
      expect(externalController.hasClients, isFalse);
      externalController.dispose();
    });

    testWidgets('ignores scroll notifications from a perpendicular scroll axis', (tester) async {
      var loadMoreCalled = false;
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Item 1')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState.succeeded(
                paginatedResponseModel: model,
                hasReachedMax: false,
              ),
              scrollDirection: Axis.vertical,
              onLoadMore: () async => loadMoreCalled = true,
              scrollableBuilder: (ctx, ctrl, items) {
                return NotificationListener<ScrollNotification>(
                  child: ListView.builder(
                    controller: ctrl,
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => Text(items[i].title),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Dispatch a horizontal scroll notification
      final element = find.text('Item 1').evaluate().first;
      ScrollUpdateNotification(
        metrics: FixedScrollMetrics(
          minScrollExtent: 0,
          maxScrollExtent: 100,
          pixels: 90,
          viewportDimension: 100,
          axisDirection: AxisDirection.right,
          devicePixelRatio: 1.0,
        ),
        context: element,
      ).dispatch(element);

      await tester.pump();
      expect(loadMoreCalled, isFalse);
    });

    testWidgets('does not trigger onLoadMore when isRefreshing or isLoadingMore or hasReachedMax is true', (tester) async {
      var loadMoreCalled = false;
      final model = PaginationResponseModel<TestItem, TestMeta>(
        data: List.generate(20, (i) => TestItem(id: '$i', title: 'Item $i')),
      );

      // 1. isRefreshing
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: StrataPaginationWidget<TestItem, TestMeta>(
                state: StrataPaginationState.refreshing(
                  paginatedResponseModel: model,
                  hasReachedMax: false,
                ),
                onLoadMore: () async => loadMoreCalled = true,
                scrollableBuilder: (ctx, ctrl, items) {
                  return ListView.builder(
                    controller: ctrl,
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => SizedBox(height: 50, child: Text(items[i].title)),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Item 0'), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(loadMoreCalled, isFalse);

      // 2. isLoadingMore
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: StrataPaginationWidget<TestItem, TestMeta>(
                state: StrataPaginationState.loadingMore(
                  paginatedResponseModel: model,
                  hasReachedMax: false,
                ),
                onLoadMore: () async => loadMoreCalled = true,
                scrollableBuilder: (ctx, ctrl, items) {
                  return ListView.builder(
                    controller: ctrl,
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => SizedBox(height: 50, child: Text(items[i].title)),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Item 0'), const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 100));
      expect(loadMoreCalled, isFalse);

      // 3. hasReachedMax
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: StrataPaginationWidget<TestItem, TestMeta>(
                state: StrataPaginationState.succeeded(
                  paginatedResponseModel: model,
                  hasReachedMax: true,
                ),
                onLoadMore: () async => loadMoreCalled = true,
                scrollableBuilder: (ctx, ctrl, items) {
                  return ListView.builder(
                    controller: ctrl,
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => SizedBox(height: 50, child: Text(items[i].title)),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Item 0'), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(loadMoreCalled, isFalse);
    });

    testWidgets('hides Scrollbar and RefreshIndicator when disabled', (tester) async {
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'No Controls')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              state: const StrataPaginationState.succeeded(
                paginatedResponseModel: model,
                hasReachedMax: true,
              ),
              enableScrollbar: false,
              showRefreshIndicator: false,
              onRefresh: () async {},
              scrollableBuilder: (ctx, ctrl, items) => ListView(),
            ),
          ),
        ),
      );

      expect(find.byType(Scrollbar), findsNothing);
      expect(find.byType(RefreshIndicator), findsNothing);
    });

    test('supports deprecated onFetchPage parameter', () {
      // Verify compile-time and runtime acceptance of onFetchPage
      final widget = StrataPaginationWidget<TestItem, TestMeta>(
        emptyEntity: TestItem.empty,
        // ignore: deprecated_member_use_from_same_package
        onFetchPage: (page) async {},
        scrollableBuilder: (ctx, ctrl, items) => const SizedBox(),
      );
      // ignore: deprecated_member_use_from_same_package
      expect(widget.onFetchPage, isNotNull);
    });
  });

  group('Explicit Properties Fallback (state == null)', () {
    testWidgets('initial loading renders when items is null and isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              isLoading: true,
              emptyEntity: TestItem.empty,
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text('Item $i'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('initial failure renders when items is null and failure is present', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              failure: const ServerFailure(message: 'Initial fail', statusCode: 500),
              onRetry: () => retried = true,
              scrollableBuilder: (ctx, ctrl, items) => ListView(),
            ),
          ),
        ),
      );

      expect(find.text('Initial fail'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('populates items and renders bottom loader when isLoading is true and items not empty', (tester) async {
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Explicit Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              items: model,
              isLoading: true,
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Explicit Item'), findsOneWidget);
      expect(find.byKey(const Key('strata_pagination_bottom_loader')), findsOneWidget);
    });

    testWidgets('populates items and renders retry bar when failure is present and items not empty', (tester) async {
      var retriedMore = false;
      const model = PaginationResponseModel<TestItem, TestMeta>(
        data: [TestItem(id: '1', title: 'Explicit Item')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationWidget<TestItem, TestMeta>(
              items: model,
              failure: const ServerFailure(message: 'More error', statusCode: 500),
              onRetryMore: () => retriedMore = true,
              scrollableBuilder: (ctx, ctrl, items) {
                return ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Explicit Item'), findsOneWidget);
      expect(find.byKey(const Key('strata_pagination_retry_button')), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retriedMore, isTrue);
    });

    testWidgets('does not trigger onLoadMore when isLoading is true in explicit fallback', (tester) async {
      var loadMoreCalled = false;
      final model = PaginationResponseModel<TestItem, TestMeta>(
        data: List.generate(20, (i) => TestItem(id: '$i', title: 'Item $i')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: StrataPaginationWidget<TestItem, TestMeta>(
                items: model,
                isLoading: true,
                onLoadMore: () async => loadMoreCalled = true,
                scrollableBuilder: (ctx, ctrl, items) {
                  return ListView.builder(
                    controller: ctrl,
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => SizedBox(height: 50, child: Text(items[i].title)),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Item 0'), const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 100));
      expect(loadMoreCalled, isFalse);
    });

    testWidgets('does not trigger onLoadMore when hasReachedMax is true in explicit fallback', (tester) async {
      var loadMoreCalled = false;
      final model = PaginationResponseModel<TestItem, TestMeta>(
        data: List.generate(20, (i) => TestItem(id: '$i', title: 'Item $i')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: StrataPaginationWidget<TestItem, TestMeta>(
                items: model,
                hasReachedMax: true,
                onLoadMore: () async => loadMoreCalled = true,
                scrollableBuilder: (ctx, ctrl, items) {
                  return ListView.builder(
                    controller: ctrl,
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => SizedBox(height: 50, child: Text(items[i].title)),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Item 0'), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(loadMoreCalled, isFalse);
    });
  });

  group('StrataPaginationConfig Defaults Inheritance', () {
    testWidgets('inherits emptyBuilder, loadingBuilder, skeletonBuilder, errorBuilder, retryMoreBuilder, offlineBadgeBuilder', (tester) async {
      // 1. Inherit emptyBuilder
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationConfig<TestItem, TestMeta>(
              emptyBuilder: (ctx) => const Text('Config Empty State'),
              child: StrataPaginationWidget<TestItem, TestMeta>(
                state: const StrataPaginationState.succeeded(
                  paginatedResponseModel: PaginationResponseModel(data: []),
                  hasReachedMax: true,
                ),
                scrollableBuilder: (ctx, ctrl, items) => ListView(),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Config Empty State'), findsOneWidget);

      // 2. Inherit loadingBuilder
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationConfig<TestItem, TestMeta>(
              loadingBuilder: (ctx) => const Text('Config Loading State'),
              child: StrataPaginationWidget<TestItem, TestMeta>(
                state: const StrataPaginationState.loading(),
                scrollableBuilder: (ctx, ctrl, items) => ListView(),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Config Loading State'), findsOneWidget);

      // 3. Inherit skeletonBuilder
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationConfig<TestItem, TestMeta>(
              skeletonBuilder: (ctx) => const Text('Config Skeleton State'),
              child: StrataPaginationWidget<TestItem, TestMeta>(
                state: const StrataPaginationState.loading(),
                scrollableBuilder: (ctx, ctrl, items) => ListView(),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Config Skeleton State'), findsOneWidget);

      // 4. Inherit errorBuilder
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationConfig<TestItem, TestMeta>(
              errorBuilder: (ctx, f, retry) => Text('Config Error: ${f.message}'),
              child: StrataPaginationWidget<TestItem, TestMeta>(
                state: const StrataPaginationState.failed(
                  failure: ServerFailure(message: 'Boom', statusCode: 500),
                ),
                scrollableBuilder: (ctx, ctrl, items) => ListView(),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Config Error: Boom'), findsOneWidget);

      // 5. Inherit retryMoreBuilder
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationConfig<TestItem, TestMeta>(
              retryMoreBuilder: (ctx, f, onRetry) => Text('Config RetryMore: ${f.message}'),
              child: StrataPaginationWidget<TestItem, TestMeta>(
                state: const StrataPaginationState.pageFetchFailure(
                  failure: ServerFailure(message: 'Page 2 fail', statusCode: 500),
                  paginatedResponseModel: PaginationResponseModel(data: [TestItem(id: '1', title: 'T')]),
                  hasReachedMax: false,
                ),
                scrollableBuilder: (ctx, ctrl, items) => ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Config RetryMore: Page 2 fail'), findsOneWidget);

      // 6. Inherit offlineBadgeBuilder & emptyEntity & skeletonItemCount
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationConfig<TestItem, TestMeta>(
              offlineBadgeBuilder: (ctx) => const Text('Config Offline Badge'),
              skeletonItemCount: 5,
              emptyEntity: TestItem.empty,
              child: StrataPaginationWidget<TestItem, TestMeta>(
                state: const StrataPaginationState.succeeded(
                  paginatedResponseModel: PaginationResponseModel(data: [TestItem(id: '1', title: 'T')]),
                  hasReachedMax: true,
                  isFromCache: true,
                ),
                scrollableBuilder: (ctx, ctrl, items) => ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text(items[i].title),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Config Offline Badge'), findsOneWidget);

      // 7. Inherit emptyEntity and skeletonItemCount for Skeletonizer
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrataPaginationConfig<TestItem, TestMeta>(
              skeletonItemCount: 3,
              emptyEntity: TestItem.empty,
              child: StrataPaginationWidget<TestItem, TestMeta>(
                state: const StrataPaginationState.loading(),
                scrollableBuilder: (ctx, ctrl, items) => ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Text('Item $i'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('inherits scrollThreshold, enableScrollbar, showRefreshIndicator, and enableScrollToTop', (tester) async {
      var refreshed = false;
      var loadMoreCalled = false;
      final model = PaginationResponseModel<TestItem, TestMeta>(
        data: List.generate(20, (i) => TestItem(id: '$i', title: 'Item $i')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: StrataPaginationConfig<TestItem, TestMeta>(
                scrollThreshold: 150.0,
                enableScrollbar: true,
                showRefreshIndicator: true,
                enableScrollToTop: true,
                enableDesktopShortcuts: true,
                child: StrataPaginationWidget<TestItem, TestMeta>(
                  state: StrataPaginationState.succeeded(
                    paginatedResponseModel: model,
                    hasReachedMax: false,
                  ),
                  onRefresh: () async => refreshed = true,
                  onLoadMore: () async => loadMoreCalled = true,
                  scrollableBuilder: (ctx, ctrl, items) {
                    return ListView.builder(
                      controller: ctrl,
                      itemCount: items.length,
                      itemBuilder: (ctx, i) => SizedBox(height: 50, child: Text(items[i].title)),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Scrollbar), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);

      await tester.drag(find.text('Item 0'), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(loadMoreCalled, isTrue);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(refreshed, isFalse);
    });
  });
}
