---
name: strata-pagination
description: Implement infinite scrolling and pagination using StrataPaginationBloc and StrataPaginationWidget, supporting Page, Offset, and Cursor strategies, offline caching, and companion unit tests.
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
- **Page Scheme** (`page`, `pageSize`, `totalPages`): Use `PagePaginationStrategy`.
- **Offset Scheme** (`offset`, `limit`, `total`): Use `OffsetPaginationStrategy`.
- **Cursor Scheme** (`cursor`, `nextCursor`): Use `CursorPaginationStrategy`.

*Tip*: If unsure, inspect a sample backend response JSON:
```json
// Example Page-based JSON:
{ "data": [...], "meta": { "page": 1, "total_pages": 5 } }
// Example Cursor-based JSON:
{ "items": [...], "next_cursor": "eyJpZCI6MTAwfQ==" }
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

#### 2. Pagination Request Params
`lib/features/orders/data/models/order_pagination_params.dart`:
```dart
import 'package:strata/strata.dart';

class OrderPaginationParams implements PaginationParamsInterface {
  const OrderPaginationParams({
    required this.page,
    required this.pageSize,
    this.requestId,
  });

  final int page;
  final int pageSize;

  @override
  final String? requestId;

  @override
  OrderPaginationParams copyWith({String? requestId}) {
    return OrderPaginationParams(
      page: page,
      pageSize: pageSize,
      requestId: requestId ?? this.requestId,
    );
  }
}
```

#### 3. BLoC Instantiation
`lib/features/orders/presentation/blocs/orders_pagination_bloc.dart`:
```dart
import 'package:strata/strata.dart';
import '../../domain/entities/order_entity.dart';
import '../models/order_pagination_params.dart';

StrataPaginationBloc<OrderEntity, PageMetaModel, OrderPaginationParams> createOrdersPaginationBloc({
  required ApiHandlerInterface apiHandler,
  CancelRequestManagerInterface? cancelRequestManager,
}) {
  return StrataPaginationBloc<OrderEntity, PageMetaModel, OrderPaginationParams>(
    cancelRequestManager: cancelRequestManager,
    paginationStrategy: PagePaginationStrategy<OrderPaginationParams>(
      initialParams: const OrderPaginationParams(page: 1, pageSize: 20),
      computeNextPage: (currentParams, lastResponse) {
        final currentPage = currentParams.page;
        final totalPages = lastResponse.meta.totalPages;
        if (currentPage >= totalPages) return null; // No more pages
        return OrderPaginationParams(
          page: currentPage + 1,
          pageSize: currentParams.pageSize,
        );
      },
    ),
    fetcher: (params, {requestId}) async {
      return apiHandler.get<PaginationResponseModel<OrderEntity, PageMetaModel>>(
        '/orders',
        queryParameters: {
          'page': params.page,
          'limit': params.pageSize,
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
          final meta = PageMetaModel(
            currentPage: json['meta']['page'] as int,
            totalPages: json['meta']['total_pages'] as int,
            totalItems: json['meta']['total'] as int,
          );
          return PaginationResponseModel(data: data, meta: meta);
        },
      );
    },
  );
}
```

#### 4. Presentation with `StrataPaginationWidget`
`lib/features/orders/presentation/pages/orders_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:strata/strata.dart';
import '../../domain/entities/order_entity.dart';
import '../blocs/orders_pagination_bloc.dart';
import '../models/order_pagination_params.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final StrataPaginationBloc<OrderEntity, PageMetaModel, OrderPaginationParams> _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = createOrdersPaginationBloc(apiHandler: GetIt.I<ApiHandlerInterface>());
    _bloc.add(const StrataPaginationInitialFetched());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: StrataPaginationWidget<OrderEntity, PageMetaModel>(
        bloc: _bloc,
        itemBuilder: (context, order, index) => ListTile(
          title: Text(order.title),
          subtitle: Text('ID: ${order.id}'),
          trailing: Text('\$${order.amount.toStringAsFixed(2)}'),
        ),
        emptyBuilder: (context) => const Center(
          child: Text('No orders found'),
        ),
        errorBuilder: (context, failure, onRetry) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load: ${failure.message}'),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
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
import 'package:my_app/features/orders/data/models/order_pagination_params.dart';

class MockApiHandler extends Mock implements ApiHandlerInterface {}

void main() {
  late MockApiHandler mockApiHandler;

  setUp(() {
    mockApiHandler = MockApiHandler();
  });

  const tOrders = [
    OrderEntity(id: '1', title: 'Order 1', amount: 10.0),
    OrderEntity(id: '2', title: 'Order 2', amount: 20.0),
  ];

  final tResponse = PaginationResponseModel<OrderEntity, PageMetaModel>(
    data: tOrders,
    meta: const PageMetaModel(currentPage: 1, totalPages: 2, totalItems: 4),
  );

  blocTest<
    StrataPaginationBloc<OrderEntity, PageMetaModel, OrderPaginationParams>,
    StrataPaginationState<OrderEntity, PageMetaModel>
  >(
    'emits [loading, succeeded] on initial fetch',
    build: () {
      when(() => mockApiHandler.get<PaginationResponseModel<OrderEntity, PageMetaModel>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            requestId: any(named: 'requestId'),
            parser: any(named: 'parser'),
          )).thenAnswer((_) async => Right(tResponse));

      return StrataPaginationBloc<OrderEntity, PageMetaModel, OrderPaginationParams>(
        paginationStrategy: PagePaginationStrategy(
          initialParams: const OrderPaginationParams(page: 1, pageSize: 20),
          computeNextPage: (current, res) => null,
        ),
        fetcher: (params, {requestId}) => mockApiHandler.get(
          '/orders',
          queryParameters: {'page': params.page},
          requestId: requestId,
        ),
      );
    },
    act: (bloc) => bloc.add(const StrataPaginationInitialFetched()),
    expect: () => [
      predicate<StrataPaginationState<OrderEntity, PageMetaModel>>(
        (s) => s.status == PaginationStatus.loading,
      ),
      predicate<StrataPaginationState<OrderEntity, PageMetaModel>>(
        (s) => s.status == PaginationStatus.succeeded && s.items == tOrders,
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

**Completion Criteria**: Zero analyzer warnings, and pagination BLoC tests pass with complete state coverage (`loading`, `succeeded`, `loadingMore`, `failed`).
