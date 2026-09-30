import 'package:equatable/equatable.dart';
import 'network_file.dart';

/// Framework-agnostic encapsulation of multipart form data.
class NetworkFormData extends Equatable {
  /// Creates a [NetworkFormData] payload with key-value fields and file attachments.
  const NetworkFormData({
    this.fields = const {},
    this.files = const [],
  });

  /// Key-value text fields.
  final Map<String, dynamic> fields;

  /// List of attached files.
  final List<NetworkFile> files;

  @override
  List<Object?> get props => [fields, files];
}
