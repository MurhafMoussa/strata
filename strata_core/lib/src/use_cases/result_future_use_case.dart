import '../typedefs/result_typedefs.dart';

abstract class ResultFutureUseCase<Output, Input> {
  const ResultFutureUseCase();

  ResultFuture<Output> call(Input input);
}
