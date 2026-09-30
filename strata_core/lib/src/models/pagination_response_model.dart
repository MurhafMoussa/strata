import 'package:equatable/equatable.dart';

/// Abstract contract for metadata models associated with pagination responses.
///
/// Implementations capture backend-specific pagination metadata such as total item count,
/// current page index, or opaque continuation cursors.
///
/// `@example`
/// ```dart
/// class MyMeta extends MetaModel {
///   const MyMeta(this.total);
///   final int total;
///   @override
///   List<Object?> get props => [total];
/// }
/// ```
abstract class MetaModel extends Equatable {
  /// Const constructor for [MetaModel].
  const MetaModel();
}

/// Default empty metadata model when no response metadata is returned.
///
/// `@example`
/// ```dart
/// const emptyMeta = NoMetaModel();
/// ```
class NoMetaModel extends MetaModel {
  /// Creates a [NoMetaModel] instance.
  const NoMetaModel();

  @override
  List<Object?> get props => [];
}

/// Standard pagination metadata model containing total count and page pagination parameters.
///
/// `@example`
/// ```dart
/// final meta = PaginationMetaModel.fromJson({'total_count': 100, 'page': 1, 'limit': 20});
/// print(meta.totalCount); // 100
/// ```
class PaginationMetaModel extends MetaModel {
  /// Creates a [PaginationMetaModel].
  const PaginationMetaModel({
    this.totalCount,
    this.page,
    this.limit,
  });

  /// Total count of records available across all pages.
  final int? totalCount;

  /// Current 1-based page index.
  final int? page;

  /// Maximum items requested per page.
  final int? limit;

  @override
  List<Object?> get props => [totalCount, page, limit];

  /// Deserializes [PaginationMetaModel] from a JSON map.
  factory PaginationMetaModel.fromJson(Map<String, dynamic> json) {
    return PaginationMetaModel(
      totalCount: (json['totalCount'] ?? json['total_count'] ?? json['total']) as int?,
      page: (json['page'] ?? json['current_page']) as int?,
      limit: (json['limit'] ?? json['per_page']) as int?,
    );
  }

  /// Converts [PaginationMetaModel] to a JSON map.
  Map<String, dynamic> toJson() => {
        if (totalCount != null) 'total_count': totalCount,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      };
}

/// Generic container for paginated response data and associated metadata.
///
/// [T] represents the item type contained in [data].
/// [M] represents the optional metadata model extending [MetaModel].
///
/// `@example`
/// ```dart
/// const response = PaginationResponseModel<String, PaginationMetaModel>(
///   data: ['item1', 'item2'],
///   meta: PaginationMetaModel(totalCount: 10),
///   nextCursor: 'cursor_xyz',
/// );
/// final updated = response.copyWith(nextCursor: 'cursor_abc');
/// ```
class PaginationResponseModel<T, M extends MetaModel> extends Equatable {
  /// Creates a [PaginationResponseModel].
  const PaginationResponseModel({
    this.data = const [],
    this.meta,
    this.nextCursor,
  });

  /// List of items returned in the current page/batch response.
  final List<T> data;

  /// Optional metadata containing page details or total record counts.
  final M? meta;

  /// Optional continuation cursor token for cursor/keyset pagination.
  final String? nextCursor;

  @override
  List<Object?> get props => [data, meta, nextCursor];

  /// Returns a copy of this response model with updated fields.
  PaginationResponseModel<T, M> copyWith({
    List<T>? data,
    M? meta,
    String? nextCursor,
  }) {
    return PaginationResponseModel<T, M>(
      data: data ?? this.data,
      meta: meta ?? this.meta,
      nextCursor: nextCursor ?? this.nextCursor,
    );
  }

  /// Deserializes a [PaginationResponseModel] from a JSON map.
  ///
  /// [fromJsonT] parses individual item objects from JSON maps.
  /// [fromJsonM] optionally parses metadata objects from JSON maps.
  factory PaginationResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT, {
    M Function(Map<String, dynamic> json)? fromJsonM,
  }) {
    final rawData = json['data'] as List<dynamic>? ?? [];
    final parsedData = rawData
        .whereType<Map<String, dynamic>>()
        .map(fromJsonT)
        .toList();

    M? meta;
    if (fromJsonM != null && json.containsKey('meta') && json['meta'] != null) {
      meta = fromJsonM(json['meta'] as Map<String, dynamic>);
    } else if (M == NoMetaModel) {
      meta = const NoMetaModel() as M;
    }

    final nextCursor = json['nextCursor'] as String? ??
        json['next_cursor'] as String? ??
        json['cursor'] as String?;

    return PaginationResponseModel(
      data: parsedData,
      meta: meta,
      nextCursor: nextCursor,
    );
  }
}
