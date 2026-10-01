---
name: strata-feature
description: Scaffold or refactor a feature using Feature-First Clean Architecture in Strata, including ResultFutureUseCase, ApiHandlerInterface, AsyncHostMixin, AsyncHandler, AsyncBuilder, and companion bloc_test suites.
---

# Strata Feature Skill

Scaffold a production-grade, test-backed feature slice conforming to Strata's Feature-First Clean Architecture.

---

## 🛠️ Step-by-Step Workflow

### Step 1: Autonomous Dependency Inspection
Inspect `pubspec.yaml`. Automatically add any missing packages:
```bash
flutter pub add flutter_bloc fpdart
flutter pub add -d bloc_test mocktail
```

---

### Step 2: Autonomous Greenfield vs. Refactor Detection
Inspect the target directory `lib/features/<feature_name>/`:
- **Greenfield**: If empty or missing, proceed to **Step 3 (Greenfield Generation)**.
- **Refactor**: If existing feature code is found:
  1. Inspect existing models and API calls; convert raw `http`/`dio` calls to `GetIt.I<ApiHandlerInterface>()`.
  2. Ensure domain contracts use `ResultFuture<T>` (`Future<Either<Failure, T>>`).
  3. Refactor state classes to contain `AsyncState<T>`.
  4. Add `with AsyncHostMixin<State>` to the BLoC/Cubit and replace manual loading/error handling with `createAsyncHandler`.
  5. Refactor UI widgets to use `AsyncBuilder`.
  6. Jump to **Step 4 (Tests)** and **Step 5 (Verification)**.

---

### Step 3: Greenfield Scaffolding

Given a feature name (e.g., `product`), scaffold the following files:

#### 1. Domain Layer (`lib/features/product/domain/`)

`entities/product_entity.dart`:
```dart
import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;

  @override
  List<Object?> get props => [id, name, price];
}
```

`repositories/product_repository_interface.dart`:
```dart
import 'package:strata/strata.dart';
import '../entities/product_entity.dart';

abstract class ProductRepositoryInterface {
  ResultFuture<ProductEntity> getProduct(String id);
}
```

`usecases/get_product_usecase.dart`:
```dart
import 'package:equatable/equatable.dart';
import 'package:strata/strata.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository_interface.dart';

// For custom parameter models, extend Equatable:
class GetProductParams extends Equatable {
  const GetProductParams({required this.id});
  final String id;

  @override
  List<Object?> get props => [id];
}

// Note: For simple single ID operations or parameterless use cases,
// you can directly use `IdParam` or `NoParams` from `package:strata_core/strata_core.dart`.

class GetProductUseCase extends ResultFutureUseCase<ProductEntity, GetProductParams> {
  const GetProductUseCase(this._repository);
  final ProductRepositoryInterface _repository;

  @override
  ResultFuture<ProductEntity> call(GetProductParams input) {
    return _repository.getProduct(input.id);
  }
}
```

#### 2. Data Layer (`lib/features/product/data/`)

`models/product_model.dart`:
```dart
import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
  };
}
```

`repositories/product_repository.dart`:
```dart
import 'package:strata/strata.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository_interface.dart';
import '../models/product_model.dart';

class ProductRepository implements ProductRepositoryInterface {
  ProductRepository(this._apiHandler);
  final ApiHandlerInterface _apiHandler;

  @override
  ResultFuture<ProductEntity> getProduct(String id) {
    return _apiHandler.get<ProductEntity>(
      '/products/$id',
      parser: (json) => ProductModel.fromJson(json as Map<String, dynamic>),
      isAuthorized: true,
      requestId: 'get-product-$id',
    );
  }
}
```

#### 3. Presentation Layer (`lib/features/product/presentation/`)

