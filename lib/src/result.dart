import 'package:safe_result/src/error.dart';

typedef FutureResult<T> = Future<Result<T>>;
typedef ResultStream<T> = Stream<Result<T>>;

abstract class Result<T> {
  Result._();
  factory Result.success(T data) => ResultWithData<T>._(data);
  factory Result.error(ResultError error) => ResultWithError<T>._(error);
  factory Result.exception(dynamic e) =>
      ResultWithError<T>._(UnknownError(message: e.toString()));

  bool get isSuccess => this is ResultWithData<T>;
  bool get isError => this is ResultWithError<T>;

  static Result<T> safeRun<T>(T Function() operation) {
    try {
      final data = operation();
      return Result.success(data);
    } catch (e) {
      if (e is ResultError) return Result.error(e);
      return Result.exception(e);
    }
  }

  static FutureResult<T> safeRunAsync<T>(Future<T> Function() operation) async {
    try {
      final data = await operation();
      return Result.success(data);
    } catch (e) {
      if (e is ResultError) return Result.error(e);
      return Result.exception(e);
    }
  }

  Future<R> onAsync<R>({
    required Future<R> Function(T data) success,
    required Future<R> Function(ResultError error) error,
  }) async {
    try {
      if (!isError) return await success((this as ResultWithData<T>).data);
      return await error((this as ResultWithError<T>).error);
    } catch (e) {
      return error(UnknownError(message: e.toString()));
    }
  }

  R on<R>({
    required R Function(T data) success,
    required R Function(ResultError error) error,
  }) {
    try {
      if (!isError) return success((this as ResultWithData<T>).data);
      return error((this as ResultWithError<T>).error);
    } catch (e) {
      return error(UnknownError(message: e.toString()));
    }
  }

  R? onSuccess<R>({required R Function(T data) success}) {
    try {
      if (isSuccess) return success((this as ResultWithData<T>).data);
      return null;
    } catch (e) {
      return null;
    }
  }

  R? onError<R>({required R Function(ResultError error) error}) {
    try {
      if (isError) return error((this as ResultWithError<T>).error);
      return null;
    } catch (e) {
      return null;
    }
  }

  T? tryGetData() {
    if (isSuccess) return (this as ResultWithData<T>).data;
    return null;
  }

  ResultError? tryGetError() {
    if (isError) return (this as ResultWithError<T>).error;
    return null;
  }

  T getOrElse(T defaultValue) {
    return tryGetData() ?? defaultValue;
  }

  Result<R> runAfter<R>({required Result<R> Function(T data) after}) {
    try {
      if (isError) return Result.error((this as ResultWithError<T>).error);
      final data = (this as ResultWithData<T>).data;
      final newResult = after(data);
      return newResult;
    } catch (e) {
      if (e is ResultError) return Result.error(e);
      return Result.exception(e);
    }
  }

  FutureResult<R> runAfterAsync<R>({
    required FutureResult<R> Function(T data) after,
  }) async {
    try {
      if (isError) return Result.error((this as ResultWithError<T>).error);
      final data = (this as ResultWithData<T>).data;
      final newResult = await after(data);
      return newResult;
    } catch (e) {
      if (e is ResultError) return Result.error(e);
      return Result.exception(e);
    }
  }
}

class ResultWithData<T> extends Result<T> {
  ResultWithData._(this.data) : super._();
  final T data;
}

class ResultWithError<T> extends Result<T> {
  ResultWithError._(this.error) : super._();
  final ResultError error;
}

extension FutureResultRunAfter<T> on FutureResult<T> {
  FutureResult<R> runAfter<R>({
    required Result<R> Function(T data) after,
  }) async {
    try {
      final current = await this;
      if (current.isError) {
        return Result.error((current as ResultWithError<T>).error);
      }
      final data = (current as ResultWithData<T>).data;
      final newResult = after(data);
      return newResult;
    } catch (e) {
      if (e is ResultError) return Result.error(e);
      return Result.exception(e);
    }
  }

  FutureResult<R> runAfterAsync<R>({
    required FutureResult<R> Function(T data) after,
  }) async {
    try {
      final current = await this;
      if (current.isError) {
        return Result.error((current as ResultWithError<T>).error);
      }
      final data = (current as ResultWithData<T>).data;
      final newResult = await after(data);
      return newResult;
    } catch (e) {
      if (e is ResultError) return Result.error(e);
      return Result.exception(e);
    }
  }
}
