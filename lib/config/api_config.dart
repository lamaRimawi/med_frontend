class ApiConfig {
  // Backend base URL
  static const String baseUrl = 'http://176.119.254.185:8051';

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String verifyResetCode = '/auth/verify-reset-code';
  static const String resendVerification = '/auth/resend-verification';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String vlmChat = '/vlm/chat';
  static const String userProfile = '/users/profile';
  static const String deleteAccount = '/users/delete-account';
  static const String reports = '/reports';
  static const String reportsTimeline = '/reports/timeline';
  static const String reportsStats = '/reports/stats';
  static const String reportsTrends = '/reports/trends';

  // Temporary sample image URL for backend extraction testing
  // Replace with a real, publicly accessible URL of the captured image.
  static const String sampleImageUrl =
      'https://images.drlogy.com/assets/uploads/lab/image/cbc-test-report-format-example-sample-template-drlogy-lab-report.webp';
}
