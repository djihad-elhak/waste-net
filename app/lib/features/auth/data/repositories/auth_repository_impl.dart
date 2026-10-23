import 'package:trash/core/error/failures.dart';
import 'package:trash/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:trash/features/auth/domain/entities/auth_user.dart';
import 'package:trash/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _dataSource;

  const AuthRepositoryImpl(this._dataSource);

  @override
  Stream<AuthUser?> get authStateChanges => _dataSource.authStateChanges;

  @override
  AuthUser? get currentUser => _dataSource.currentUser;

  @override
  Future<({AuthUser? user, Failure? failure})> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _dataSource.signInWithEmail(email: email, password: password);

  @override
  Future<({AuthUser? user, Failure? failure})> signInWithGoogle() =>
      _dataSource.signInWithGoogle();

  @override
  Future<({String? uid, Failure? failure})> registerWithEmail({
    required String email,
    required String password,
  }) =>
      _dataSource.registerWithEmail(email: email, password: password);

  @override
  Future<({bool success, Failure? failure})> saveUserProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String username,
    String? photoUrl,
  }) =>
      _dataSource.saveUserProfile(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        username: username,
        photoUrl: photoUrl,
      );

  @override
  Future<({bool available, Failure? failure})> checkUsernameAvailable(
          String username) =>
      _dataSource.checkUsernameAvailable(username);

  @override
  Future<({bool success, Failure? failure})> sendOtp(String email) =>
      _dataSource.sendOtp(email);

  @override
  Future<({bool success, Failure? failure})> verifyOtp({
    required String email,
    required String otp,
  }) =>
      _dataSource.verifyOtp(email: email, otp: otp);

  @override
  Future<({bool success, Failure? failure})> sendPasswordResetEmail(
          String email) =>
      _dataSource.sendPasswordResetEmail(email);

  @override
  Future<void> signOut() => _dataSource.signOut();
}
