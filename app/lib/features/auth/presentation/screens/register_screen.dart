import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:trash/features/auth/presentation/widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(registerControllerProvider.notifier).registerWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);

    // Move to profile setup on success
    ref.listen<RegisterState>(registerControllerProvider, (prev, next) {
      if (next.isSuccess && next.registeredUid != null) {
        context.push(
          AppConstants.routeRegisterDetails,
          extra: {
            'uid': next.registeredUid,
            'email': next.registeredEmail,
          },
        );
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

              // Header
              Text('Create account', style: AppTextStyles.displayMedium),
              const SizedBox(height: 6),
              Text(
                'Join thousands cleaning the streets',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 12),

              // Progress indicator
              _StepIndicator(currentStep: 1, totalSteps: 2),

              const SizedBox(height: 28),

              // Error
              if (state.errorMessage != null) ...[
                AppErrorBanner(message: state.errorMessage!),
                const SizedBox(height: 16),
              ],

              // Google option at top
              GoogleSignInButton(
                label: 'Sign up with Google',
                onPressed: () {
                  // Reuse google sign in from login
                  ref.read(loginControllerProvider.notifier).signInWithGoogle();
                },
              ),

              const SizedBox(height: 20),
              const OrDivider(),
              const SizedBox(height: 20),

              // Email
              AppTextField(
                controller: _emailCtrl,
                label: 'Email address',
                hint: 'you@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(v)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Password
              AppTextField(
                controller: _passwordCtrl,
                label: 'Password',
                hint: 'At least 8 characters',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 8) return 'At least 8 characters required';
                  if (!v.contains(RegExp(r'[0-9]'))) {
                    return 'Include at least one number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Confirm password
              AppTextField(
                controller: _confirmPasswordCtrl,
                label: 'Confirm password',
                hint: 'Repeat your password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _register(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your password';
                  if (v != _passwordCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),

              const SizedBox(height: 8),

              // Password strength hints
              _PasswordHints(password: _passwordCtrl.text),

              const SizedBox(height: 28),

              AppPrimaryButton(
                label: 'Continue',
                isLoading: state.isLoading,
                onPressed: _register,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              ),

              const SizedBox(height: 24),

              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: AppTextStyles.bodyMedium,
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Terms
              Center(
                child: Text(
                  'By signing up you agree to our Terms & Privacy Policy',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────
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

// ─── Password Hints ───────────────────────────────────────────
class _PasswordHints extends StatelessWidget {
  final String password;

  const _PasswordHints({required this.password});

  @override
  Widget build(BuildContext context) {
    final hasLength = password.length >= 8;
    final hasNumber = password.contains(RegExp(r'[0-9]'));

    return Column(
      children: [
        _Hint(label: 'At least 8 characters', met: hasLength),
        const SizedBox(height: 4),
        _Hint(label: 'Contains a number', met: hasNumber),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  final String label;
  final bool met;

  const _Hint({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 14,
          color: met ? AppColors.accentGreen : AppColors.textHint,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: met ? AppColors.accentGreen : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
