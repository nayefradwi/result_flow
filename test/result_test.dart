import 'package:safe_result/safe_result.dart';
import 'package:test/test.dart';

FutureResult<int> returnsFutureSuccess(int value) async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return Result.success(value);
}

Result<int> returnsSuccess(int value) {
  return Result.success(value);
}

Result<String> returnsStringSuccess(String value) {
  return Result.success(value);
}

Result<int> returnsError(int value) {
  return Result.error(
    DomainError(
      'Simulated domain error for value $value',
      code: 'test_error_$value',
    ),
  );
}

Result<int> throwsException(int value) {
  throw DomainError(
    'Simulated exception for value $value',
    code: 'test_error_$value',
  );
}

void main() {
  group('Result Chaining - Successful Execution:', () {
    test(
      'should execute sequential synchronous runAfter calls successfully',
      () {
        final sequence = <int>[];
        final result = returnsSuccess(1)
            .mapTo((data) {
              final next = data + 1;
              sequence.add(next);
              return returnsSuccess(next);
            })
            .mapTo((data) {
              final next = data + 1;
              sequence.add(next);
              return returnsSuccess(next);
            })
            .mapTo((data) {
              final next = data + 1;
              sequence.add(next);
              return returnsSuccess(next);
            });

        expect(result.isSuccess, true);
        expect(result.data, 4);
        expect(sequence, [2, 3, 4]);
      },
    );

    test(
      'should execute sequential asynchronous after calls successfully',
      () async {
        final sequence = <int>[];
        final result = await returnsSuccess(1)
            .continueWith((data) async {
              final next = data + 1;
              sequence.add(next);
              return returnsFutureSuccess(next);
            })
            .continueWith((data) async {
              final next = data + 1;
              sequence.add(next);
              return returnsFutureSuccess(next);
            })
            .continueWith((data) async {
              final next = data + 1;
              sequence.add(next);
              return returnsFutureSuccess(next);
            });

        expect(result.isSuccess, true);
        expect(result.data, 4);
        expect(sequence, [2, 3, 4]);
      },
    );

    test(
      '''should execute mixed synchronous and asynchronous runAfter calls successfully''',
      () async {
        final sequence = <int>[];
        final result = await returnsFutureSuccess(1)
            .mapToAsync((data) {
              final next = data + 1;
              sequence.add(next);
              return returnsSuccess(next);
            })
            .continueWith((data) async {
              final next = data + 1;
              sequence.add(next);
              return returnsFutureSuccess(next);
            })
            .mapToAsync((data) {
              final next = data + 1;
              sequence.add(next);
              return returnsSuccess(next);
            });

        expect(result.isSuccess, true);
        expect(result.data, 4);
        expect(sequence, [2, 3, 4]);
      },
    );
  });

  group('Result Chaining - Error Propagation:', () {
    test(
      'should stop chain execution when a step returns Result.error',
      () async {
        final sequence = <int>[];

        var resultSync = returnsSuccess(1)
            .mapTo((data) {
              final next = data + 1;
              sequence.add(next);
              return returnsError(next);
            })
            .mapTo((data) {
              final next = data + 1;
              sequence.add(99);
              return returnsSuccess(next);
            });

        expect(
          resultSync.isError,
          true,
          reason: 'Sync chain should be error after first step',
        );
        expect(
          sequence,
          [2],
          reason: '''Sync chain sequence should only have first step''',
        );
        expect(
          resultSync.error,
          isA<DomainError>(),
          reason: 'Sync chain error type mismatch',
        );
        expect(
          (resultSync.error! as DomainError).code,
          'test_error_2',
          reason: 'Sync chain error code mismatch',
        );
        expect(resultSync.data, null, reason: 'Sync chain data should be null');

        sequence.clear();
        resultSync = returnsSuccess(1)
            .mapTo((data) {
              final next = data + 1;
              sequence.add(next);
              return returnsSuccess(next);
            })
            .mapTo((data) {
              final next = data + 1;
              sequence.add(next);
              return returnsError(next);
            })
            .mapTo((data) {
              final next = data + 1;
              sequence.add(99);
              return returnsSuccess(next);
            });

        expect(
          resultSync.isError,
          true,
          reason: 'Sync chain should be error after second step',
        );
        expect(
          sequence,
          [2, 3],
          reason: '''Sync chain sequence should have first two steps''',
        );
        expect(
          resultSync.error,
          isA<DomainError>(),
          reason: 'Sync chain error type mismatch',
        );
        expect(
          (resultSync.error! as DomainError).code,
          'test_error_3',
          reason: 'Sync chain error code mismatch',
        );
        expect(resultSync.data, null, reason: 'Sync chain data should be null');

        sequence.clear();
        final resultMixed = await returnsFutureSuccess(1)
            .continueWith((data) async {
              final next = data + 1;
              sequence.add(next);
              return returnsFutureSuccess(next);
            })
            .mapToAsync((data) {
              final next = data + 1;
              sequence.add(next);
              return returnsError(next);
            })
            .continueWith((data) async {
              final next = data + 1;
              sequence.add(99);
              return returnsFutureSuccess(next);
            });

        expect(
          resultMixed.isError,
          true,
          reason: 'Mixed chain should be error after sync step',
        );
        expect(
          sequence,
          [2, 3],
          reason: '''Mixed chain sequence should have first two steps''',
        );
        expect(
          resultMixed.error,
          isA<DomainError>(),
          reason: 'Mixed chain error type mismatch',
        );
        expect(
          (resultMixed.error! as DomainError).code,
          'test_error_3',
          reason: 'Mixed chain error code mismatch',
        );
        expect(
          resultMixed.data,
          null,
          reason: 'Mixed chain data should be null',
        );
      },
    );
  });

  group('Result Chaining - Exception Handling:', () {
    test(
      '''should stop chain and return Result.error when a step throws an exception''',
      () async {
        final sequence = <int>[];

        var resultSync = returnsSuccess(1)
            .mapTo((data) {
              final next = data + 1;
              sequence.add(next);
              return throwsException(next);
            })
            .mapTo((data) {
              final next = data + 1;
              sequence.add(99);
              return returnsSuccess(next);
            });

        expect(
          resultSync.isError,
          true,
          reason: 'Sync chain should be error after exception in first step',
        );
        expect(
          sequence,
          [2],
          reason: 'Sync chain sequence should only have first step (exception)',
        );
        expect(
          resultSync.error,
          isA<DomainError>(),
          reason: 'Sync chain error type mismatch (exception)',
        );
        expect(
          resultSync.error?.message,
          'Simulated exception for value 2',
          reason: 'Sync chain error message mismatch (exception)',
        );
        expect(
          resultSync.error?.code,
          'test_error_2',
          reason: 'Sync chain error code mismatch (exception)',
        );
        expect(
          resultSync.data,
          null,
          reason: 'Sync chain data should be null (exception)',
        );

        sequence.clear();
        resultSync = returnsSuccess(1)
            .mapTo((data) {
              final next = data + 1;
              sequence.add(next);
              return returnsSuccess(next);
            })
            .mapTo((data) {
              final next = data + 1;
              sequence.add(next);
              return throwsException(next);
            })
            .mapTo((data) {
              final next = data + 1;
              sequence.add(99);
              return returnsSuccess(next);
            });

        expect(
          resultSync.isError,
          true,
          reason: 'Sync chain should be error after exception in second step',
        );
        expect(
          sequence,
          [2, 3],
          reason: 'Sync chain sequence should have first two steps (exception)',
        );
        expect(
          resultSync.error,
          isA<DomainError>(),
          reason: 'Sync chain error type mismatch (exception)',
        );
        expect(
          resultSync.error?.message,
          'Simulated exception for value 3',
          reason: 'Sync chain error message mismatch (exception)',
        );
        expect(
          resultSync.error?.code,
          'test_error_3',
          reason: 'Sync chain error code mismatch (exception)',
        );
        expect(
          resultSync.data,
          null,
          reason: 'Sync chain data should be null (exception)',
        );

        sequence.clear();
        final resultMixed = await returnsFutureSuccess(1)
            .continueWith((data) async {
              final next = data + 1;
              sequence.add(next);
              return returnsFutureSuccess(next);
            })
            .mapToAsync((data) {
              final next = data + 1;
              sequence.add(next);
              return throwsException(next);
            })
            .continueWith((data) async {
              final next = data + 1;
              sequence.add(99);
              return returnsFutureSuccess(next);
            });

        expect(
          resultMixed.isError,
          true,
          reason: 'Mixed chain should be error after exception in sync step',
        );
        expect(
          sequence,
          [2, 3],
          reason:
              'Mixed chain sequence should have first two steps (exception)',
        );
        expect(
          resultMixed.error,
          isA<DomainError>(),
          reason: 'Mixed chain error type mismatch (exception)',
        );
        expect(
          resultMixed.error?.message,
          'Simulated exception for value 3',
          reason: 'Mixed chain error message mismatch (exception)',
        );
        expect(
          resultMixed.error?.code,
          'test_error_3',
          reason: 'Mixed chain error code mismatch (exception)',
        );
        expect(
          resultMixed.data,
          null,
          reason: 'Mixed chain data should be null (exception)',
        );
      },
    );
  });

  group('Result Chaining - Type Handling:', () {
    test('should handle changing data types across chained runAfter calls', () {
      final sequenceOfDataPassed = <dynamic>[];

      final result = returnsStringSuccess('start')
          .mapTo<int>((data) {
            sequenceOfDataPassed.add(data);
            final nextVal = data.length;
            return returnsSuccess(nextVal);
          })
          .mapTo<String>((data) {
            sequenceOfDataPassed.add(data);
            final nextVal = data.toString();
            return returnsStringSuccess(nextVal);
          })
          .mapTo<bool>((data) {
            sequenceOfDataPassed.add(data);
            final nextVal = data.isNotEmpty;
            return Result.success(nextVal);
          });

      expect(sequenceOfDataPassed, ['start', 5, '5']);

      expect(result.isSuccess, true);
      expect(result.data, isA<bool>());
      expect(result.data, true);
    });
  });

  group('Result.on - Exception in onError:', () {
    test('should handle exceptions thrown in error handler for Result.on', () {
      var result = returnsError(1).on<int>(
        success: (data) {
          fail('success callback should not be called');
        },
        error: (error) {
          throw Exception('Exception from error handler');
        },
        fallback: 42,
      );

      expect(result, 42);
      expect(result, isA<int>());

      result = returnsError(1).on<int>(
        success: (data) {
          fail('success callback should not be called');
        },
        error: (error) {
          throw Exception('Exception from error handler');
        },
        onException: (exception) {
          expect(exception, isA<Exception>());
          expect(
            exception.toString(),
            contains('Exception from error handler'),
          );
          return 99;
        },
      );

      expect(result, 99);
      expect(result, isA<int>());

      result = returnsError(1).on<int>(
        success: (data) {
          fail('success callback should not be called');
        },
        error: (error) {
          throw Exception('Exception from error handler');
        },
        fallback: 42,
        onException: (exception) => 777,
      );

      expect(result, 777);
    });

    test(
      'should handle exceptions thrown in error handler for Result.onAsync',
      () async {
        var result = await returnsError(1).onAsync<int>(
          success: (data) async {
            fail('success callback should not be called');
          },
          error: (error) async {
            throw Exception('Exception from error handler');
          },
          fallback: 42,
        );

        expect(result, 42);
        expect(result, isA<int>());

        result = await returnsError(1).onAsync<int>(
          success: (data) async {
            fail('success callback should not be called');
          },
          error: (error) async {
            throw Exception('Exception from error handler');
          },
          onException: (exception) async {
            expect(exception, isA<Exception>());
            expect(
              exception.toString(),
              contains('Exception from error handler'),
            );
            return 99;
          },
        );

        expect(result, 99);
        expect(result, isA<int>());

        result = await returnsError(1).onAsync<int>(
          success: (data) async {
            fail('success callback should not be called');
          },
          error: (error) async {
            throw Exception('Exception from error handler');
          },
          fallback: 42,
          onException: (exception) async => 777,
        );

        expect(result, 777);
      },
    );

    test(
      '''should handle exceptions thrown in error handler for FutureResult.onAsync''',
      () async {
        final futureResult = returnsFutureSuccess(1).mapToAsync(returnsError);

        final resultObj = await futureResult;
        var result = await resultObj.onAsync<int>(
          success: (data) async {
            fail('success callback should not be called');
          },
          error: (error) async {
            throw Exception('Exception from error handler');
          },
          fallback: 42,
        );

        expect(result, 42);
        expect(result, isA<int>());

        result = await resultObj.onAsync<int>(
          success: (data) async {
            fail('success callback should not be called');
          },
          error: (error) async {
            throw Exception('Exception from error handler');
          },
          onException: (exception) async {
            expect(exception, isA<Exception>());
            expect(
              exception.toString(),
              contains('Exception from error handler'),
            );
            return 99;
          },
        );

        expect(result, 99);
        expect(result, isA<int>());
      },
    );

    test(
      '''should handle exceptions thrown in success handler with fallback and onException''',
      () async {
        var result = returnsSuccess(1).on<int>(
          success: (data) {
            throw Exception('Exception from success handler');
          },
          error: (error) {
            fail('error callback should not be called');
          },
          onException: (exception) {
            expect(exception, isA<Exception>());
            expect(
              exception.toString(),
              contains('Exception from success handler'),
            );
            return 100;
          },
        );

        expect(result, 100);

        result = await returnsSuccess(1).onAsync<int>(
          success: (data) async {
            throw Exception('Exception from success handler');
          },
          error: (error) async {
            fail('error callback should not be called');
          },
          fallback: 200,
        );

        expect(result, 200);
      },
    );
  });
}
