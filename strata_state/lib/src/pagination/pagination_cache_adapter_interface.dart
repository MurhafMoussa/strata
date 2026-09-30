import 'package:strata_core/strata_core.dart';

/// Abstract contract for pluggable offline caching of paginated responses.
///
/// Implementations handle loading, persisting, and clearing paginated data models
/// from local persistence layers (e.g. Hive, SQLite, or SharedPreferences).
///
/// `@example`
/// ```dart
/// class InMemoryCacheAdapter<T extends Identifiable<String>, M extends MetaModel>
///     extends PaginationCacheAdapterInterface<T, M> {
///   final Map<String, PaginationResponseModel<T, M>> _storage = {};
///
///   @override
///   Future<PaginationResponseModel<T, M>?> loadCache(String key) async {
///     return _storage[key];
///   }
///
///   @override
///   Future<void> saveCache(
///     String key,
///     PaginationResponseModel<T, M> response,
///   ) async {
///     _storage[key] = response;
///   }
///
///   @override
///   Future<void> clearCache(String key) async {
///     _storage.remove(key);
///   }
/// }
/// ```
abstract class PaginationCacheAdapterInterface<
    T extends Identifiable<String>, M extends MetaModel> {
  /// Const constructor for [PaginationCacheAdapterInterface].
  const PaginationCacheAdapterInterface();

  /// Loads cached [PaginationResponseModel] for the given [key].
  Future<PaginationResponseModel<T, M>?> loadCache(String key);

  /// Saves [response] to local storage using [key].
  Future<void> saveCache(String key, PaginationResponseModel<T, M> response);

  /// Clears cached data for the given [key].
  Future<void> clearCache(String key);
}
