abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong. Please try again.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure() : super('This email is already registered.');
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure() : super('Invalid email or password.');
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure() : super('No account found with this email.');
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure() : super('Password must be at least 8 characters.');
}

class InvalidOtpFailure extends Failure {
  const InvalidOtpFailure() : super('Invalid or expired OTP. Please try again.');
}

class UsernameTakenFailure extends Failure {
  const UsernameTakenFailure() : super('This username is already taken.');
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data error.']);
}
