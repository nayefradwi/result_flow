// ignore_for_file: only_throw_errors

typedef FutureEither<L, R> = Future<Either<L, R>>;
typedef EitherStream<L, R> = Stream<Either<L, R>>;
typedef EitherMapperCallback<R, T> = Either<R, T> Function(T data);
typedef EitherMapperCallbackAsync<R, T> = FutureEither<R, T> Function(T data);

abstract class Either<L, R> {
  Either._();

  factory Either.left(L left) => EitherLeft<L, R>(left);
  factory Either.right(R right) => EitherRight<L, R>(right);

  bool get isLeft => this is EitherLeft<L, R>;
  bool get isRight => this is EitherRight<L, R>;

  RT fold<RT>({
    required RT Function(L left) left,
    required RT Function(R right) right,
    RT Function(dynamic error)? onError,
  }) {
    try {
      if (isLeft) return left((this as EitherLeft<L, R>).left);
      if (isRight) return right((this as EitherRight<L, R>).right);
      throw Exception('No right handler provided');
    } catch (e) {
      return onError?.call(e) ?? (throw e);
    }
  }

  Future<RT> foldAsync<RT>({
    required Future<RT> Function(L left) left,
    required Future<RT> Function(R right) right,
    Future<RT> Function(dynamic error)? onError,
  }) async {
    try {
      if (isLeft) return await left((this as EitherLeft<L, R>).left);
      if (isRight) return await right((this as EitherRight<L, R>).right);
      throw Exception('No right handler provided');
    } catch (e) {
      return onError?.call(e) ?? (throw e);
    }
  }

  Either<R, L> swap() {
    return switch (this) {
      EitherLeft<L, R>() => EitherRight<R, L>((this as EitherLeft<L, R>).left),
      EitherRight<L, R>() => EitherLeft<R, L>(
        (this as EitherRight<L, R>).right,
      ),
      _ => throw Exception('No right handler provided'),
    };
  }

  RT? onLeft<RT>(RT Function(L left) left) {
    if (isLeft) return left((this as EitherLeft<L, R>).left);
    return null;
  }

  RT? onRight<RT>(RT Function(R right) right) {
    if (isRight) return right((this as EitherRight<L, R>).right);
    return null;
  }

  L? get leftValue {
    if (isLeft) return (this as EitherLeft<L, R>).left;
    return null;
  }

  R? get rightValue {
    if (isRight) return (this as EitherRight<L, R>).right;
    return null;
  }

  R get rightOrThrow {
    if (isRight) return (this as EitherRight<L, R>).right;
    throw Exception('No right handler provided');
  }

  L get leftOrThrow {
    if (isLeft) return (this as EitherLeft<L, R>).left;
    throw Exception('No left handler provided');
  }
}

class EitherLeft<L, R> extends Either<L, R> {
  EitherLeft(this.left) : super._();
  final L left;
}

class EitherRight<L, R> extends Either<L, R> {
  EitherRight(this.right) : super._();
  final R right;
}
