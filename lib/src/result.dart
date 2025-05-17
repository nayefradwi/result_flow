import 'package:result_flow/src/error.dart';
import 'package:result_flow/src/util.dart';

typedef FutureResult<T> = Future<Result<T>>;
typedef ResultStream<T> = Stream<Result<T>>;
typedef ResultMapperCallback<R, T> = Result<R> Function(T data);
typedef ResultMapperCallbackAsync<R, T> = FutureResult<R> Function(T data);

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
    R? fallback,
    Future<R> Function(dynamic exception)? onException,
  }) async {
    try {
      if (!isError) return await success((this as ResultWithData<T>).data);
      return await error((this as ResultWithError<T>).error);
    } catch (err) {
      try {
        return await error(UnknownError(message: err.toString()));
      } catch (e) {
        final r = onException?.call(e);
        if (r != null) return r;
        if (fallback != null) return fallback;
        if (isTypeNullable<R>()) return null as R;
        rethrow;
      }
    }
  }

  R on<R>({
    required R Function(T data) success,
    required R Function(ResultError error) error,
    R? fallback,
    R Function(dynamic exception)? onException,
  }) {
    try {
      if (!isError) return success((this as ResultWithData<T>).data);
      return error((this as ResultWithError<T>).error);
    } catch (err) {
      try {
        return error(UnknownError(message: err.toString()));
      } catch (e) {
        final r = onException?.call(e);
        if (r != null) return r;
        if (fallback != null) return fallback;
        if (isTypeNullable<R>()) return null as R;
        rethrow;
      }
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

  T? get data {
    if (isSuccess) return (this as ResultWithData<T>).data;
    return null;
  }

  ResultError? get error {
    if (isError) return (this as ResultWithError<T>).error;
    return null;
  }

  T getOrElse(T defaultValue) {
    return data ?? defaultValue;
  }

  T get dataOrThrow {
    if (isSuccess) return (this as ResultWithData<T>).data;
    throw (this as ResultWithError<T>).error;
  }

  Result<R> mapTo<R>(ResultMapperCallback<R, T> after) {
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

  FutureResult<R> continueWith<R>(ResultMapperCallbackAsync<R, T> after) async {
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

  Result<T> handle(Result<T> Function(ResultError error) onError) {
    try {
      if (isSuccess) return this;
      final error = (this as ResultWithError<T>).error;
      final newResult = onError(error);
      return newResult;
    } catch (e) {
      if (e is ResultError) return Result.error(e);
      return Result.exception(e);
    }
  }

  FutureResult<T> handleAsync(
    FutureResult<T> Function(ResultError error) onError,
  ) async {
    try {
      if (isSuccess) return this;
      final error = (this as ResultWithError<T>).error;
      final newResult = await onError(error);
      return newResult;
    } catch (e) {
      if (e is ResultError) return Result.error(e);
      return Result.exception(e);
    }
  }
}

class ResultWithData<T> extends Result<T> {
  ResultWithData._(this.data) : super._();

  @override
  final T data;
}

class ResultWithError<T> extends Result<T> {
  ResultWithError._(this.error) : super._();

  @override
  final ResultError error;
}

extension FutureResultRunAfter<T> on FutureResult<T> {
  FutureResult<R> mapToAsync<R>(ResultMapperCallback<R, T> after) async {
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

  FutureResult<R> continueWith<R>(ResultMapperCallbackAsync<R, T> after) async {
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

  FutureResult<T> handleAsync(
    FutureResult<T> Function(ResultError error) onError,
  ) async {
    try {
      final current = await this;
      if (current.isSuccess) return current;
      final error = (current as ResultWithError<T>).error;
      final newResult = await onError(error);
      return newResult;
    } catch (e) {
      if (e is ResultError) return Result.error(e);
      return Result.exception(e);
    }
  }

  FutureResult<T> handle(Result<T> Function(ResultError error) onError) async {
    try {
      final current = await this;
      if (current.isSuccess) return current;
      final error = (current as ResultWithError<T>).error;
      final newResult = onError(error);
      return newResult;
    } catch (e) {
      if (e is ResultError) return Result.error(e);
      return Result.exception(e);
    }
  }
}
