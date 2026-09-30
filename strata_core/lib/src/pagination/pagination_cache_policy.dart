/// Represents the caching policy strategy when fetching paginated data.
///
/// Controls how local cached records and remote network requests interact.
///
/// `@example`
/// ```dart
/// const policy = PaginationCachePolicy.cacheFirst;
/// print(policy.usesCache); // true
/// print(policy.requestsNetwork); // true
/// ```
enum PaginationCachePolicy {
  /// Always fetch fresh data from network, ignoring local cache.
  networkOnly,

  /// Read from local cache first; perform network fetch only if cache is absent or expired.
  cacheFirst,

  /// Emit local cached data immediately if available, then execute background network fetch
  /// to refresh cache and emit updated results.
  cacheAndNetwork;

  /// Returns `true` if this policy reads from local cache.
  bool get usesCache => this == cacheFirst || this == cacheAndNetwork;

  /// Returns `true` if this policy executes network requests.
  bool get requestsNetwork =>
      this == networkOnly || this == cacheFirst || this == cacheAndNetwork;
}
