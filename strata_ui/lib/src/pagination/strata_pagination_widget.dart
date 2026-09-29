import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_state/strata_state.dart';

import '../constants/padding_manager.dart';
import '../widgets/core_default_error_widget.dart';
import '../widgets/core_scrollable_content_with_fab.dart';

/// Inherited widget for providing default configuration to descendant [StrataPaginationWidget]s.
///
/// Use this widget higher up in the widget tree to set default pagination options such as
/// [scrollThreshold], builders, and platform configuration.
///
/// `@example`
/// ```dart
/// StrataPaginationConfig<ProductItem, PaginationMetaModel>(
///   scrollThreshold: 300.0,
///   showOfflineBadge: true,
///   child: MaterialApp(home: ProductListPage()),
/// );
/// ```
class StrataPaginationConfig<T extends Identifiable, M extends MetaModel>
    extends InheritedWidget {
  /// Creates a [StrataPaginationConfig].
  const StrataPaginationConfig({
    super.key,
    this.showRefreshIndicator = true,
    this.scrollThreshold = 200.0,
    this.showOfflineBadge = true,
    this.enableDesktopShortcuts = true,
    this.enableScrollbar = true,
    this.enableScrollToTop = false,
    this.scrollDirection = Axis.vertical,
    this.physics,
    this.reverse = false,
    this.skeletonItemCount = 20,
    this.loadingBuilder,
    this.emptyBuilder,
    this.skeletonBuilder,
    this.errorBuilder,
    this.retryMoreBuilder,
    this.offlineBadgeBuilder,
    this.emptyEntity,
    required super.child,
  });

  /// Whether to render pull-to-refresh control by default.
  final bool showRefreshIndicator;

  /// Distance in pixels from the bottom of scrollable to trigger [StrataPaginationWidget.onLoadMore].
  final double scrollThreshold;

  /// Whether to render offline badge when viewing cached or offline data.
  final bool showOfflineBadge;

  /// Whether to listen for `Ctrl+R` / `Cmd+R` refresh shortcuts on desktop/web.
  final bool enableDesktopShortcuts;

  /// Whether to wrap content in a [Scrollbar] on desktop/web platforms.
  final bool enableScrollbar;

  /// Whether to show floating action button to scroll back to top.
  final bool enableScrollToTop;

  /// Scroll axis direction.
  final Axis scrollDirection;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Whether scroll view is reversed.
  final bool reverse;

  /// Number of skeleton placeholder items to render during initial load.
  final int skeletonItemCount;

  /// Default loading builder.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Default empty state builder.
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Default skeleton loader builder.
  final Widget Function(BuildContext context)? skeletonBuilder;

  /// Default error builder for initial fetch failure.
  final Widget Function(
    BuildContext context,
    Failure failure,
    VoidCallback? retry,
  )? errorBuilder;

  /// Default retry bar builder for page-N fetch failure.
  final Widget Function(
    BuildContext context,
    Failure failure,
    VoidCallback? onRetryMore,
  )? retryMoreBuilder;

  /// Default offline badge builder.
  final Widget Function(BuildContext context)? offlineBadgeBuilder;

  /// Default prototype entity used for [Skeletonizer] layout creation.
  final T? emptyEntity;

  /// Safely attempts to retrieve the nearest ancestor [StrataPaginationConfig].
  static StrataPaginationConfig<T, M>? maybeOf<T extends Identifiable,
      M extends MetaModel>(
    BuildContext context,
  ) {
    return context
        .dependOnInheritedWidgetOfExactType<StrataPaginationConfig<T, M>>();
  }

  /// Retrieves the nearest ancestor [StrataPaginationConfig] or throws an assertion error.
  static StrataPaginationConfig<T, M> of<T extends Identifiable,
      M extends MetaModel>(
    BuildContext context,
  ) {
    final cfg = maybeOf<T, M>(context);
    assert(cfg != null, 'No StrataPaginationConfig<$T, $M> found in context');
    return cfg!;
  }

  @override
  bool updateShouldNotify(covariant StrataPaginationConfig<T, M> oldWidget) =>
      this != oldWidget;
}

