import 'package:fpdart/fpdart.dart';
import '../error_handling/failures/failure.dart';

/// Standard Async Response for repositories, data sources, and use cases.
typedef ResultFuture<T> = Future<Either<Failure, T>>;

/// Standard Stream Response for real-time streams.
typedef ResultStream<T> = Stream<Either<Failure, T>>;
