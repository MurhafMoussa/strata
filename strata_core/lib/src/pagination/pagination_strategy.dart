import '../models/pagination_response_model.dart';
import 'pagination_params.dart';
import 'pagination_params_interface.dart';

export 'pagination_params.dart';

/// Pure, state-free pagination strategy abstraction.
///
/// Implementations calculate initial and subsequent page request parameters as pure functions
/// without maintaining mutable internal state.
///
/// Generic parameter [P] represents the parameter model passed to data fetchers,
/// constrained to [PaginationParamsInterface] so every parameter model exposes
/// a type-safe [PaginationParamsInterface.requestId].
///
/// `@example`
/// ```dart
/// const strategy = PagePaginationStrategy();
/// final initialParams = strategy.getInitialParams(limit: 20);
/// final nextParams = strategy.getNextParams<String, NoMetaModel>(
///   currentItems: List.generate(20, (i) => 'Item $i'),
///   limit: 20,
/// );
/// print(nextParams?.page); // 2
/// ```
abstract class PaginationStrategy<P extends PaginationParamsInterface> {
  /// Const constructor for pure value strategies.
  const PaginationStrategy();

  /// Calculates initial parameters for the first page request.
  P getInitialParams({required int limit});

  /// Calculates next page parameters based on [currentItems], optional [meta], and [nextCursor].
  ///
  /// Returns `null` when maximum pages/items have been reached or no further data is available.
  P? getNextParams<T, M extends MetaModel>({
    required List<T> currentItems,
    M? meta,
    String? nextCursor,
    required int limit,
  });
}

/// Pure, state-free strategy for 1-based page number pagination.
///
/// Generates parameter instances of type [PagePaginationParams].
///
/// `@example`
/// ```dart
/// const strategy = PagePaginationStrategy();
/// final initial = strategy.getInitialParams(limit: 20);
/// print(initial.page); // 1
///
/// final next = strategy.getNextParams<String, NoMetaModel>(
///   currentItems: List.generate(20, (i) => 'Item $i'),
///   limit: 20,
/// );
/// print(next?.page); // 2
/// ```
class PagePaginationStrategy extends PaginationStrategy<PagePaginationParams> {
  /// Creates a [PagePaginationStrategy].
  ///
  /// If [createParams] is provided, it is used to generate custom parameter instances.
  const PagePaginationStrategy({
    this.createParams,
  });

  /// Optional factory function to create custom parameter objects.
  final PagePaginationParams Function({required int page, required int limit})? createParams;

  PagePaginationParams _buildParams({required int page, required int limit}) {
    final builder = createParams;
    if (builder != null) {
      return builder(page: page, limit: limit);
    }
    return PagePaginationParams(page: page, limit: limit);
  }

  @override
  PagePaginationParams getInitialParams({required int limit}) {
    return _buildParams(page: 1, limit: limit);
  }

  @override
  PagePaginationParams? getNextParams<T, M extends MetaModel>({
    required List<T> currentItems,
    M? meta,
    String? nextCursor,
    required int limit,
  }) {
    if (currentItems.isEmpty) return null;
    if (currentItems.length % limit != 0) return null;

    if (meta is PaginationMetaModel && meta.totalCount != null) {
      if (currentItems.length >= meta.totalCount!) return null;
    }

    final nextPage = (currentItems.length ~/ limit) + 1;
    return _buildParams(page: nextPage, limit: limit);
  }
}

/// Pure, state-free strategy for skip/limit offset based pagination.
///
/// Generates parameter instances of type [SkipPaginationParams].
///
/// `@example`
/// ```dart
/// const strategy = SkipPaginationStrategy();
/// final initial = strategy.getInitialParams(limit: 20);
/// print(initial.skip); // 0
///
/// final next = strategy.getNextParams<String, NoMetaModel>(
///   currentItems: List.generate(20, (i) => 'Item $i'),
///   limit: 20,
/// );
/// print(next?.skip); // 20
/// ```
class SkipPaginationStrategy extends PaginationStrategy<SkipPaginationParams> {
  /// Creates a [SkipPaginationStrategy].
  ///
  /// If [createParams] is provided, it is used to generate custom parameter instances.
  const SkipPaginationStrategy({
    this.createParams,
  });

  /// Optional factory function to create custom parameter objects.
  final SkipPaginationParams Function({required int skip, required int limit})? createParams;

  SkipPaginationParams _buildParams({required int skip, required int limit}) {
    final builder = createParams;
    if (builder != null) {
      return builder(skip: skip, limit: limit);
    }
    return SkipPaginationParams(skip: skip, limit: limit);
  }

  @override
  SkipPaginationParams getInitialParams({required int limit}) {
    return _buildParams(skip: 0, limit: limit);
  }

  @override
  SkipPaginationParams? getNextParams<T, M extends MetaModel>({
    required List<T> currentItems,
    M? meta,
    String? nextCursor,
    required int limit,
  }) {
    if (currentItems.isEmpty) return null;
    if (currentItems.length % limit != 0) return null;

    if (meta is PaginationMetaModel && meta.totalCount != null) {
      if (currentItems.length >= meta.totalCount!) return null;
    }

    final nextSkip = currentItems.length;
    return _buildParams(skip: nextSkip, limit: limit);
  }
}

/// Pure, state-free strategy for opaque cursor/keyset based pagination.
///
/// Generates parameter instances of type [CursorPaginationParams].
///
/// `@example`
/// ```dart
/// const strategy = CursorPaginationStrategy();
/// final initial = strategy.getInitialParams(limit: 20);
/// print(initial.cursor); // null
///
/// final next = strategy.getNextParams<String, NoMetaModel>(
///   currentItems: List.generate(20, (i) => 'Item $i'),
///   nextCursor: 'cursor_xyz',
///   limit: 20,
/// );
/// print(next?.cursor); // 'cursor_xyz'
/// ```
class CursorPaginationStrategy extends PaginationStrategy<CursorPaginationParams> {
  /// Creates a [CursorPaginationStrategy].
  ///
  /// [initialCursor] optional token used on the initial page fetch.
  /// If [createParams] is provided, it is used to generate custom parameter instances.
  const CursorPaginationStrategy({
    this.initialCursor,
    this.createParams,
  });

  /// Optional initial cursor token.
  final String? initialCursor;

  /// Optional factory function to create custom parameter objects.
  final CursorPaginationParams Function({String? cursor, required int limit})? createParams;

  CursorPaginationParams _buildParams({String? cursor, required int limit}) {
    final builder = createParams;
    if (builder != null) {
      return builder(cursor: cursor, limit: limit);
    }
    return CursorPaginationParams(cursor: cursor, limit: limit);
  }

  @override
  CursorPaginationParams getInitialParams({required int limit}) {
    return _buildParams(cursor: initialCursor, limit: limit);
  }

  @override
  CursorPaginationParams? getNextParams<T, M extends MetaModel>({
    required List<T> currentItems,
    M? meta,
    String? nextCursor,
    required int limit,
  }) {
    if (currentItems.isEmpty) return null;
    if (nextCursor == null || nextCursor.isEmpty) return null;

    if (meta is PaginationMetaModel && meta.totalCount != null) {
      if (currentItems.length >= meta.totalCount!) return null;
    }

    if (currentItems.length % limit != 0) return null;

    return _buildParams(cursor: nextCursor, limit: limit);
  }
}
