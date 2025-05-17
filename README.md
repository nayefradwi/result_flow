# result_flow

[![pub package](https://img.shields.io/pub/v/result_flow.svg)](https://pub.dev/packages/result_flow) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This package provides a Dart/Flutter implementation of the Result pattern, influenced by approaches in modern languages where errors are often treated as return values alongside success values. It introduces `Result<T>`, a type that encapsulates either a success value (`T`) or an error (`ResultError`), facilitating more explicit error handling and reducing the need for exceptions for expected failure paths or standard control flow.

## Features

- ✨ **Explicit Outcomes:** Clearly represent success (`Result.success<T>`) and failure (`Result.error<E extends ResultError>`) states, making control flow predictable and safe.
- 🔗 **Fluent Chaining:** Link operations sequentially using distinctly named methods: `mapTo` for synchronous calls and `continueWith` for asynchronous calls. Errors automatically propagate, simplifying complex workflows.
- ❓ **Optional Handling:** Safely access success data with the `data` getter or error details with the `error` getter. These methods return `null` if the `Result` is not in the corresponding state, integrating smoothly with nullable type handling.
- 👐 **Flexible Handling:** Process the `Result` using methods like `on` (handles both success and error cases in one go), `onSuccess` (runs code only on success), `onError` (runs code only on error), and their asynchronous counterparts (`onAsync`).
- 🧱 **Extendible Errors:** Define custom, specific error types by extending the base `ResultError` class, allowing for rich, domain-specific failure information (e.g., `NetworkError`, `ValidationError`).
- 🏷️ **Error Codes:** `ResultError` includes an optional `code` (String) field, enabling identifier-based error handling, localization lookups, or routing to specific error recovery logic based on a unique code.

## Getting Started

To add `result_flow` to your project, run one of the following commands in your terminal:

```bash
# For Flutter projects
flutter pub add result_flow

# For Dart projects
dart pub add result_flow
```

## Usage

Here are some common ways to use the result_flow package:

1. Safely Execute Potentially Failing Code

Use Result.safeRun or Result.safeRunAsync to wrap functions that might throw exceptions (like network calls or parsing). They automatically catch errors and return a Result.error.

```dart
FutureResult<BankAccount> _fetchBankAccount() {
    return Result.safeRunAsync(() async => await _apiCallToGetBankAccount());
}
```

2. Handle domain logic

Provide error codes to trigger different custom flows like displaying unique messages or performing fallback actions

```dart
Result<double> _gambleLifeSavings(int currentBalance) {
    final random = Random();
    double maxAbsoluteGamble = currentBalance > 0 ? currentBalance.toDouble() : 1.0;
    double amountToDeduct = (random.nextDouble() * 2 * maxAbsoluteGamble) - maxAbsoluteGamble;
    double newBalance = currentBalance.toDouble() - amountToDeduct;

    if(newBalance < 0) {
        return Result.error(DomainError('negative', code: 'you_lost_all_your_money'));
    } else if(newBalance > currentBalance) {
        return Result.error(DomainError('gained money', code: 'you_gained_money_somehow'));
    }

    return Result.success(newBalance);
}

void printError(String message, {String? code}){
    if(code == null) return print(message);
    return switch(code) {
        'you_gained_money_somehow' => print('congratulations!'),
        'you_lost_all_your_money' => print('that is very sad, gambling is bad'),
        _ => print('oops something unexpected happend'),
    };
}
```

3. Chain Operations and Handle Outcomes with on

Link multiple steps like fetching, parsing, validating stock, and calculating price. If any step returns an error, the subsequent steps are skipped.

Use `result.on()` to provide callbacks for both success and error scenarios. Check the error's code for specific handling logic.

```dart
Future<void> gambleAlittle() async {
    final result = await _fetchBankAccount()
    .mapToAsync((data) => _gambleLifeSavings(data.savings))
    .continueWith((data) async => await _fetchBankAccount())
    .mapToAsync((data) => _gambleLifeSavings(data.savings))
    .continueWith((data) async => await _fetchBankAccount())
    .mapToAsync((data) => _gambleLifeSavings(data.savings));

    result.on(
        success: (data) => print(data.toString()),
        error: (error) => printError(error.message, code: error.code),
    );
}
```

## Related Packages

`result_flow` provides other packages built on top of it for different requirements like `result_flow_dio`
that allows `dio` responses to return safe results.

| Package           | Pub.dev Link                                                                                                 |
| :---------------- | :----------------------------------------------------------------------------------------------------------- |
| `result_flow`     | [![pub package](https://img.shields.io/pub/v/result_flow.svg)](https://pub.dev/packages/result_flow)         |
| `result_flow_dio` | [![pub package](https://img.shields.io/pub/v/result_flow_dio.svg)](https://pub.dev/packages/result_flow_dio) |
