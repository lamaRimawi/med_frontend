import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_api.dart';

class AuthService {
  // Biometric Authentication
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Google Sign-In with Firebase
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('Google Sign-In initiated');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        print('Google Sign-In successful: ${user.email}');
        return {
          'id': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoUrl': user.photoURL,
          'idToken': googleAuth.idToken, // To send to backend
        };
      }
      return null;
    } catch (error) {
      print('Google Sign-In Error: $error');
      rethrow;
    }
  }

  static Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
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

        return {
          ...userData,
          'accessToken': result.accessToken?.tokenString,
        };
      } else {
        print('Facebook Login failed: status=${result.status}, message=${result.message}');
        return null;
      }
    } catch (e, stack) {
      print('Facebook Login Exception: $e');
      print('Stack Trace: $stack');
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
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await isDeviceSupported();

      if (!canAuthenticate) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == 'noCredentialsSet') {
        throw 'No fingerprints enrolled. Please add a fingerprint in your phone settings.';
      } else if (e.code == 'notAvailable') {
        throw 'Biometric security is not available on this device.';
      }
      throw 'Biometric error: ${e.code}';
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> getBiometricType() async {
    final List<BiometricType> availableBiometrics =
        await getAvailableBiometrics();

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
  static Future<(bool success, String? message)> loginWithBiometrics() async {
    try {
      final authenticated = await authenticateWithBiometrics();
      if (!authenticated) {
        return (false, 'Biometric authentication failed');
      }

      // Check for stored credentials
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');
      
      // If we have a valid token, we might check if it's expired or just let them in.
      // But typically, "Login with Biometrics" implies re-authenticating to get a fresh session 
      // OR mostly just bypassing the UI form if the token is valid.
      // However, if the token is expired, we need the PASSWORD to re-login.
      // AuthApi.login stores 'user_password' in SharedPrefs (insecure but requested 'functionality').
      
      final savedPassword = prefs.getString('user_password');
      // For email, we might need to store it too or decode from token (if possible).
      // Let's check if we save email. User model has email.
      // We can also save email in login.
      final savedEmail = prefs.getString('user_email');

      if (savedEmail != null && savedPassword != null) {
        // Perform unexpected backend login
        return await AuthApi.login(email: savedEmail, password: savedPassword);
      } else if (jwtToken != null) {
         // Fallback: If only token exists (maybe no restart), verify profile
         final (success, _, msg) = await AuthApi.getUserProfile();
         if (success) return (true, null);
         return (false, 'Session expired. Please log in with password.');
      } else {
        return (false, 'No credentials found. Log in with password first.');
      }
    } catch (e) {
      return (false, 'Error: $e');
    }
  }
}
