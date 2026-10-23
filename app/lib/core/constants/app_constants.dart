class AppConstants {
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String claimsCollection = 'claims';
  static const String missionsCollection = 'missions';

  // Shared Prefs Keys
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyGuestClaimCount = 'guest_claim_count';

  // Guest limits
  static const int guestMaxClaims = 3;

  // Validation
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int minPasswordLength = 8;
  static const int otpLength = 6;
  static const int otpResendSeconds = 60;

  // Routes
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeRegisterDetails = '/register/details';
  static const String routeOtp = '/otp';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeHome = '/home';
  static const String routeCamera = '/claim/camera';
  static const String routeResult = '/claim/result';
  static const String routeMap = '/map';
  static const String routeMissions = '/missions';
  static const String routeSocial = '/social';
  static const String routeProfile = '/profile';
  static const String routeRewards = '/rewards';
}
