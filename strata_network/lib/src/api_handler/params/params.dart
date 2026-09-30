import 'package:equatable/equatable.dart';

/// Empty parameter class for requests requiring no arguments.
class const NoParams() extends Equatable {
  factory NoParams.fromJson(Map<String, dynamic> json) => const NoParams();

  Map<String, dynamic> toJson() => {};

  @override
  List<Object?> get props => [];
}

/// Simple parameter class holding a single string ID.
class const IdParam({required final String id}) extends Equatable {
  factory IdParam.fromJson(Map<String, dynamic> json) =>
      IdParam(id: json['id'] as String? ?? '');

  Map<String, dynamic> toJson({String? idKey}) => {idKey ?? 'id': id};

  @override
  List<Object?> get props => [id];
}

/// Abstract contract and sealed hierarchy for pagination request parameters.
///
/// Supports [DefaultPaginationParams] (page/batch based), [SkipPaginationParams]
/// (offset/skip based), and [CursorPaginationParams] (opaque token based).
///
/// Each variant generates an automatic [requestId] used for request keying
/// and cancellation tracking via `CancelRequestManagerInterface`.
///
/// `@example`
/// ```dart
/// const pageParams = DefaultPaginationParams(
///   page: 1,
///   limit: 20,
///   extra: {'search': 'flutter', 'status': 'active'},
/// );
/// print(pageParams.requestId); // 'default_page_1_limit_20'
/// print(pageParams.extra); // {'search': 'flutter', 'status': 'active'}
///
/// const skipParams = SkipPaginationParams(skip: 10, limit: 10);
/// print(skipParams.requestId); // 'skip_10_limit_10'
///
/// const cursorParams = CursorPaginationParams(cursor: 'abc123', limit: 20);
/// print(cursorParams.requestId); // 'cursor_abc123_limit_20'
/// ```
sealed class PaginationParams extends Equatable {
  /// Const constructor for sealed [PaginationParams] hierarchy.
  const PaginationParams();

  /// Maximum number of items requested per page/batch.
  int get limit;

  /// Unique request identifier string generated automatically for cancellation tracking.
  String get requestId;

  /// Optional dynamic filter or query parameter map.
  Map<String, dynamic>? get extra;

  /// Converts parameters into JSON query representation.
  Map<String, dynamic> toJson();

  /// Converts parameters and [extra] filter entries into a flat map for URL query parameters.
  Map<String, dynamic> toQueryParameters() {
    final queryMap = Map<String, dynamic>.from(toJson())..remove('extra');
    if (extra != null) {
      queryMap.addAll(extra!);
    }
    return queryMap;
  }

  /// Deserializes a [PaginationParams] instance from JSON based on property keys.
  factory PaginationParams.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('cursor')) {
      return CursorPaginationParams.fromJson(json);
    } else if (json.containsKey('skip')) {
      return SkipPaginationParams.fromJson(json);
    } else {
      return DefaultPaginationParams.fromJson(json);
    }
  }
}

/// Page-number based pagination parameters.
///
/// `@example`
/// ```dart
/// const params = DefaultPaginationParams(
///   page: 1,
///   limit: 20,
///   extra: {'search': 'dart', 'sort': 'asc'},
/// );
/// print(params.requestId); // 'default_page_1_limit_20'
/// print(params.toJson());
/// // {'page': 1, 'limit': 20, 'extra': {'search': 'dart', 'sort': 'asc'}}
/// ```
class DefaultPaginationParams extends PaginationParams {
  /// Creates a [DefaultPaginationParams] instance.
  ///
  /// Supports [page] (1-based index) and [limit]. Accepts optional [batch]
  /// for backward compatibility.
  const DefaultPaginationParams({
    int page = 1,
    this.limit = 10,
    int? batch,
    this.extra,
  }) : page = batch ?? page;

  /// Factory constructor to deserialize [DefaultPaginationParams] from JSON.
  factory DefaultPaginationParams.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? extraMap;
    if (json.containsKey('extra') && json['extra'] is Map<String, dynamic>) {
      extraMap = Map<String, dynamic>.from(json['extra'] as Map);
    }
    return DefaultPaginationParams(
      page: json['page'] as int? ?? json['batch'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      extra: extraMap,
    );
  }

  /// 1-based page number index.
  final int page;

  /// Backward-compatible getter for batch index (aliases [page]).
  int get batch => page;

  @override
  final int limit;

  @override
  final Map<String, dynamic>? extra;

  @override
  String get requestId => 'default_page_${page}_limit_$limit';

  @override
  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      if (extra != null) 'extra': extra,
    };
  }

  @override
  List<Object?> get props => [page, limit, extra];
}

/// Skip/offset based pagination parameters.
///
/// `@example`
/// ```dart
/// const params = SkipPaginationParams(skip: 0, limit: 20);
/// print(params.requestId); // 'skip_0_limit_20'
/// print(params.toJson()); // {'skip': 0, 'limit': 20}
/// ```
class SkipPaginationParams extends PaginationParams {
  /// Creates a [SkipPaginationParams] instance.
  const SkipPaginationParams({
    this.skip = 0,
    this.limit = 10,
    this.extra,
  });

  /// Factory constructor to deserialize [SkipPaginationParams] from JSON.
  factory SkipPaginationParams.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? extraMap;
    if (json.containsKey('extra') && json['extra'] is Map<String, dynamic>) {
      extraMap = Map<String, dynamic>.from(json['extra'] as Map);
    }
    return SkipPaginationParams(
      skip: json['skip'] as int? ?? 0,
      limit: json['limit'] as int? ?? 10,
      extra: extraMap,
    );
  }

  /// Number of items to skip.
  final int skip;

  @override
  final int limit;

  @override
  final Map<String, dynamic>? extra;

  @override
  String get requestId => 'skip_${skip}_limit_$limit';

  @override
  Map<String, dynamic> toJson() {
    return {
      'skip': skip,
      'limit': limit,
      if (extra != null) 'extra': extra,
    };
  }

  @override
  List<Object?> get props => [skip, limit, extra];
}

/// Opaque cursor token based pagination parameters.
///
/// `@example`
/// ```dart
/// const params = CursorPaginationParams(cursor: 'token_xyz', limit: 20);
/// print(params.requestId); // 'cursor_token_xyz_limit_20'
/// print(params.toJson()); // {'cursor': 'token_xyz', 'limit': 20}
/// ```
class CursorPaginationParams extends PaginationParams {
  /// Creates a [CursorPaginationParams] instance.
  const CursorPaginationParams({
    this.cursor,
    this.limit = 10,
    this.extra,
  });

  /// Factory constructor to deserialize [CursorPaginationParams] from JSON.
  factory CursorPaginationParams.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? extraMap;
    if (json.containsKey('extra') && json['extra'] is Map<String, dynamic>) {
      extraMap = Map<String, dynamic>.from(json['extra'] as Map);
    }
    return CursorPaginationParams(
      cursor: json['cursor'] as String?,
      limit: json['limit'] as int? ?? 10,
      extra: extraMap,
    );
  }

  /// Opaque continuation token.
  final String? cursor;

  @override
  final int limit;

  @override
  final Map<String, dynamic>? extra;

  @override
  String get requestId => 'cursor_${cursor}_limit_$limit';

  @override
  Map<String, dynamic> toJson() {
    return {
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
      if (extra != null) 'extra': extra,
    };
  }

  @override
  List<Object?> get props => [cursor, limit, extra];
}
