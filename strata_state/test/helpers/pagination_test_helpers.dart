import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_state/strata_state.dart';

/// Standard test entity implementing [Identifiable] for state testing.
class TestItem extends Equatable implements Identifiable<String> {
  /// Creates a [TestItem].
  const TestItem(this.id, {this.name = ''});

  @override
  final String id;

  /// Display name property.
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Helper function generating a list of [TestItem] instances.
List<TestItem> createTestItems(
  int count, {
  int startId = 1,
  String namePrefix = 'Item',
}) {
  return List.generate(
    count,
    (index) => TestItem(
      '${startId + index}',
      name: '$namePrefix ${startId + index}',
    ),
  );
}

/// Helper function constructing a [PaginationResponseModel] instance.
PaginationResponseModel<TestItem, NoMetaModel> createTestResponse({
  required List<TestItem> items,
  NoMetaModel? meta,
  String? nextCursor,
}) {
  return PaginationResponseModel<TestItem, NoMetaModel>(
    data: items,
    meta: meta,
    nextCursor: nextCursor,
  );
}

/// Helper function constructing a successful [Either] pagination result.
Future<Either<Failure, PaginationResponseModel<TestItem, NoMetaModel>>>
    createSuccessFuture(List<TestItem> items) async {
  return Right(createTestResponse(items: items));
}

/// Helper function constructing a failed [Either] pagination result.
Future<Either<Failure, PaginationResponseModel<TestItem, NoMetaModel>>>
    createFailureFuture(Failure failure) async {
  return Left(failure);
}

/// Reusable mock cancellation manager for state tests.
class MockCancelManager extends Mock implements CancelRequestManagerInterface {}

/// Reusable mock caching adapter for state tests.
class MockCacheAdapter extends Mock
    implements PaginationCacheAdapterInterface<TestItem, NoMetaModel> {}
