import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class AuthService {
  // Biometric Authentication
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Google Sign-In (Placeholder - requires Firebase setup)
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // TODO: Implement Google Sign-In with Firebase Auth
      // For now, return a simulated response
      print('Google Sign-In initiated');
      print('Note: Requires Firebase configuration to work');
      
      // Simulate a delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Return null to indicate not configured
      return null;
    } catch (error) {
      print('Google Sign-In Error: $error');
      return null;
    }
  }

  static Future<void> signOutGoogle() async {
    print('Google Sign-Out');
  }

  // Facebook Login
  static Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Get user data
        final userData = await FacebookAuth.instance.getUserData();
        print('Facebook Login successful');
        print('Access Token: ${result.accessToken?.tokenString}');
        print('User Data: $userData');
        
        // TODO: Send token to your backend
        // final response = await http.post(
        //   Uri.parse('YOUR_BACKEND_URL/auth/facebook'),
        //   body: {'accessToken': result.accessToken?.tokenString},
        // );
        
        return userData;
      } else {
        print('Facebook Login failed: ${result.status}');
        return null;
      }
    } catch (error) {
      print('Facebook Login Error: $error');
      return null;
    }
  }

  static Future<void> signOutFacebook() async {
    await FacebookAuth.instance.logOut();
  }

  // Biometric Authentication
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }

  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  static Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await canCheckBiometrics();
      final bool canAuthenticate = canAuthenticateWithBiometrics || await isDeviceSupported();

      if (!canAuthenticate) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  static Future<String> getBiometricType() async {
    final List<BiometricType> availableBiometrics = await getAvailableBiometrics();
    
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (availableBiometrics.contains(BiometricType.strong)) {
      return 'Biometric';
    }
    return 'Biometric';
  }
}
