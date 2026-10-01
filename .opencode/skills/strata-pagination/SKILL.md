---
name: strata-pagination
description: Implement infinite scrolling and pagination using StrataPaginationBloc and StrataPaginationWidget, supporting Page, Skip, and Cursor strategies, offline caching, and companion unit tests.
---

# Strata Pagination Skill

Implement high-performance, pull-to-refresh infinite scrolling lists using `StrataPaginationBloc` and `StrataPaginationWidget`.

---

## 🛠️ Step-by-Step Workflow

### Step 1: Dependencies Verification
Inspect `pubspec.yaml` and ensure required packages exist:
```bash
flutter pub add flutter_bloc
flutter pub add -d bloc_test mocktail
```

---

### Step 2: Pagination Scheme Selection
Determine the pagination mechanic used by the target API endpoint:
- **Page Scheme** (`page`, `limit`, `totalCount`): Use `PagePaginationStrategy` and `PagePaginationParams`.
- **Skip/Offset Scheme** (`skip`, `limit`, `totalCount`): Use `SkipPaginationStrategy` and `SkipPaginationParams`.
- **Cursor Scheme** (`cursor`, `limit`): Use `CursorPaginationStrategy` and `CursorPaginationParams`.
*(All pagination parameters inherit from the unified `PaginationParams` in `strata_core`, implement `PaginationParamsInterface`, and support optional `extra` query filters and `.toQueryParameters()`)*

*Tip*: If unsure, inspect a sample backend response JSON:
```json
// Example Page-based JSON:
{ "data": [...], "meta": { "page": 1, "limit": 20, "total_count": 100 } }
// Example Cursor-based JSON:
{ "data": [...], "meta": { "cursor": "eyJpZCI6MTAwfQ==", "limit": 20 } }
```

---

### Step 3: Greenfield Scaffolding

Given an entity (e.g. `Order`):

#### 1. Entity Implementing `Identifiable<String>`
`lib/features/orders/domain/entities/order_entity.dart`:
```dart
import 'package:equatable/equatable.dart';
import 'package:strata/strata.dart';

class OrderEntity extends Equatable implements Identifiable<String> {
  const OrderEntity({
    required this.id,
    required this.title,
    required this.amount,
  });

  final String id;
  final String title;
  final double amount;

  @override
  String get identifier => id; // Used by Strata for O(N) deduplication

  @override
  List<Object?> get props => [id, title, amount];
}
```

#### 2. BLoC Factory Instantiation
`lib/features/orders/presentation/blocs/orders_pagination_bloc.dart`:
```dart
import 'package:strata/strata.dart';
import '../../domain/entities/order_entity.dart';

StrataPaginationBloc<OrderEntity, PaginationMetaModel, PagePaginationParams> createOrdersPaginationBloc({
  required ApiHandlerInterface apiHandler,
  CancelRequestManagerInterface? cancelRequestManager,
  PaginationCacheAdapterInterface<OrderEntity, PaginationMetaModel>? cacheAdapter,
  PaginationCachePolicy cachePolicy = PaginationCachePolicy.networkOnly,
}) {
  return StrataPaginationBloc<OrderEntity, PaginationMetaModel, PagePaginationParams>(
    paginationStrategy: const PagePaginationStrategy(),
    cancelRequestManager: cancelRequestManager,
    cacheAdapter: cacheAdapter,
    cachePolicy: cachePolicy,
    fetcher: (params, {requestId}) async {
      return apiHandler.get<PaginationResponseModel<OrderEntity, PaginationMetaModel>>(
        '/orders',
        queryParameters: {
          'page': params.page,
          'limit': params.limit,
        },
        requestId: requestId,
        parser: (json) {
          final data = (json['data'] as List)
              .map((item) => OrderEntity(
                    id: item['id'] as String,
                    title: item['title'] as String,
                    amount: (item['amount'] as num).toDouble(),
                  ))
              .toList();
          final meta = PaginationMetaModel.fromJson(
            json['meta'] as Map<String, dynamic>? ?? {},
          );
          return PaginationResponseModel(data: data, meta: meta);
        },
      );
    },
  );
}
```

