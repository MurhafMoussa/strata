import '../typedefs/result_typedefs.dart';

abstract class ResultStreamUseCase<Output, Input> {
  const ResultStreamUseCase();

  ResultStream<Output> call(Input input);
}
