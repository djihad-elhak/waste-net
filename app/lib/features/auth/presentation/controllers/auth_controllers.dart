import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/core/error/failures.dart';
import 'package:trash/features/auth/data/providers/auth_providers.dart';
import 'package:trash/features/auth/domain/entities/auth_user.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared Auth State
// ─────────────────────────────────────────────────────────────────────────────
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final AuthUser? user;
  final bool isSuccess;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.isSuccess = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    AuthUser? user,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: user ?? this.user,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login Controller
// ─────────────────────────────────────────────────────────────────────────────
class LoginController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final useCase = ref.read(signInWithEmailUseCaseProvider);
    final result = await useCase(email: email, password: password);

    if (result.failure != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure!.message,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        user: result.user,
        isSuccess: true,
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final useCase = ref.read(signInWithGoogleUseCaseProvider);
    final result = await useCase();

    if (result.failure != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure!.message,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        user: result.user,
        isSuccess: true,
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final loginControllerProvider = NotifierProvider<LoginController, AuthState>(
  LoginController.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Register Step 1 – Email + Password
// ─────────────────────────────────────────────────────────────────────────────
class RegisterState {
  final bool isLoading;
  final String? errorMessage;
  final String? registeredUid;
  final String? registeredEmail;
  final bool isSuccess;

  const RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.registeredUid,
    this.registeredEmail,
    this.isSuccess = false,
  });

  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? registeredUid,
    String? registeredEmail,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      registeredUid: registeredUid ?? this.registeredUid,
      registeredEmail: registeredEmail ?? this.registeredEmail,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class RegisterController extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState();

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final useCase = ref.read(registerWithEmailUseCaseProvider);
    final result = await useCase(email: email, password: password);

    if (result.failure != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure!.message,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        registeredUid: result.uid,
        registeredEmail: email,
        isSuccess: true,
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final registerControllerProvider =
    NotifierProvider<RegisterController, RegisterState>(RegisterController.new);

// ─────────────────────────────────────────────────────────────────────────────
// Register Step 2 – Profile Details
// ─────────────────────────────────────────────────────────────────────────────
class ProfileSetupState {
  final bool isLoading;
  final String? errorMessage;
  final bool? usernameAvailable;
  final bool isCheckingUsername;
  final bool isSuccess;

  const ProfileSetupState({
    this.isLoading = false,
    this.errorMessage,
    this.usernameAvailable,
    this.isCheckingUsername = false,
    this.isSuccess = false,
  });

  ProfileSetupState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? usernameAvailable,
    bool? isCheckingUsername,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return ProfileSetupState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      usernameAvailable: usernameAvailable ?? this.usernameAvailable,
      isCheckingUsername: isCheckingUsername ?? this.isCheckingUsername,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ProfileSetupController extends Notifier<ProfileSetupState> {
  @override
  ProfileSetupState build() => const ProfileSetupState();

  Future<void> checkUsername(String username) async {
    if (username.length < 3) {
      state = state.copyWith(usernameAvailable: null);
      return;
    }
    state = state.copyWith(isCheckingUsername: true);
    final useCase = ref.read(checkUsernameUseCaseProvider);
    final result = await useCase(username);
    state = state.copyWith(
      isCheckingUsername: false,
      usernameAvailable: result.available,
    );
  }

  Future<void> saveProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String username,
    String? photoUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final useCase = ref.read(saveUserProfileUseCaseProvider);
    final result = await useCase(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      username: username,
      photoUrl: photoUrl,
    );

    if (result.failure != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure!.message,
      );
    } else {
      state = state.copyWith(isLoading: false, isSuccess: true);
    }
  }
}

final profileSetupControllerProvider =
    NotifierProvider<ProfileSetupController, ProfileSetupState>(
        ProfileSetupController.new);

// ─────────────────────────────────────────────────────────────────────────────
// Forgot Password Controller
// ─────────────────────────────────────────────────────────────────────────────
class ForgotPasswordState {
  final bool isLoading;
  final String? errorMessage;
  final bool isEmailSent;

  const ForgotPasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.isEmailSent = false,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isEmailSent,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isEmailSent: isEmailSent ?? this.isEmailSent,
    );
  }
}

class ForgotPasswordController extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  Future<void> sendResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final useCase = ref.read(sendPasswordResetUseCaseProvider);
    final result = await useCase(email);

    if (result.failure != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure!.message,
      );
    } else {
      state = state.copyWith(isLoading: false, isEmailSent: true);
    }
  }
}

final forgotPasswordControllerProvider =
    NotifierProvider<ForgotPasswordController, ForgotPasswordState>(
        ForgotPasswordController.new);
