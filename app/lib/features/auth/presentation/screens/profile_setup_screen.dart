import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:trash/features/auth/presentation/widgets/auth_widgets.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String uid;
  final String email;

  const ProfileSetupScreen({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  String? _photoPath;
  Timer? _usernameDebounce;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    if (value.length < AppConstants.minUsernameLength) return;
    _usernameDebounce = Timer(const Duration(milliseconds: 600), () {
      ref.read(profileSetupControllerProvider.notifier).checkUsername(value);
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (file != null) {
      setState(() => _photoPath = file.path);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final state = ref.read(profileSetupControllerProvider);
    if (state.usernameAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username is already taken')),
      );
      return;
    }

    ref.read(profileSetupControllerProvider.notifier).saveProfile(
          uid: widget.uid,
          firstName: _firstNameCtrl.text,
          lastName: _lastNameCtrl.text,
          username: _usernameCtrl.text,
          photoUrl: _photoPath,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSetupControllerProvider);

    ref.listen<ProfileSetupState>(profileSetupControllerProvider, (prev, next) {
      if (next.isSuccess) {
        context.go(AppConstants.routeHome);
      }
    });

    return AuthScreenShell(
      showBackButton: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Text('Your profile', style: AppTextStyles.displayMedium),
              const SizedBox(height: 6),
              Text(
                'How should the community know you?',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 12),
              _StepIndicator(currentStep: 2, totalSteps: 2),
              const SizedBox(height: 32),

              // Error
              if (state.errorMessage != null) ...[
                AppErrorBanner(message: state.errorMessage!),
                const SizedBox(height: 16),
              ],

              // Avatar picker
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          border: Border.all(
                            color: AppColors.accentGreen.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: _photoPath != null
                            ? ClipOval(
                                child: Image.asset(
                                  _photoPath!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person_rounded,
                                size: 44,
                                color: AppColors.textSecondary,
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: AppColors.background,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),
              Center(
                child: Text('Upload photo', style: AppTextStyles.caption),
              ),

              const SizedBox(height: 28),

              // First + Last name row
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _firstNameCtrl,
                      label: 'First name',
                      hint: 'Ahmed',
                      prefixIcon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _lastNameCtrl,
                      label: 'Last name',
                      hint: 'Benali',
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Username
              AppTextField(
                controller: _usernameCtrl,
                label: 'Username',
                hint: 'greenwarrior42',
                prefixIcon: Icons.alternate_email_rounded,
                textInputAction: TextInputAction.done,
                onChanged: _onUsernameChanged,
                onSubmitted: (_) => _submit(),
                suffixWidget: _UsernameSuffix(state: state),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Username is required';
                  if (v.length < AppConstants.minUsernameLength) {
                    return 'At least ${AppConstants.minUsernameLength} characters';
                  }
                  if (v.length > AppConstants.maxUsernameLength) {
                    return 'Max ${AppConstants.maxUsernameLength} characters';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                    return 'Only letters, numbers and _';
                  }
                  return null;
                },
              ),

              // Username availability message
              if (state.usernameAvailable != null && !state.isCheckingUsername) ...[
                const SizedBox(height: 6),
                _UsernameAvailability(available: state.usernameAvailable!),
              ],

              const SizedBox(height: 32),

              AppPrimaryButton(
                label: 'Create Account 🌱',
                isLoading: state.isLoading,
                onPressed: _submit,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step Indicator (reused) ──────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final isActive = i + 1 <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? AppColors.accentGreen : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Username Suffix Icon ─────────────────────────────────────
class _UsernameSuffix extends StatelessWidget {
  final ProfileSetupState state;

  const _UsernameSuffix({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (state.usernameAvailable == true) {
      return const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen);
    }
    if (state.usernameAvailable == false) {
      return const Icon(Icons.cancel_rounded, color: AppColors.error);
    }
    return const SizedBox.shrink();
  }
}

// ─── Username Availability Text ───────────────────────────────
class _UsernameAvailability extends StatelessWidget {
  final bool available;

  const _UsernameAvailability({required this.available});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          available ? Icons.check_rounded : Icons.close_rounded,
          size: 14,
          color: available ? AppColors.accentGreen : AppColors.error,
        ),
        const SizedBox(width: 4),
        Text(
          available ? 'Username is available!' : 'Username is already taken',
          style: AppTextStyles.caption.copyWith(
            color: available ? AppColors.accentGreen : AppColors.error,
          ),
        ),
      ],
    );
  }
}
