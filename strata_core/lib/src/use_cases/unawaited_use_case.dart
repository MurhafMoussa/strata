abstract class UnawaitedUseCase<Output, Input> {
  const UnawaitedUseCase();

  Output call(Input input);
}
