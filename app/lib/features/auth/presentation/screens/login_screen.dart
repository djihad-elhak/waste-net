import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:trash/features/auth/presentation/widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _signIn() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginControllerProvider.notifier).signInWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
  }

  void _signInWithGoogle() {
    ref.read(loginControllerProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(loginControllerProvider);

    // Navigate to home on success
    ref.listen<AuthState>(loginControllerProvider, (prev, next) {
      if (next.isSuccess) {
        context.go(AppConstants.routeHome);
      }
    });

    return AuthScreenShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Logo
              Center(child: TrashGoLogo(size: 72)),

              const SizedBox(height: 40),

              // Title
              Text('Welcome back', style: AppTextStyles.displayMedium),
              const SizedBox(height: 6),
              Text(
                'Sign in to keep cleaning & earning',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 32),

              // Error banner
              if (authState.errorMessage != null) ...[
                AppErrorBanner(message: authState.errorMessage!),
                const SizedBox(height: 16),
              ],

              // Email
              AppTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'you@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                focusNode: _emailFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Password
              AppTextField(
                controller: _passwordCtrl,
                label: 'Password',
                hint: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                focusNode: _passwordFocus,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signIn(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppConstants.routeForgotPassword),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.accentGreen,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.accentGreen,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign in button
              AppPrimaryButton(
                label: 'Sign In',
                isLoading: authState.isLoading,
                onPressed: _signIn,
              ),

              const SizedBox(height: 20),

              // Divider
              const OrDivider(),

              const SizedBox(height: 20),

              // Google
              GoogleSignInButton(
                onPressed: _signInWithGoogle,
                isLoading: authState.isLoading,
              ),

              const SizedBox(height: 32),

              // Sign up link
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: AppTextStyles.bodyMedium,
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.push(AppConstants.routeRegister),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Guest mode
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppConstants.routeHome),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textHint,
                  ),
                  child: Text(
                    'Continue as Guest',
                    style: AppTextStyles.caption.copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textHint,
                    ),
                  ),
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