/// Decoupled, platform-adaptive pagination widget for the Strata framework.
///
/// Replaces third-party refresh libraries with native Flutter SDK components ([RefreshIndicator.adaptive],
/// [NotificationListener<ScrollNotification>], [Scrollbar], [CallbackShortcuts]).
///
/// Strictly driven by [StrataPaginationState] from `strata_state` or explicit state properties.
/// Requires exactly one layout builder: [scrollableBuilder], [sliversBuilder], or [customBuilder].
///
/// Deterministic keys provided for testing:
/// - `Key('strata_pagination_list')`
/// - `Key('strata_pagination_refresh_indicator')`
/// - `Key('strata_pagination_bottom_loader')`
/// - `Key('strata_pagination_retry_button')`
/// - `Key('strata_pagination_offline_badge')`
///
/// `@example`
/// ```dart
/// StrataPaginationWidget<ProductItem, PaginationMetaModel>(
///   state: state,
///   onRefresh: () async => context.read<ProductBloc>().add(const StrataPaginationRefreshed()),
///   onLoadMore: () async => context.read<ProductBloc>().add(const StrataPaginationMoreFetched()),
///   scrollableBuilder: (context, controller, items) {
///     return ListView.separated(
///       key: const Key('strata_pagination_list'),
///       controller: controller,
///       itemCount: items.length,
///       separatorBuilder: (_, __) => const Divider(),
///       itemBuilder: (context, index) => ListTile(title: Text(items[index].name)),
///     );
///   },
/// );
/// ```
class StrataPaginationWidget<T extends Identifiable, M extends MetaModel>
    extends StatefulWidget {
  /// Creates a [StrataPaginationWidget].
  const StrataPaginationWidget({
    super.key,
    this.state,
    @Deprecated('Use StrataPaginationState driven by StrataPaginationBloc instead.')
    this.onFetchPage,
    this.onRefresh,
    this.onLoadMore,
    this.onRetry,
    this.onRetryMore,
    this.items,
    this.isLoading = false,
    this.hasReachedMax = false,
    this.failure,
    this.scrollableBuilder,
    this.sliversBuilder,
    this.customBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.skeletonBuilder,
    this.errorBuilder,
    this.retryMoreBuilder,
    this.offlineBadgeBuilder,
    this.emptyEntity,
    this.showRefreshIndicator = true,
    this.scrollThreshold = 200.0,
    this.showOfflineBadge = true,
    this.enableDesktopShortcuts = true,
    this.enableScrollbar = true,
    this.enableScrollToTop = false,
    this.scrollDirection = Axis.vertical,
    this.physics,
    this.reverse = false,
    this.skeletonItemCount,
    this.controller,
  }) : assert(
          (scrollableBuilder != null ? 1 : 0) +
                  (sliversBuilder != null ? 1 : 0) +
                  (customBuilder != null ? 1 : 0) ==
              1,
          'Provide exactly one of scrollableBuilder, sliversBuilder, or customBuilder',
        );

  /// Active pagination state driven by BLoC or state container.
  final StrataPaginationState<T, M>? state;

  /// Deprecated internal state fetching callback.
  ///
  /// Deprecated in favor of [state] driven by [StrataPaginationBloc].
  @Deprecated('Use StrataPaginationState driven by StrataPaginationBloc instead.')
  final Future<void> Function(int page)? onFetchPage;

  /// Callback dispatched when pull-to-refresh or keyboard shortcut occurs.
  final Future<void> Function()? onRefresh;

  /// Callback dispatched when user scrolls within [scrollThreshold] pixels of the end.
  final Future<void> Function()? onLoadMore;

  /// Callback dispatched to retry initial fetch after failure.
  final VoidCallback? onRetry;

  /// Callback dispatched to retry incremental page-N fetch after failure.
  final VoidCallback? onRetryMore;

  /// Explicit items model when [state] is omitted.
  final PaginationResponseModel<T, M>? items;

  /// Explicit loading state when [state] is omitted.
  final bool isLoading;

  /// Explicit reached max flag when [state] is omitted.
  final bool hasReachedMax;

  /// Explicit failure when [state] is omitted.
  final Failure? failure;

  /// Builder for standard list/grid scrollables.
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
    List<T> items,
  )? scrollableBuilder;

  /// Builder for custom scroll view slivers.
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
    List<T> items,
  )? sliversBuilder;

  /// Builder for custom layout elements (carousels, page views, tabs).
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
    List<T> items,
  )? customBuilder;

  /// Custom loading widget builder.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Custom empty state builder.
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Custom skeleton loader builder.
  final Widget Function(BuildContext context)? skeletonBuilder;

  /// Custom initial fetch error builder.
  final Widget Function(
    BuildContext context,
    Failure failure,
    VoidCallback? retry,
  )? errorBuilder;

  /// Custom page-N fetch retry bar builder.
  final Widget Function(
    BuildContext context,
    Failure failure,
    VoidCallback? onRetryMore,
  )? retryMoreBuilder;

  /// Custom offline data banner builder.
  final Widget Function(BuildContext context)? offlineBadgeBuilder;

  /// Prototype entity required for default skeletonizer layout generation.
  final T? emptyEntity;

  /// Whether pull-to-refresh is enabled.
  final bool showRefreshIndicator;

  /// Distance threshold in pixels from scroll end to dispatch [onLoadMore].
  final double scrollThreshold;

  /// Whether offline badge indicator is rendered when viewing cached/offline state.
  final bool showOfflineBadge;

  /// Whether `Ctrl+R` / `Cmd+R` desktop refresh shortcuts are active.
  final bool enableDesktopShortcuts;

  /// Whether scrollbars are shown on desktop/web platforms.
  final bool enableScrollbar;

  /// Whether floating action button for scroll-to-top is active.
  final bool enableScrollToTop;

  /// Scroll axis direction.
  final Axis scrollDirection;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Reverse scroll direction.
  final bool reverse;

  /// Number of skeleton items to generate during initial loading.
  final int? skeletonItemCount;

  /// External scroll controller.
  final ScrollController? controller;

  @override
  State<StrataPaginationWidget<T, M>> createState() =>
      _StrataPaginationWidgetState<T, M>();
}

