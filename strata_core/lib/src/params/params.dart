import 'package:equatable/equatable.dart';

/// Empty parameter class for use cases and requests requiring no arguments.
///
/// `@example`
/// ```dart
/// const params = NoParams();
/// final json = params.toJson();
/// final fromJson = NoParams.fromJson(json);
/// ```
class NoParams extends Equatable {
  /// Creates a [NoParams] instance.
  const NoParams();

  /// Deserializes a [NoParams] instance from JSON.
  factory NoParams.fromJson(Map<String, dynamic> json) => const NoParams();

  /// Converts [NoParams] into an empty JSON representation.
  Map<String, dynamic> toJson() => {};

  @override
  List<Object?> get props => [];
}

/// Simple parameter class holding a single string ID.
///
/// `@example`
/// ```dart
/// const param = IdParam(id: '123');
/// final json = param.toJson();
/// final fromJson = IdParam.fromJson(json);
/// ```
class IdParam extends Equatable {
  /// Creates an [IdParam] instance.
  const IdParam({required this.id});

  /// Deserializes an [IdParam] instance from JSON.
  factory IdParam.fromJson(Map<String, dynamic> json) =>
      IdParam(id: json['id'] as String? ?? '');

  /// The encapsulated unique entity identifier string.
  final String id;

  /// Converts [IdParam] into a JSON representation with an optional custom [idKey].
  Map<String, dynamic> toJson({String? idKey}) => {idKey ?? 'id': id};

  @override
  List<Object?> get props => [id];
}
