---
type: Work Item
title: Decoupled Native StrataPaginationWidget & Multi-Platform UI
parent: ../spec.md
---

## What to build
Refactor `StrataPaginationWidget` in `strata_ui`, deprecating internal state fetching (`onFetchPage`) and removing the `easy_refresh` dependency from `pubspec.yaml`. Implement native pull-to-refresh using `RefreshIndicator.adaptive`, infinite scroll using `NotificationListener<ScrollNotification>` with configurable pixel threshold, and mutually exclusive layout builders (`scrollableBuilder`, `sliversBuilder`, `customBuilder`). Render full-screen `Skeletonizer` on initial load and bottom tile/spinner on load-more. Render inline bottom retry bar on `PaginationPageFetchFailure` without losing scroll position. Add desktop/web scrollbar, `Ctrl+R` / `Cmd+R` refresh shortcut listeners, offline data badges, 100% executable DartDoc, and native Flutter widget tests with deterministic keys.

## Required context
- Remove `easy_refresh` from `strata_ui/pubspec.yaml`.
- Deterministic keys required for widget testing: `Key('strata_pagination_list')`, `Key('strata_pagination_refresh_indicator')`, `Key('strata_pagination_bottom_loader')`, `Key('strata_pagination_retry_button')`.
- Mutual exclusivity assertion: exactly one of `scrollableBuilder`, `sliversBuilder`, or `customBuilder` must be provided.
- Platform support: adaptive refresh control, mouse wheel overscroll protection, desktop shortcut listeners (`Ctrl+R` / `Cmd+R`), desktop `Scrollbar`, and scroll offset preservation during window resize.

## Usage Examples & Code Snippets

### Example 1: Standard Scrollable ListView (`scrollableBuilder`)
For standard vertical lists (`ListView.builder` or `ListView.separated`), use `scrollableBuilder`. The widget passes the active `ScrollController` and `List<T> items` to your builder.

```dart
StrataPaginationWidget<ProductItem, PaginationMetaModel>(
  state: state,
  onRefresh: () => context.read<ProductPaginationBloc>().add(const StrataPaginationRefreshed()),
  onLoadMore: () => context.read<ProductPaginationBloc>().add(const StrataPaginationMoreFetched()),
  scrollableBuilder: (context, scrollController, items) {
    return ListView.separated(
      key: const Key('strata_pagination_list'),
      controller: scrollController,
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final product = items[index];
        return ListTile(
          title: Text(product.name),
          subtitle: Text('\$${product.price}'),
        );
      },
    );
  },
);
```

### Example 2: Sliver CustomScrollView with Collapsible Header (`sliversBuilder`)
For advanced sliver layouts containing `SliverAppBar`, `SliverGrid`, or multiple sliver sections, use `sliversBuilder`.

```dart
StrataPaginationWidget<ProductItem, PaginationMetaModel>(
  state: state,
  onRefresh: () => context.read<ProductPaginationBloc>().add(const StrataPaginationRefreshed()),
  onLoadMore: () => context.read<ProductPaginationBloc>().add(const StrataPaginationMoreFetched()),
  sliversBuilder: (context, scrollController, items) {
    return CustomScrollView(
      key: const Key('strata_pagination_list'),
      controller: scrollController,
      slivers: [
        const SliverAppBar(
          floating: true,
          pinned: true,
          expandedHeight: 160.0,
          flexibleSpace: FlexibleSpaceBar(title: Text('Store Catalog')),
        ),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => ProductCard(product: items[index]),
            childCount: items.length,
          ),
        ),
      ],
    );
  },
);
```

### Example 3: Custom Carousel / Horizontal Layout (`customBuilder`)
For horizontal scrollables, carousels, PageViews, or tabbed views, use `customBuilder`.

```dart
StrataPaginationWidget<ProductItem, PaginationMetaModel>(
  state: state,
  onRefresh: () => context.read<ProductPaginationBloc>().add(const StrataPaginationRefreshed()),
  onLoadMore: () => context.read<ProductPaginationBloc>().add(const StrataPaginationMoreFetched()),
  customBuilder: (context, scrollController, items) {
    return ListView.builder(
      key: const Key('strata_pagination_list'),
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Container(
          width: 280,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ProductHeroCard(product: items[index]),
        );
      },
    );
  },
);
```

### Example 4: Desktop & Web with Scrollbars and `Ctrl+R` / `Cmd+R` Refresh Shortcuts
For desktop and web environments requiring explicit mouse scrollbar, mouse wheel overscroll protection, and keyboard shortcut listeners (`Ctrl+R` or `Cmd+R`).

