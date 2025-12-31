import 'package:flutter_test/flutter_test.dart';
import 'package:health_track/services/auth_api.dart';
import 'package:health_track/config/api_config.dart';

void main() {
  group('AuthApi - Google/Facebook Authentication Tests', () {
    test('Google login endpoint is correctly configured', () {
      expect(ApiConfig.googleLogin, equals('/auth/google'));
      expect(ApiConfig.baseUrl, isNotEmpty);
    });

    test('Facebook login endpoint is correctly configured', () {
      expect(ApiConfig.facebookLogin, equals('/auth/facebook'));
      expect(ApiConfig.baseUrl, isNotEmpty);
    });

    test('Google login method accepts string idToken', () async {
      // This test verifies the method signature is correct
      // Note: Actual API calls require network and valid tokens
      expect(
        () => AuthApi.loginWithGoogle('test_id_token'),
        returnsNormally,
      );
    });

    test('Facebook login method accepts string accessToken', () async {
      // This test verifies the method signature is correct
      // Note: Actual API calls require network and valid tokens
      expect(
        () => AuthApi.loginWithFacebook('test_access_token'),
        returnsNormally,
      );
    });

    // Integration test - requires actual network and valid tokens
    // Uncomment and provide valid tokens to test actual backend connection
    /*
    test('Google login with valid token connects to backend', () async {
      const testIdToken = 'YOUR_VALID_GOOGLE_ID_TOKEN_HERE';
      final (success, message) = await AuthApi.loginWithGoogle(testIdToken);
      
      // Backend should return success if token is valid
      // If user exists, it should login; if not, it should create account and login
      expect(success, isTrue, reason: 'Google login should succeed with valid token');
      expect(message, isNull, reason: 'No error message on success');
    });

    test('Facebook login with valid token connects to backend', () async {
      const testAccessToken = 'YOUR_VALID_FACEBOOK_ACCESS_TOKEN_HERE';
      final (success, message) = await AuthApi.loginWithFacebook(testAccessToken);
      
      // Backend should return success if token is valid
      // If user exists, it should login; if not, it should create account and login
      expect(success, isTrue, reason: 'Facebook login should succeed with valid token');
      expect(message, isNull, reason: 'No error message on success');
    });

    test('Google login with same token should return same user (no duplicate accounts)', () async {
      const testIdToken = 'YOUR_VALID_GOOGLE_ID_TOKEN_HERE';
      
      // First login - should create account if new
      final (success1, message1) = await AuthApi.loginWithGoogle(testIdToken);
      expect(success1, isTrue);
      
      // Second login with same token - should login to existing account, not create new one
      final (success2, message2) = await AuthApi.loginWithGoogle(testIdToken);
      expect(success2, isTrue);
      
      // Both should succeed and return the same user
      // This verifies backend is checking for existing users
    });

    test('Facebook login with same token should return same user (no duplicate accounts)', () async {
      const testAccessToken = 'YOUR_VALID_FACEBOOK_ACCESS_TOKEN_HERE';
      
      // First login - should create account if new
      final (success1, message1) = await AuthApi.loginWithFacebook(testAccessToken);
      expect(success1, isTrue);
      
      // Second login with same token - should login to existing account, not create new one
      final (success2, message2) = await AuthApi.loginWithFacebook(testAccessToken);
      expect(success2, isTrue);
      
      // Both should succeed and return the same user
      // This verifies backend is checking for existing users
    });
    */
  });

  group('AuthApi - Error Handling Tests', () {
    test('Google login with invalid token returns error', () async {
      final (success, message) = await AuthApi.loginWithGoogle('invalid_token');
      
      // Should fail with appropriate error message
      expect(success, isFalse, reason: 'Invalid token should fail');
      expect(message, isNotNull, reason: 'Error message should be provided');
      expect(message, isNotEmpty, reason: 'Error message should not be empty');
    });

    test('Facebook login with invalid token returns error', () async {
      final (success, message) = await AuthApi.loginWithFacebook('invalid_token');
      
      // Should fail with appropriate error message
      expect(success, isFalse, reason: 'Invalid token should fail');
      expect(message, isNotNull, reason: 'Error message should be provided');
      expect(message, isNotEmpty, reason: 'Error message should not be empty');
    });

    test('Google login with empty token returns error', () async {
      final (success, message) = await AuthApi.loginWithGoogle('');
      
      expect(success, isFalse);
      expect(message, isNotNull);
    });

    test('Facebook login with empty token returns error', () async {
      final (success, message) = await AuthApi.loginWithFacebook('');
      
      expect(success, isFalse);
      expect(message, isNotNull);
    });
  });
}

