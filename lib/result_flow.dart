/// Result Flow is a Dart libarary that allows handling
/// asynchronous and synchronous operations with a functional approach.
///
/// It provides a way to represent the result of an
/// operation as either a success or an error, and allows chaining operations
/// together in a clean and readable way.
///
/// This library also treats errors as first-class citizens, allowing you
/// to handle them either by utilizing unique error codes or extending the
/// base error class to create custom error types.
library;

export 'src/error.dart';
export 'src/result.dart';