```dart
StrataPaginationWidget<ProductItem, PaginationMetaModel>(
  state: state,
  enableDesktopShortcuts: true,
  enableScrollbar: true,
  onRefresh: () => context.read<ProductPaginationBloc>().add(const StrataPaginationRefreshed()),
  onLoadMore: () => context.read<ProductPaginationBloc>().add(const StrataPaginationMoreFetched()),
  scrollableBuilder: (context, scrollController, items) {
    return ListView.builder(
      key: const Key('strata_pagination_list'),
      controller: scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) => ProductRow(product: items[index]),
    );
  },
);
```

### Example 5: Offline & Cache Badge Indicator
Displays a contextual offline banner or cache badge when viewing cached offline data (`state.isFromCache` or `state.isOffline`).

```dart
StrataPaginationWidget<ProductItem, PaginationMetaModel>(
  state: state,
  showOfflineBadge: true,
  offlineBadgeBuilder: (context) {
    return Container(
      color: Colors.orange.shade100,
      padding: const EdgeInsets.all(8.0),
      child: const Row(
        mainAxisAlignment: MainAlignment.center,
        children: [
          Icon(Icons.offline_bolt, color: Colors.orange),
          SizedBox(width: 8),
          Text('Viewing offline cached data'),
        ],
      ),
    );
  },
  onRefresh: () => context.read<ProductPaginationBloc>().add(const StrataPaginationRefreshed()),
  onLoadMore: () => context.read<ProductPaginationBloc>().add(const StrataPaginationMoreFetched()),
  scrollableBuilder: (context, scrollController, items) {
    return ListView.builder(
      key: const Key('strata_pagination_list'),
      controller: scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) => ProductTile(product: items[index]),
    );
  },
);
```

### Example 6: Custom Empty, Loading Skeleton, and Page-N Inline Retry Footer
Provides custom skeletonizer shapes during initial load, a custom empty state widget, and a custom inline bottom retry bar on incremental fetch failure.

```dart
StrataPaginationWidget<ProductItem, PaginationMetaModel>(
  state: state,
  onRefresh: () => context.read<ProductPaginationBloc>().add(const StrataPaginationRefreshed()),
  onLoadMore: () => context.read<ProductPaginationBloc>().add(const StrataPaginationMoreFetched()),
  emptyBuilder: (context) => const Center(
    child: Text('No products found matching your search.'),
  ),
  skeletonBuilder: (context) => ListView.builder(
    itemCount: 6,
    itemBuilder: (context, index) => const CardSkeletonTile(),
  ),
  retryMoreBuilder: (context, failure, onRetryMore) {
    return Container(
      key: const Key('strata_pagination_retry_button'),
      padding: const EdgeInsets.all(12.0),
      color: Colors.red.shade50,
      child: Row(
        mainAxisAlignment: MainAlignment.spaceBetween,
        children: [
          Text('Failed to load next page: ${failure.message}'),
          ElevatedButton(
            onPressed: onRetryMore,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  },
  scrollableBuilder: (context, scrollController, items) {
    return ListView.builder(
      key: const Key('strata_pagination_list'),
      controller: scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) => ProductTile(product: items[index]),
    );
  },
);
```

## Acceptance criteria
- [x] `easy_refresh` package is completely removed from `strata_ui/pubspec.yaml` and code.
- [x] Internal state fetching (`onFetchPage`) is deprecated/removed in favor of `StrataPaginationState` / BLoC driven UI.
- [x] Native pull-to-refresh (`RefreshIndicator.adaptive`) and `NotificationListener<ScrollNotification>` infinite scroll threshold logic are implemented.
- [x] Exactly one of `scrollableBuilder`, `sliversBuilder`, or `customBuilder` is enforced via constructor assertions.
- [x] Full-screen `Skeletonizer` renders on initial load, and a bottom tile/spinner renders during load-more.
- [x] Inline bottom retry bar renders on page-N fetch failure (`PaginationPageFetchFailure`) without resetting scroll offset.
- [x] Desktop/web features (`Ctrl+R` / `Cmd+R` refresh shortcut, `Scrollbar`, resize state retention) are implemented.
- [x] Offline/cached data banner/badge renders when `isFromCache` or `isOffline` is true.
- [x] 100% executable DartDoc with `@example` snippets is provided for all public UI pagination classes.
- [x] Native Flutter `testWidgets` tests in `strata_ui/test/` verify pull-to-refresh, infinite scroll, page-N retry, and key accessibility.

## Covers
- User Stories: 2, 3, 4, 5
- Requirements: 4, 5
- Testing Strategy: 3, 4
- Interview Ledger: L1, L2, L3, L4, L6, L7, L8

## Blocked by
1, 3
