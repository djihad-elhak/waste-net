import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:trash/features/auth/presentation/widgets/auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _sendReset() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetEmail(_emailCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);

    return AuthScreenShell(
      showBackButton: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: state.isEmailSent
            ? _SuccessState(email: _emailCtrl.text)
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Center(
                        child: Text('🔑', style: TextStyle(fontSize: 32)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text('Reset password', style: AppTextStyles.displayMedium),
                    const SizedBox(height: 8),
                    Text(
                      "Enter your email and we'll send you a reset link.",
                      style: AppTextStyles.bodyMedium,
                    ),

                    const SizedBox(height: 32),

                    if (state.errorMessage != null) ...[
                      AppErrorBanner(message: state.errorMessage!),
                      const SizedBox(height: 16),
                    ],

                    AppTextField(
                      controller: _emailCtrl,
                      label: 'Email address',
                      hint: 'you@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _sendReset(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    AppPrimaryButton(
                      label: 'Send Reset Link',
                      isLoading: state.isLoading,
                      onPressed: _sendReset,
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text('Back to Sign In'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Email Sent Success ───────────────────────────────────────
class _SuccessState extends StatelessWidget {
  final String email;

  const _SuccessState({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        // Success animation placeholder (use Lottie in production)
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentGreen.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: const Center(
            child: Text('📧', style: TextStyle(fontSize: 40)),
          ),
        ),

        const SizedBox(height: 28),

        Text('Check your email', style: AppTextStyles.headlineLarge),
        const SizedBox(height: 12),
        Text(
          'We sent a password reset link to',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.accentGreen,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 40),

        AppPrimaryButton(
          label: 'Back to Sign In',
          onPressed: () => context.go(AppConstants.routeLogin),
        ),

        const SizedBox(height: 16),

        TextButton(
          onPressed: () {
            // Resend
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
          child: Text(
            "Didn't receive it? Resend",
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
