import 'package:equatable/equatable.dart';

/// Represents a file attachment in a multipart/form-data request.
class NetworkFile extends Equatable {
  /// Creates a [NetworkFile] attachment.
  const NetworkFile({
    required this.fieldName,
    required this.filePath,
    this.filename,
    this.contentType,
  });

  /// The form field name associated with this file.
  final String fieldName;

  /// The local filesystem path of the file.
  final String filePath;

  /// Optional custom file name sent in headers.
  final String? filename;

  /// Optional MIME content type (e.g. `image/png`).
  final String? contentType;

  @override
  List<Object?> get props => [fieldName, filePath, filename, contentType];
}
