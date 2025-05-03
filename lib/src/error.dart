import 'package:safe_result/src/lookup.dart';

const String unknownErrorCode = 'UNKNOWN_ERROR';
const String validationErrorCode = 'VALIDATION_ERROR';

abstract class ResultError extends Error {
  ResultError(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() {
    return 'ResultError($code): $message';
  }
}

class NetworkError extends ResultError {
  NetworkError(super.message, {super.code, this.statusCode = 0});
  final int statusCode;

  @override
  String toString() {
    return 'NetworkError($code, $statusCode): $message';
  }
}

class UnknownError extends ResultError {
  UnknownError({
    String message = 'unknown error',
    super.code = unknownErrorCode,
  }) : super(message);
}

class DomainError extends ResultError {
  DomainError(super.message, {required String code}) : super(code: code);
}

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

  @override
  String toString() {
    return 'ValidationError($code): $details';
  }
}

class ValidationErrorFields with LookUpModel<String> {
  ValidationErrorFields({required this.field, required this.message});
  factory ValidationErrorFields.fromField(String field) =>
      ValidationErrorFields(field: field, message: 'invalid $field');
  final String field;
  final String message;

  @override
  String get lookupKey => field;
}