class _StrataPaginationWidgetState<T extends Identifiable, M extends MetaModel>
    extends State<StrataPaginationWidget<T, M>> {
  ScrollController? _internalController;

  ScrollController get _activeController =>
      widget.controller ?? (_internalController ??= ScrollController());

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  void _triggerLoadMore() {
    final state = widget.state;
    final rawItems = state?.items ?? widget.items?.data;
    final itemsCount = rawItems?.length ?? 0;
    final isLoadingMore = state?.isLoadingMore == true ||
        (state == null && itemsCount > 0 && widget.isLoading);
    final isRefreshing = state?.isRefreshing == true;
    final isLoadingInitial = state?.isLoading == true ||
        state is PaginationInitial ||
        (state == null && itemsCount == 0 && widget.isLoading);
    final hasReachedMax = state?.hasReachedMax ?? widget.hasReachedMax;

    if (isLoadingMore || isRefreshing || isLoadingInitial || hasReachedMax) {
      return;
    }

    widget.onLoadMore?.call();
  }

  bool _onScrollNotification(
    ScrollNotification notification,
    ScrollController activeCtrl,
  ) {
    if (notification.metrics.axis != widget.scrollDirection) return false;
    final maxScroll = notification.metrics.maxScrollExtent;
    final currentScroll = notification.metrics.pixels;
    final parentConfig = StrataPaginationConfig.maybeOf<T, M>(context);
    final threshold = widget.scrollThreshold != 200.0
        ? widget.scrollThreshold
        : (parentConfig?.scrollThreshold ?? 200.0);

    if (maxScroll - currentScroll <= threshold) {
      _triggerLoadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final parentConfig = StrataPaginationConfig.maybeOf<T, M>(context);

    final state = widget.state;
    final rawItems = state?.items ?? widget.items?.data;

    final isInitialLoading = state?.isLoading == true ||
        state is PaginationInitial ||
        (state == null && rawItems == null && widget.isLoading);

    final isInitialFailed = state is PaginationFailed ||
        (state == null && rawItems == null && widget.failure != null);

    final failure = state?.failure ?? widget.failure;

    final isLoadingMore = state?.isLoadingMore == true ||
        (state == null && rawItems != null && rawItems.isNotEmpty && widget.isLoading);
    final isPageFetchFailure = state?.isPageFetchFailure == true ||
        (state == null && rawItems != null && rawItems.isNotEmpty && widget.failure != null);
    final isFromCache = state?.isFromCache == true;
    final isOffline = state?.isOffline == true;

    final onRefresh = widget.onRefresh;

    final onRetry = widget.onRetry ??
        (state is PaginationFailed
            ? (state as PaginationFailed).onRetry
            : null);

    final onRetryMore = widget.onRetryMore ??
        (state is PaginationPageFetchFailure
            ? (state as PaginationPageFetchFailure).onRetryMore
            : null);

    final items = rawItems ?? <T>[];

    final activeBuilder = widget.scrollableBuilder ??
        widget.sliversBuilder ??
        widget.customBuilder!;

    Widget buildTree(ScrollController activeCtrl) {
      Widget body;

      // 1. Initial Loading State
      if (isInitialLoading && items.isEmpty) {
        body = _buildInitialLoadingState(
          context: context,
          activeController: activeCtrl,
          parentConfig: parentConfig,
          activeBuilder: activeBuilder,
        );
      }
      // 2. Initial Failure State
      else if (isInitialFailed && items.isEmpty) {
        body = _buildInitialErrorState(
          context: context,
          failure: failure ??
              const ServerFailure(message: 'Failed to load data', statusCode: 500),
          onRetry: onRetry,
          parentConfig: parentConfig,
        );
      }
      // 3. Empty Data State
      else if (items.isEmpty) {
        body = widget.emptyBuilder?.call(context) ??
            parentConfig?.emptyBuilder?.call(context) ??
            const _DefaultEmptyState();
      }
      // 4. Populated Data State
      else {
        body = _buildContentLayout(
          context: context,
          activeController: activeCtrl,
          items: items,
          activeBuilder: activeBuilder,
          isLoadingMore: isLoadingMore,
          isPageFetchFailure: isPageFetchFailure,
          isFromCache: isFromCache,
          isOffline: isOffline,
          failure: failure,
          onRetryMore: onRetryMore,
          parentConfig: parentConfig,
        );
      }

      // Wrap with NotificationListener for infinite scroll
      Widget content = NotificationListener<ScrollNotification>(
        onNotification: (notification) =>
            _onScrollNotification(notification, activeCtrl),
        child: body,
      );

      // Wrap with RefreshIndicator
      final showRefresh = widget.showRefreshIndicator &&
          (parentConfig?.showRefreshIndicator ?? true) &&
          onRefresh != null;
      if (showRefresh) {
        content = RefreshIndicator.adaptive(
          key: const Key('strata_pagination_refresh_indicator'),
          onRefresh: onRefresh,
          child: content,
        );
      }

      // Wrap with Desktop Scrollbar
      final enableScrollbar = widget.enableScrollbar &&
          (parentConfig?.enableScrollbar ?? true);
      if (enableScrollbar) {
        content = Scrollbar(
          controller: activeCtrl,
          child: content,
        );
      }

      return content;
    }

    final enableScrollToTop = widget.enableScrollToTop ||
        (parentConfig?.enableScrollToTop ?? false);
    Widget content = enableScrollToTop
        ? CoreScrollableContentWithFab(
            scrollableBuilder: (ctrl) => buildTree(ctrl),
          )
        : buildTree(_activeController);

    // Wrap with Desktop Refresh Shortcuts (Ctrl+R / Cmd+R)
    final enableShortcuts = widget.enableDesktopShortcuts &&
        (parentConfig?.enableDesktopShortcuts ?? true) &&
        onRefresh != null;

    if (enableShortcuts) {
      content = CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyR, control: true): () =>
              onRefresh(),
          const SingleActivator(LogicalKeyboardKey.keyR, meta: true): () =>
              onRefresh(),
        },
        child: Focus(
          autofocus: true,
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildInitialLoadingState({
    required BuildContext context,
    required ScrollController activeController,
    required StrataPaginationConfig<T, M>? parentConfig,
    required Widget Function(
      BuildContext context,
      ScrollController controller,
      List<T> items,
    ) activeBuilder,
  }) {
    final customLoading = widget.loadingBuilder ?? parentConfig?.loadingBuilder;
    if (customLoading != null) {
      return customLoading(context);
    }

    final customSkeleton =
        widget.skeletonBuilder ?? parentConfig?.skeletonBuilder;
    if (customSkeleton != null) {
      return customSkeleton(context);
    }

    final emptyEntity = widget.emptyEntity ?? parentConfig?.emptyEntity;
    if (emptyEntity == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator.adaptive(
            key: Key('strata_pagination_initial_loader'),
          ),
        ),
      );
    }

    final skeletonCount = widget.skeletonItemCount ??
        parentConfig?.skeletonItemCount ??
        20;

    final mockItems = List<T>.generate(skeletonCount, (_) => emptyEntity);

    return Skeletonizer(
      child: activeBuilder(context, activeController, mockItems),
    );
  }

  Widget _buildInitialErrorState({
    required BuildContext context,
    required Failure failure,
    required VoidCallback? onRetry,
    required StrataPaginationConfig<T, M>? parentConfig,
  }) {
    final customError = widget.errorBuilder ?? parentConfig?.errorBuilder;
    if (customError != null) {
      return customError(context, failure, onRetry);
    }

    return CoreDefaultErrorWidget(
      message: failure.message,
      onRetry: onRetry,
    );
  }

  Widget _buildContentLayout({
    required BuildContext context,
    required ScrollController activeController,
    required List<T> items,
    required Widget Function(
      BuildContext context,
      ScrollController controller,
      List<T> items,
    ) activeBuilder,
    required bool isLoadingMore,
    required bool isPageFetchFailure,
    required bool isFromCache,
    required bool isOffline,
    required Failure? failure,
    required VoidCallback? onRetryMore,
    required StrataPaginationConfig<T, M>? parentConfig,
  }) {
    final showBadge = widget.showOfflineBadge &&
        (parentConfig?.showOfflineBadge ?? true) &&
        (isFromCache || isOffline);

    final offlineWidget = showBadge
        ? (widget.offlineBadgeBuilder?.call(context) ??
            parentConfig?.offlineBadgeBuilder?.call(context) ??
            const _DefaultOfflineBadge())
        : null;

    Widget? footerWidget;
    if (isLoadingMore) {
      footerWidget = const _DefaultBottomLoader();
    } else if (isPageFetchFailure) {
      final customRetryMore =
          widget.retryMoreBuilder ?? parentConfig?.retryMoreBuilder;
      footerWidget = customRetryMore != null
          ? customRetryMore(context, failure ?? const ServerFailure(message: 'Error', statusCode: 500), onRetryMore)
          : _DefaultBottomRetryBar(
              failure: failure,
              onRetryMore: onRetryMore,
            );
    }

    final scrollableChild = activeBuilder(context, activeController, items);

    if (offlineWidget == null && footerWidget == null) {
      return scrollableChild;
    }

    return Column(
      children: [
        ?offlineWidget,
        Expanded(child: scrollableChild),
        ?footerWidget,
      ],
    );
  }
}

class _DefaultEmptyState extends StatelessWidget {
  const _DefaultEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: PaddingManager.paddingHorizontal20,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64),
            SizedBox(height: 16),
            Text('No items found'),
          ],
        ),
      ),
    );
  }
}

class _DefaultOfflineBadge extends StatelessWidget {
  const _DefaultOfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('strata_pagination_offline_badge'),
      color: Colors.orange.shade100,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 16, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Text(
            'Viewing offline cached data',
            style: TextStyle(
              color: Colors.orange.shade900,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultBottomLoader extends StatelessWidget {
  const _DefaultBottomLoader();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('strata_pagination_bottom_loader'),
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: const CircularProgressIndicator.adaptive(),
    );
  }
}

class _DefaultBottomRetryBar extends StatelessWidget {
  const _DefaultBottomRetryBar({
    required this.failure,
    required this.onRetryMore,
  });

  final Failure? failure;
  final VoidCallback? onRetryMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('strata_pagination_retry_bar'),
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              failure?.message ?? 'Failed to load next page',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          TextButton.icon(
            key: const Key('strata_pagination_retry_button'),
            onPressed: onRetryMore,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
