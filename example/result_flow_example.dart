// ignore_for_file: avoid_print

import 'package:result_flow/result_flow.dart';

const validEmail = 'test@test.com';
const validPassword = 'test1234';

class AccessToken {
  AccessToken(this.randomNumber);
  final int randomNumber;
}

class User {
  User(this.email, this.password);
  final String email;
  final String password;
}

void main() async {
  final validUserResult = await login(validEmail, validPassword);
  validUserResult.on(
    success: (user) => print(' ✅ user(${user.email}, ${user.password})}'),
    error: (_) => print(' ❌ this should not be printed'),
  );

  final invalidUserEmailResult = await login('', '');
  invalidUserEmailResult.on(
    success: (user) => print(' ❌ this should not be printed'),
    error: (error) {
      print(' ❌ ${error.code}: ${error.message}');
      if (error is ValidationError) {
        for (final field in error.details.entries) {
          print(' ❌ ${field.key}: ${field.value.message}');
        }
      }
    },
  );

  final invalidUserPasswordResult = await login(validEmail, 'wrongpassword');
  invalidUserPasswordResult.on(
    success: (user) => print(' ❌ this should not be printed'),
    error: (error) {
      print(' ❌ ${error.code}: ${error.message}');
      if (error is ValidationError) {
        for (final field in error.details.entries) {
          print(' ❌ ${field.key}: ${field.value.message}');
        }
      }
    },
  );

  final invalidUserButMappedToValid = await login('', '')
      .handle((err) => Result.success(User('valid email', 'valid password')))
      .mapToAsync((data) {
        print(' ✅ error mapped to user(${data.email}, ${data.password})}');
        return Result.success(data);
      });

  invalidUserButMappedToValid.on(
    success: (user) => print(' ✅ user(${user.email}, ${user.password})}'),
    error: (_) => print(' ❌ this should not be printed'),
  );

  final user = validUserResult.data;
  if (user != null) {
    print(' ✅ user(${user.email}, ${user.password})}');
  }

  final invalidUser = invalidUserEmailResult.data;
  if (invalidUser == null) {
    print(' ❌ cannot get user data because of result being error');
  }

  final invalidUserButMappedToValidData = invalidUserButMappedToValid.data;
  if (invalidUserButMappedToValidData != null) {
    print(
      ''' ✅ user(${invalidUserButMappedToValidData.email}, ${invalidUserButMappedToValidData.password})}''',
    );
  }
}

Future<Result<User>> login(String email, String password) async {
  return validateEmail(email)
      .mapTo((_) => validatePassword(password))
      .continueWith((_) {
        return Result.safeRunAsync(() async => getAccessToken(email, password));
      })
      .continueWith(getUser);
}

Result<void> validateEmail(String email) {
  if (email.isEmpty) {
    return Result.error(
      ValidationError(
        details: {'email': ValidationErrorFields.fromField('email')},
      ),
    );
  }

  return Result.success(null);
}

Result<void> validatePassword(String password) {
  if (password.isEmpty) {
    return Result.error(
      ValidationError(
        details: {'password': ValidationErrorFields.fromField('password')},
      ),
    );
  }

  return Result.success(null);
}

Future<AccessToken> getAccessToken(String email, String password) async {
  if (email == validEmail && password == validPassword) {
    return AccessToken(123456);
  } else {
    throw DomainError('Invalid credentials', code: 'invalid_credentials');
  }
}

Future<Result<User>> getUser(AccessToken token) async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return Result.success(User(validEmail, validPassword));
}
