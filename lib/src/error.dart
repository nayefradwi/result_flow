const String unknownErrorCode = 'UNKNOWN_ERROR';
const String validationErrorCode = 'VALIDATION_ERROR';

/// Base class for all errors that allow customization either through
/// unique error codes or by extending the base error class.
///
/// This class is designed to be used as a base class for all errors
/// that can occur in the application.
///
/// It provides a way to represent the error message and an optional
/// error code that can be used to identify the error type.
abstract class ResultError extends Error {
  ResultError(this.message, {this.code, this.trace});

  /// Creates a ResultError with a specific error code.
  /// This constructor is useful for creating errors that are
  /// associated with a specific error code. and syntaxically shorter.
  ResultError.fromCode(String code)
    : this('error with code: $code', code: code);

  final String message;
  final String? code;
  final StackTrace? trace;

  @override
  String toString() {
    return 'ResultError($code): $message';
  }
}

/// A class representing a network error.
/// This class extends the ResultError class and provides additional
/// functionality for handling network-related errors.
///
/// It includes a status code to represent the HTTP status code
/// associated with the error, and overrides the toString method
/// to provide a more detailed error message.
class NetworkError extends ResultError {
  NetworkError(super.message, {super.code, this.statusCode = 0});
  NetworkError.fromCode(String code, {int statusCode = 0})
    : this(
        'network error with code: $code',
        code: code,
        statusCode: statusCode,
      );
  final int statusCode;

  @override
  String toString() {
    return 'NetworkError($code, $statusCode): $message';
  }
}

/// A class used as a generic error and a wrapper to uncaught exceptions.
class UnknownError extends ResultError {
  UnknownError({
    required super.trace,
    String message = 'unknown error',
    super.code = unknownErrorCode,
  }) : super(message);
}

/// A class that can be used to represent a domain specific errors like invalid
/// internal operations or operations not following specific business rules.
class DomainError extends ResultError {
  DomainError(super.message, {required String code}) : super(code: code);

  DomainError.fromCode(String code)
    : this('domain error with code: $code', code: code);
}

/// A class representing a validation error. This class allows for form
/// validation and provides a way to represent the details of the validation
/// error for each field.
///
/// Using [ValidationErrorFields] you can add multiple fields to the error
/// details.
class ValidationError extends ResultError {
  ValidationError({required this.details})
    : super('invalid data', code: validationErrorCode);
  ValidationError.fromField(String field)
    : this(details: {field: ValidationErrorFields.fromField(field)});

  final Map<String, ValidationErrorFields> details;

  void addField(String field) {
    details[field] = ValidationErrorFields.fromField(field);
  }

  void addFields(List<String> fields) {
    for (final field in fields) {
      details[field] = ValidationErrorFields.fromField(field);
    }
  }

  ValidationErrorFields? getField(String field) {
    return details[field];
  }

  @override
  String toString() {
    return 'ValidationError($code): $details';
  }
}

/// A class representing a validation error for a specific field.
/// This class is used to represent the details of the validation error
/// for a specific field in the form.
class ValidationErrorFields {
  ValidationErrorFields({required this.field, required this.message});
  factory ValidationErrorFields.fromField(String field) =>
      ValidationErrorFields(field: field, message: 'invalid $field');

  final String field;
  final String message;
}
