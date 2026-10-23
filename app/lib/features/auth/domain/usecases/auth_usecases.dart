import 'package:trash/core/error/failures.dart';
import 'package:trash/features/auth/domain/entities/auth_user.dart';
import 'package:trash/features/auth/domain/repositories/auth_repository.dart';

// ─────────────────────────────────────────────
// Sign In With Email
// ─────────────────────────────────────────────
class SignInWithEmailUseCase {
  final AuthRepository _repo;
  const SignInWithEmailUseCase(this._repo);

  Future<({AuthUser? user, Failure? failure})> call({
    required String email,
    required String password,
  }) =>
      _repo.signInWithEmail(email: email, password: password);
}

// ─────────────────────────────────────────────
// Sign In With Google
// ─────────────────────────────────────────────
class SignInWithGoogleUseCase {
  final AuthRepository _repo;
  const SignInWithGoogleUseCase(this._repo);

  Future<({AuthUser? user, Failure? failure})> call() => _repo.signInWithGoogle();
}

// ─────────────────────────────────────────────
// Register With Email
// ─────────────────────────────────────────────
class RegisterWithEmailUseCase {
  final AuthRepository _repo;
  const RegisterWithEmailUseCase(this._repo);

  Future<({String? uid, Failure? failure})> call({
    required String email,
    required String password,
  }) =>
      _repo.registerWithEmail(email: email, password: password);
}

// ─────────────────────────────────────────────
// Save User Profile
// ─────────────────────────────────────────────
class SaveUserProfileUseCase {
  final AuthRepository _repo;
  const SaveUserProfileUseCase(this._repo);

  Future<({bool success, Failure? failure})> call({
    required String uid,
    required String firstName,
    required String lastName,
    required String username,
    String? photoUrl,
  }) =>
      _repo.saveUserProfile(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        username: username,
        photoUrl: photoUrl,
      );
}

// ─────────────────────────────────────────────
// Check Username Available
// ─────────────────────────────────────────────
class CheckUsernameAvailableUseCase {
  final AuthRepository _repo;
  const CheckUsernameAvailableUseCase(this._repo);

  Future<({bool available, Failure? failure})> call(String username) =>
      _repo.checkUsernameAvailable(username);
}

// ─────────────────────────────────────────────
// Send / Verify OTP
// ─────────────────────────────────────────────
class SendOtpUseCase {
  final AuthRepository _repo;
  const SendOtpUseCase(this._repo);

  Future<({bool success, Failure? failure})> call(String email) => _repo.sendOtp(email);
}

class VerifyOtpUseCase {
  final AuthRepository _repo;
  const VerifyOtpUseCase(this._repo);

  Future<({bool success, Failure? failure})> call({
    required String email,
    required String otp,
  }) =>
      _repo.verifyOtp(email: email, otp: otp);
}

// ─────────────────────────────────────────────
// Forgot Password
// ─────────────────────────────────────────────
class SendPasswordResetEmailUseCase {
  final AuthRepository _repo;
  const SendPasswordResetEmailUseCase(this._repo);

  Future<({bool success, Failure? failure})> call(String email) =>
      _repo.sendPasswordResetEmail(email);
}

// ─────────────────────────────────────────────
// Sign Out
// ─────────────────────────────────────────────
class SignOutUseCase {
  final AuthRepository _repo;
  const SignOutUseCase(this._repo);

  Future<void> call() => _repo.signOut();
}
