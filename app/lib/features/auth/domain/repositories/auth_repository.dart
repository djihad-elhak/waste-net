import 'package:trash/core/error/failures.dart';
import 'package:trash/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  /// Stream of auth state changes
  Stream<AuthUser?> get authStateChanges;

  /// Current user (null if not authenticated)
  AuthUser? get currentUser;

  /// Sign in with email and password
  Future<({AuthUser? user, Failure? failure})> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google
  Future<({AuthUser? user, Failure? failure})> signInWithGoogle();

  /// Register with email/password (returns uid for OTP step)
  Future<({String? uid, Failure? failure})> registerWithEmail({
    required String email,
    required String password,
  });

  /// Save user profile after registration
  Future<({bool success, Failure? failure})> saveUserProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String username,
    String? photoUrl,
  });

  /// Check if username is available
  Future<({bool available, Failure? failure})> checkUsernameAvailable(String username);

  /// Send OTP to email
  Future<({bool success, Failure? failure})> sendOtp(String email);

  /// Verify OTP
  Future<({bool success, Failure? failure})> verifyOtp({
    required String email,
    required String otp,
  });

  /// Send password reset email
  Future<({bool success, Failure? failure})> sendPasswordResetEmail(String email);

  /// Sign out
  Future<void> signOut();
}