`blocs/product_state.dart`:
```dart
import 'package:equatable/equatable.dart';
import 'package:strata/strata.dart';
import '../../domain/entities/product_entity.dart';

class ProductState extends Equatable {
  const ProductState({
    this.productState = const AsyncState.initial(),
  });

  final AsyncState<ProductEntity> productState;

  ProductState copyWith({
    AsyncState<ProductEntity>? productState,
  }) {
    return ProductState(
      productState: productState ?? this.productState,
    );
  }

  @override
  List<Object?> get props => [productState];
}
```

`blocs/product_bloc.dart`:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strata/strata.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_product_usecase.dart';
import 'product_state.dart';

abstract class ProductEvent {}
class ProductFetchRequested extends ProductEvent {
  ProductFetchRequested(this.id);
  final String id;
}

class ProductBloc extends Bloc<ProductEvent, ProductState>
    with AsyncHostMixin<ProductState> {
  ProductBloc(this._getProductUseCase) : super(const ProductState()) {
    _productHandler = createAsyncHandler<ProductEntity>(
      getAsyncState: (state) => state.productState,
      setAsyncState: (state, asyncState) => state.copyWith(productState: asyncState),
    );

    on<ProductFetchRequested>((event, emit) async {
      await _productHandler.execute(
        () => _getProductUseCase(GetProductParams(id: event.id)),
      );
    });
  }

  final GetProductUseCase _getProductUseCase;
  late final AsyncHandler<ProductState, ProductEntity> _productHandler;
}
```

`pages/product_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strata/strata.dart';
import '../../domain/entities/product_entity.dart';
import '../blocs/product_bloc.dart';
import '../blocs/product_state.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductBloc>();

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: AsyncBuilder<ProductState, ProductEntity>(
        bloc: bloc,
        getAsyncState: (state) => state.productState,
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        errorBuilder: (context, failure, retry) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: ${failure.message}'),
              if (retry != null)
                ElevatedButton(onPressed: retry, child: const Text('Retry')),
            ],
          ),
        ),
        successBuilder: (context, product) => Center(
          child: Text('Product: ${product.name} (\$${product.price})'),
        ),
      ),
    );
  }
}
```

---

### Step 4: Companion Unit Tests
Generate `test/features/product/presentation/blocs/product_bloc_test.dart`:
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata/strata.dart';

import 'package:my_app/features/product/domain/entities/product_entity.dart';
import 'package:my_app/features/product/domain/usecases/get_product_usecase.dart';
import 'package:my_app/features/product/presentation/blocs/product_bloc.dart';
import 'package:my_app/features/product/presentation/blocs/product_state.dart';

class MockGetProductUseCase extends Mock implements GetProductUseCase {}

void main() {
  late MockGetProductUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(const GetProductParams(id: ''));
  });

  setUp(() {
    mockUseCase = MockGetProductUseCase();
  });

  const tProduct = ProductEntity(id: '1', name: 'Coffee', price: 4.5);

  blocTest<ProductBloc, ProductState>(
    'emits [loading, success] when product fetch succeeds',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => const Right(tProduct));
      return ProductBloc(mockUseCase);
    },
    act: (bloc) => bloc.add(ProductFetchRequested('1')),
    expect: () => [
      const ProductState(productState: AsyncState.loading()),
      const ProductState(productState: AsyncState.success(tProduct)),
    ],
  );

  blocTest<ProductBloc, ProductState>(
    'emits [loading, failure] when product fetch fails',
    build: () {
      when(() => mockUseCase(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Not found', code: 404)),
      );
      return ProductBloc(mockUseCase);
    },
    act: (bloc) => bloc.add(ProductFetchRequested('1')),
    expect: () => [
      const ProductState(productState: AsyncState.loading()),
      const ProductState(
        productState: AsyncState.failure(
          ServerFailure(message: 'Not found', code: 404),
        ),
      ),
    ],
  );
}
```

---

### Step 5: Verification & Compilation
Run static analysis and test execution:
```bash
flutter analyze
flutter test test/features/<feature_name>
```

**Completion Criteria**: Zero analyzer errors, clean package boundaries, and all companion tests pass.
