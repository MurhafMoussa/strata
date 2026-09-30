import 'package:dio/dio.dart';
import 'package:strata_core/strata_core.dart';

import '../api_handler/models/base_error_response_model.dart';

/// Function signature for parsing network error models from Dio responses.
typedef ErrorModelParser = BaseErrorResponseModel Function(
    Response<dynamic>? response);

/// Abstract contract for mapping network exceptions into domain [Failure]s.
abstract interface class NetworkExceptionMapperInterface {
  /// Maps an exception and stack trace into a domain [Failure].
  Failure mapException(Object exception, StackTrace? stackTrace);
}