#### 3. Presentation with `StrataPaginationWidget`
`lib/features/orders/presentation/pages/orders_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strata/strata.dart';
import '../../domain/entities/order_entity.dart';
import '../blocs/orders_pagination_bloc.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => createOrdersPaginationBloc(
        apiHandler: GetIt.I<ApiHandlerInterface>(),
      )..add(const StrataPaginationInitialFetched()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: BlocBuilder<
          StrataPaginationBloc<OrderEntity, PaginationMetaModel, PagePaginationParams>,
          StrataPaginationState<OrderEntity, PaginationMetaModel>
        >(
          builder: (context, state) {
            final bloc = context.read<
              StrataPaginationBloc<OrderEntity, PaginationMetaModel, PagePaginationParams>
            >();

            return StrataPaginationWidget<OrderEntity, PaginationMetaModel>(
              state: state,
              onRefresh: () async => bloc.add(const StrataPaginationRefreshed()),
              onLoadMore: () async => bloc.add(const StrataPaginationMoreFetched()),
              onRetry: () => bloc.add(const StrataPaginationInitialFetched()),
              onRetryMore: () => bloc.add(const StrataPaginationMoreFetched()),
              scrollableBuilder: (context, scrollController, items) {
                return ListView.separated(
                  key: const Key('strata_pagination_list'),
                  controller: scrollController,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final order = items[index];
                    return ListTile(
                      title: Text(order.title),
                      subtitle: Text('ID: ${order.id}'),
                      trailing: Text('\$${order.amount.toStringAsFixed(2)}'),
                    );
                  },
                );
              },
              emptyBuilder: (context) => const Center(
                child: Text('No orders found'),
              ),
              errorBuilder: (context, failure, onRetry) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load: ${failure.message}'),
                    if (onRetry != null)
                      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

### Step 4: Companion Unit Tests
Create `test/features/orders/presentation/blocs/orders_pagination_bloc_test.dart`:
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata/strata.dart';

import 'package:my_app/features/orders/domain/entities/order_entity.dart';
import 'package:my_app/features/orders/presentation/blocs/orders_pagination_bloc.dart';

class MockApiHandler extends Mock implements ApiHandlerInterface {}

void main() {
  late MockApiHandler mockApiHandler;

  setUpAll(() {
    registerFallbackValue(
      const PaginationResponseModel<OrderEntity, PaginationMetaModel>(),
    );
  });

  setUp(() {
    mockApiHandler = MockApiHandler();
  });

  const tOrders = [
    OrderEntity(id: '1', title: 'Order 1', amount: 10.0),
    OrderEntity(id: '2', title: 'Order 2', amount: 20.0),
  ];

  const tResponse = PaginationResponseModel<OrderEntity, PaginationMetaModel>(
    data: tOrders,
    meta: PaginationMetaModel(page: 1, limit: 20, totalCount: 2),
  );

  blocTest<
    StrataPaginationBloc<OrderEntity, PaginationMetaModel, PagePaginationParams>,
    StrataPaginationState<OrderEntity, PaginationMetaModel>
  >(
    'emits [loading, succeeded] on initial fetch',
    build: () {
      when(() => mockApiHandler.get<PaginationResponseModel<OrderEntity, PaginationMetaModel>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            requestId: any(named: 'requestId'),
            parser: any(named: 'parser'),
          )).thenAnswer((_) async => const Right(tResponse));

      return createOrdersPaginationBloc(apiHandler: mockApiHandler);
    },
    act: (bloc) => bloc.add(const StrataPaginationInitialFetched()),
    expect: () => [
      const StrataPaginationState<OrderEntity, PaginationMetaModel>.loading(),
      const StrataPaginationState<OrderEntity, PaginationMetaModel>.succeeded(
        paginatedResponseModel: tResponse,
        hasReachedMax: true,
      ),
    ],
  );
}
```

---

### Step 5: Verification & Compilation
Run static analysis and test validation:
```bash
flutter analyze
flutter test test/features/<feature_name>
```

**Completion Criteria**: Zero analyzer warnings, exactly one layout builder provided (`scrollableBuilder`), and pagination BLoC tests pass with complete state coverage.
