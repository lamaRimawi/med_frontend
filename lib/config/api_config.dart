class ApiConfig {
  // Backend base URL
  static const String baseUrl = 'http://176.119.254.185:8051';

  // Endpoints
  static const String login = '/auth/login';
  static const String vlmChat = '/vlm/chat';

  // Temporary sample image URL for backend extraction testing
  // Replace with a real, publicly accessible URL of the captured image.
  static const String sampleImageUrl =
      'https://images.drlogy.com/assets/uploads/lab/image/cbc-test-report-format-example-sample-template-drlogy-lab-report.webp';
}
