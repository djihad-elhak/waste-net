import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:trash/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:trash/features/auth/domain/entities/auth_user.dart';
import 'package:trash/features/auth/domain/repositories/auth_repository.dart';
import 'package:trash/features/auth/domain/usecases/auth_usecases.dart';

// ─── Data Source ──────────────────────────────────────────────
final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource();
});

// ─── Repository ───────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(firebaseAuthDataSourceProvider));
});

// ─── Use Cases ────────────────────────────────────────────────
final signInWithEmailUseCaseProvider = Provider(
  (ref) => SignInWithEmailUseCase(ref.read(authRepositoryProvider)),
);

final signInWithGoogleUseCaseProvider = Provider(
  (ref) => SignInWithGoogleUseCase(ref.read(authRepositoryProvider)),
);

final registerWithEmailUseCaseProvider = Provider(
  (ref) => RegisterWithEmailUseCase(ref.read(authRepositoryProvider)),
);

final saveUserProfileUseCaseProvider = Provider(
  (ref) => SaveUserProfileUseCase(ref.read(authRepositoryProvider)),
);

final checkUsernameUseCaseProvider = Provider(
  (ref) => CheckUsernameAvailableUseCase(ref.read(authRepositoryProvider)),
);

final sendOtpUseCaseProvider = Provider(
  (ref) => SendOtpUseCase(ref.read(authRepositoryProvider)),
);

final verifyOtpUseCaseProvider = Provider(
  (ref) => VerifyOtpUseCase(ref.read(authRepositoryProvider)),
);

final sendPasswordResetUseCaseProvider = Provider(
  (ref) => SendPasswordResetEmailUseCase(ref.read(authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider(
  (ref) => SignOutUseCase(ref.read(authRepositoryProvider)),
);

// ─── Auth State Stream ────────────────────────────────────────
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});
