import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/features/profile/data/profile_module.dart';
import 'package:trash/features/profile/domain/entities/user_profile.dart';

class ProfileEditState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  const ProfileEditState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  ProfileEditState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileEditState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProfileController extends Notifier<ProfileEditState> {
  @override
  ProfileEditState build() => const ProfileEditState();

  Future<void> saveProfile({
    required String userId,
    required ProfileEditData data,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final useCase = ref.read(updateProfileUseCaseProvider);
    final result = await useCase(data, userId);

    if (result.failure != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure!.message,
      );
    } else {
      state = state.copyWith(isLoading: false, isSuccess: true);
    }
  }

  Future<void> signOut() async {
    await ref.read(profileSignOutUseCaseProvider).call();
  }

  void resetSuccess() => state = state.copyWith(isSuccess: false);
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileEditState>(
        ProfileController.new);
