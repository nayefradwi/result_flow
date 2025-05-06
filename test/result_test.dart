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
            expect(error, isA<UnknownError>());
            expect(
              error.toString(),
              contains('Exception from success handler'),
            );
            return 100;
          },
          onException: (exception) {
            fail('exception callback should not be called');
          },
        );

        expect(result, 100);

        result = await returnsSuccess(1).onAsync<int>(
          success: (data) async {
            throw Exception('Exception from success handler');
          },
          error: (error) async {
            expect(error, isA<UnknownError>());
            expect(
              error.toString(),
              contains('Exception from success handler'),
            );
            return 100;
          },
          fallback: 200,
        );

        expect(result, 100);

        result = await returnsError(1).onAsync<int>(
          success: (data) async {
            fail('success callback should not be called');
          },
          error: (error) async {
            throw Exception('Exception from error handler');
          },
          fallback: 42,
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
  });

  group('Result.on and onAsync - Exception Handling:', () {
    test('should handle void return type for Result.on', () {
      final callTracker = <String>[];

      returnsSuccess(42).on<void>(
        success: (data) {
          callTracker.add('success:$data');
        },
        error: (error) {
          callTracker.add('error:${error.code}');
          fail('Error callback should not be called for success case');
        },
      );

      returnsError(42).on<void>(
        success: (data) {
          callTracker.add('success:$data');
          fail('Success callback should not be called for error case');
        },
        error: (error) {
          callTracker.add('error:${error.code}');
        },
      );

      // Test for exception in success handler being passed to error handler
      returnsSuccess(100).on<void>(
        success: (data) {
          callTracker.add('before-exception:$data');
          throw Exception('Test exception in success handler');
        },
        error: (error) {
          callTracker.add('exception-handled-by-error:${error.message}');
          expect(error, isA<UnknownError>());
          expect(error.message, contains('Test exception in success handler'));
        },
        onException: (exception) {
          callTracker.add('should-not-reach-onException:$exception');
          fail(
            '''onException should not be called if error handler handles the exception''',
          );
        },
      );

      // Test for exception in success handler with onException
      returnsSuccess(200).on<void>(
        success: (data) {
          callTracker.add('before-exception:$data');
          throw Exception('Test exception in success handler 2');
        },
        error: (error) {
          callTracker.add('error-handling-throws:${error.message}');
          throw Exception('Error handler also throws');
        },
        onException: (exception) {
          callTracker.add('caught-exception:$exception');
        },
      );

      expect(callTracker, [
        'success:42',
        'error:test_error_42',
        'before-exception:100',
        '''exception-handled-by-error:Exception: Test exception in success handler''',
        'before-exception:200',
        'error-handling-throws:Exception: Test exception in success handler 2',
        'caught-exception:Exception: Error handler also throws',
      ]);
    });

    test('should handle void return type for Result.onAsync', () async {
      final callTracker = <String>[];

      await returnsSuccess(42).onAsync<void>(
        success: (data) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          callTracker.add('success:$data');
        },
        error: (error) async {
          callTracker.add('error:${error.code}');
          fail('Error callback should not be called for success case');
        },
      );

      await returnsError(42).onAsync<void>(
        success: (data) async {
          callTracker.add('success:$data');
          fail('Success callback should not be called for error case');
        },
        error: (error) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          callTracker.add('error:${error.code}');
        },
      );

      // Test for exception in success handler being passed to error handler
      await returnsSuccess(100).onAsync<void>(
        success: (data) async {
          callTracker.add('before-exception:$data');
          await Future<void>.delayed(const Duration(milliseconds: 10));
          throw Exception('Test exception in success handler');
        },
        error: (error) async {
          callTracker.add('exception-handled-by-error:${error.message}');
          expect(error, isA<UnknownError>());
          expect(error.message, contains('Test exception in success handler'));
        },
        onException: (exception) async {
          callTracker.add('should-not-reach-onException:$exception');
          fail(
            '''onException should not be called if error handler handles the exception''',
          );
        },
      );

      await returnsSuccess(150).onAsync<void>(
        success: (data) async {
          callTracker.add('before-exception-cascading:$data');
          throw Exception('Test exception in success handler');
        },
        error: (error) async {
          callTracker.add('error-throws-again:${error.message}');
          throw Exception('Error handler also throws');
        },
        onException: (exception) async {
          callTracker.add('caught-cascading-exception:$exception');
        },
      );

      final futureResult = returnsFutureSuccess(200);
      final result = await futureResult;
      await result.onAsync<void>(
        success: (data) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          callTracker.add('future-success:$data');
        },
        error: (error) async {
          fail('Error callback should not be called for success case');
        },
      );

      // Test for FutureResult with success throwing exception
      await (await returnsFutureSuccess(250)).onAsync<void>(
        success: (data) async {
          callTracker.add('future-before-exception:$data');
          throw Exception('Future success exception');
        },
        error: (error) async {
          callTracker.add('future-exception-handled:${error.message}');
          expect(error, isA<UnknownError>());
          expect(error.message, contains('Future success exception'));
        },
      );

      expect(callTracker, [
        'success:42',
        'error:test_error_42',
        'before-exception:100',
        '''exception-handled-by-error:Exception: Test exception in success handler''',
        'before-exception-cascading:150',
        'error-throws-again:Exception: Test exception in success handler',
        'caught-cascading-exception:Exception: Error handler also throws',
        'future-success:200',
        'future-before-exception:250',
        'future-exception-handled:Exception: Future success exception',
      ]);
    });

    test(
      'should handle non-void return type for Result.on when success throws',
      () {
        // Case 1: Success throws, error handles with correct return value
        var result = returnsSuccess(42).on<int>(
          success: (data) {
            throw Exception('Exception in success handler');
          },
          error: (error) {
            expect(error, isA<UnknownError>());
            expect(error.message, contains('Exception in success handler'));
            return 999;
          },
        );
        expect(result, 999);

        // Case 2: Success throws, error throws, onException handles
        result = returnsSuccess(42).on<int>(
          success: (data) {
            throw Exception('First exception');
          },
          error: (error) {
            throw Exception('Second exception');
          },
          onException: (e) {
            expect(e.toString(), contains('Second exception'));
            return 888;
          },
        );
        expect(result, 888);

        // Case 3: Success throws, error throws, fallback used
        result = returnsSuccess(42).on<int>(
          success: (data) {
            throw Exception('Exception chain');
          },
          error: (error) {
            throw Exception('Error handler fails too');
          },
          fallback: 777,
        );
        expect(result, 777);
      },
    );

    test(
      '''should handle non-void return type for Result.onAsync when success throws''',
      () async {
        // Case 1: Success throws, error handles with correct return value
        var result = await returnsSuccess(42).onAsync<int>(
          success: (data) async {
            throw Exception('Async exception in success handler');
          },
          error: (error) async {
            expect(error, isA<UnknownError>());
            expect(
              error.message,
              contains('Async exception in success handler'),
            );
            return 999;
          },
        );
        expect(result, 999);

        // Case 2: Success throws, error throws, onException handles
        result = await returnsSuccess(42).onAsync<int>(
          success: (data) async {
            throw Exception('First async exception');
          },
          error: (error) async {
            throw Exception('Second async exception');
          },
          onException: (e) async {
            expect(e.toString(), contains('Second async exception'));
            return 888;
          },
        );
        expect(result, 888);

        // Case 3: Success throws, error throws, fallback used
        result = await returnsSuccess(42).onAsync<int>(
          success: (data) async {
            throw Exception('Async exception chain');
          },
          error: (error) async {
            throw Exception('Async error handler fails too');
          },
          fallback: 777,
        );
        expect(result, 777);
      },
    );
  });
}
