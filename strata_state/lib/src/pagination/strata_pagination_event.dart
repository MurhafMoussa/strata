import 'package:equatable/equatable.dart';
import 'package:strata_core/strata_core.dart';

/// Sealed hierarchy of all events processed by [StrataPaginationBloc].
///
/// `@example`
/// ```dart
/// const fetchEvent = StrataPaginationInitialFetched<TestItem>(limit: 20);
/// const moreEvent = StrataPaginationMoreFetched<TestItem>(limit: 20);
/// const filterEvent = StrataPaginationFilterUpdated<TestItem>(extra: {'status': 'active'});
/// ```
sealed class StrataPaginationEvent<T extends Identifiable<String>> extends Equatable {
  /// Const constructor for [StrataPaginationEvent].
  const StrataPaginationEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to trigger initial data fetching or a full reset-and-fetch.
class StrataPaginationInitialFetched<T extends Identifiable<String>>
    extends StrataPaginationEvent<T> {
  /// Creates a [StrataPaginationInitialFetched] event.
  const StrataPaginationInitialFetched({
    this.limit = 20,
    this.extra,
    this.cachePolicy,
  });

  /// Limit parameter for initial fetch.
  final int limit;

  /// Optional extra query filters.
  final Map<String, dynamic>? extra;

  /// Optional cache policy override.
  final PaginationCachePolicy? cachePolicy;

  @override
  List<Object?> get props => [limit, extra, cachePolicy];
}

/// Dispatched during user pull-to-refresh to fetch page 1 while retaining current items.
class StrataPaginationRefreshed<T extends Identifiable<String>>
    extends StrataPaginationEvent<T> {
  /// Creates a [StrataPaginationRefreshed] event.
  const StrataPaginationRefreshed({
    this.limit = 20,
    this.extra,
  });

  /// Limit parameter for refresh fetch.
  final int limit;

  /// Optional extra query filters.
  final Map<String, dynamic>? extra;

  @override
  List<Object?> get props => [limit, extra];
}

/// Dispatched when user scrolls near list end to request the next page of items.
class StrataPaginationMoreFetched<T extends Identifiable<String>>
    extends StrataPaginationEvent<T> {
  /// Creates a [StrataPaginationMoreFetched] event.
  const StrataPaginationMoreFetched({
    this.limit = 20,
  });

  /// Limit parameter for incremental page fetch.
  final int limit;

  @override
  List<Object?> get props => [limit];
}

/// Dispatched when user changes search query or filters to restart pagination.
class StrataPaginationFilterUpdated<T extends Identifiable<String>>
    extends StrataPaginationEvent<T> {
  /// Creates a [StrataPaginationFilterUpdated] event.
  const StrataPaginationFilterUpdated({
    this.extra,
    this.limit = 20,
  });

  /// Updated extra query filter map.
  final Map<String, dynamic>? extra;

  /// Limit parameter.
  final int limit;

  @override
  List<Object?> get props => [extra, limit];
}

/// Dispatched to optimistically add an item to the current state.
class StrataPaginationItemAdded<T extends Identifiable<String>>
    extends StrataPaginationEvent<T> {
  /// Creates a [StrataPaginationItemAdded] event.
  const StrataPaginationItemAdded(
    this.item, {
    this.atFirst = false,
  });

  /// The item instance to add.
  final T item;

  /// True to prepend at index 0, false to append at list end.
  final bool atFirst;

  @override
  List<Object?> get props => [item, atFirst];
}

/// Dispatched to optimistically update an item in state matching [item.id].
class StrataPaginationItemUpdated<T extends Identifiable<String>>
    extends StrataPaginationEvent<T> {
  /// Creates a [StrataPaginationItemUpdated] event.
  const StrataPaginationItemUpdated(this.item);

  /// The updated item instance.
  final T item;

  @override
  List<Object?> get props => [item];
}

/// Dispatched to optimistically remove an item from state matching [id].
class StrataPaginationItemDeleted<T extends Identifiable<String>>
    extends StrataPaginationEvent<T> {
  /// Creates a [StrataPaginationItemDeleted] event.
  const StrataPaginationItemDeleted(this.id);

  /// Unique identifier of the item to delete.
  final String id;

  @override
  List<Object?> get props => [id];
}
