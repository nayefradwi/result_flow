import 'package:result_flow/src/error.dart';
import 'package:result_flow/src/util.dart';

typedef FutureResult<T> = Future<Result<T>>;
typedef ResultStream<T> = Stream<Result<T>>;
typedef ResultMapperCallback<R, T> = Result<R> Function(T data);
typedef ResultMapperCallbackAsync<R, T> = FutureResult<R> Function(T data);

/// A class that represents the result of an operation. It can be either a
/// success using [ResultWithData] or an error using [ResultWithError].
///
/// The abstract class [Result] provides a way to handle the result of one
/// or more operations in a safe and functional way by providing methods like
/// [on], [onAsync], [mapTo], [continueWith], and [handle].
abstract class Result<T> {
  Result._();
  factory Result.success(T data) => ResultWithData<T>._(data);
  factory Result.error(ResultError error) => ResultWithError<T>._(error);
  factory Result.exception(dynamic e) =>
      ResultWithError<T>._(UnknownError(message: e.toString()));

  bool get isSuccess => this is ResultWithData<T>;
  bool get isError => this is ResultWithError<T>;

  /// A helper method to wraps a synchronous operation that can throw an
  /// exception or return a result. If the operation throws an exception,
  /// it will be caught and wrapped in a [ResultError] or [UnknownError].
  /// If the operation returns a result, it will be wrapped in a
  /// [ResultWithData] instance.
  ///
  /// This method is useful for wrapping synchronous operations that can
  /// throw unexpected exceptions, such as parsing JSON
  /// or performing calculations.
  static Result<T> safeRun<T>(T Function() operation) {
    try {
      final data = operation();
      return Result.success(data);
    } catch (e) {
      if (e is ResultError) return Result.error(e);
      return Result.exception(e);
    }
  }

  /// A helper method to wraps an asynchronous operation that can throw an
  /// exception or return a result. If the operation throws an exception,
  /// it will be caught and wrapped in a [ResultError] or [UnknownError].
  /// If the operation returns a result, it will be wrapped in a
  /// [ResultWithData] instance.
  ///
  /// This method is useful for wrapping asynchronous operations that can
  /// throw unexpected exceptions, such as network requests
  /// or database queries.
  static FutureResult<T> safeRunAsync<T>(Future<T> Function() operation) async {
    try {
      final data = await operation();
      return Result.success(data);
    } catch (e) {
      if (e is ResultError) return Result.error(e);
      return Result.exception(e);
    }
  }

  /// [onAsync] is a method that allows you to handle the result of an
  /// asynchronous operation by providing two callbacks:
  ///   - [success]: a callback that is called when the result is a success
  ///   - [error]: a callback that is called when the result is an error
  ///
  /// [onAsync] also accepts different optional paramaters like [fallback] and
  /// [onException] to handle cases where the result is [ResultWithError] but
  /// the [error] callback throws an exception. It will first attempt to call
  /// [error] with an [UnknownError] and if that throws an exception it will
  /// call [onException] with the exception or [fallback] if provided
  /// (prioritizing [onException] first).
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

  /// [on] is a method that allows you to handle the result of an operation
  /// by providing two callbacks:
  ///   - [success]: a callback that is called when the result is a success
  ///   - [error]: a callback that is called when the result is an error
  ///
  /// [on] also accepts different optional paramaters like [fallback] and
  /// [onException] to handle cases where the result is [ResultWithError] but
  /// the [error] callback throws an exception. It will first attempt to call
  /// [error] with an [UnknownError] and if that throws an exception it will
  /// call [onException] with the exception or [fallback] if provided
  /// (prioritizing [onException] first).
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

  /// Executes the [success] callback if the result is a success.
  /// Returns the result of the [success] callback or null if the result is
  /// an error or an exception occurs.
  R? onSuccess<R>({required R Function(T data) success}) {
    try {
      if (isSuccess) return success((this as ResultWithData<T>).data);
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Executes the [error] callback if the result is an error.
  /// Returns the result of the [error] callback or null if the result is a
  /// success or an exception occurs.
  R? onError<R>({required R Function(ResultError error) error}) {
    try {
      if (isError) return error((this as ResultWithError<T>).error);
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Returns the data if the result is a success, otherwise returns null.
  T? get data {
    if (isSuccess) return (this as ResultWithData<T>).data;
    return null;
  }

  /// Returns the error if the result is an error, otherwise returns null.
  ResultError? get error {
    if (isError) return (this as ResultWithError<T>).error;
    return null;
  }

  /// Returns the data if the result is a success,
  /// otherwise returns the [defaultValue].
  T getOrElse(T defaultValue) {
    return data ?? defaultValue;
  }

  /// Returns the data if the result is a success, otherwise throws the error.
  T get dataOrThrow {
    if (isSuccess) return (this as ResultWithData<T>).data;
    throw (this as ResultWithError<T>).error;
  }

  /// Transforms the data of a successful result using the [after] callback.
  /// If the result is an error, or if an exception occurs in
  /// the [after] callback, it returns a new error result.
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

  /// Asynchronously transforms the data of a successful result using
  /// the [after] callback. If the result is an error, or if an exception
  /// occurs in the [after] callback, it returns a new error result.
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

  /// Handles an error result by executing the [onError] callback.
  /// If the result is a success, it returns the original result.
  /// If an exception occurs in the [onError] callback,
  /// it returns a new error result.
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

  /// Asynchronously handles an error result by executing
  /// the [onError] callback. If the result is a success, it returns
  /// the original result. If an exception occurs in the [onError] callback,
  /// it returns a new error result.
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

/// Extension methods for [FutureResult] to chain operations.
extension FutureResultRunAfter<T> on FutureResult<T> {
  /// Asynchronously transforms the data of a successful result
  /// using the [after] callback.
  ///
  /// This method is intended to be used with a [FutureResult].
  /// If the result is an error, or if an exception occurs in the [after]
  /// callback, it returns a new error result.
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

  /// Asynchronously transforms the data of a successful result
  /// using the [after] callback.
  ///
  /// This method is intended to be used with a [FutureResult].
  /// If the result is an error, or if an exception occurs in the [after]
  /// callback, it returns a new error result.
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

  /// Asynchronously handles an error result by executing
  /// the [onError] callback.
  ///
  /// This method is intended to be used with a [FutureResult].
  /// If the result is a success, it returns the original result.
  /// If an exception occurs in the [onError] callback,
  /// it returns a new error result.
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

  /// Asynchronously handles an error result by
  /// executing the [onError] callback.
  ///
  /// This method is intended to be used with a [FutureResult].
  /// If the result is a success, it returns the original result.
  /// If an exception occurs in the [onError] callback,
  /// it returns a new error result.
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
