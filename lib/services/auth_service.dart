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
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        print('Google Sign-In successful: ${user.email}');
        print('Google Display Name: ${user.displayName}');
        print('Google Photo URL: ${user.photoURL}');
        return {
          'id': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoUrl': user.photoURL,
          'idToken': googleAuth.idToken, // To send to backend
          'accessToken': googleAuth
              .accessToken, // Important for getting birthday and phone
        };
      }
      return null;
    } on PlatformException catch (error) {
      print(
        'Google Sign-In Platform Exception: ${error.code} - ${error.message}',
      );
      if (error.code == 'sign_in_failed' || error.code == 'exception') {
        print(
          '⚠️ This is often caused by a missing SHA-1 fingerprint in the Firebase Console.',
        );
        print(
          '⚠️ Make sure you have added the SHA-1 fingerprint of your debug keystore to the Firebase project settings.',
        );
      }
      rethrow;
    } catch (error) {
      print('Google Sign-In Error: $error');
      rethrow;
    }
  }

  static Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  static Future<Map<String, dynamic>?> trySilentGoogleLogin() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signInSilently();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        return {
          'id': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoUrl': user.photoURL,
          'idToken': googleAuth.idToken,
          'accessToken': googleAuth
              .accessToken, // Important for getting birthday and phone
        };
      }
      return null;
    } catch (e) {
      print('Silent Google Login Error: $e');
      return null;
    }
  }

  // Facebook Login
  static Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      // Request additional permissions
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Get user data with all requested permissions
        final userData = await FacebookAuth.instance.getUserData(
          fields: 'email,name,first_name,last_name,picture',
        );
        print('Facebook Login successful');
        print('Access Token: ${result.accessToken?.tokenString}');
        print('User Data: $userData');
        print('📋 Facebook Data Retrieved:');
        print('   - Email: ${userData['email']}');
        print('   - Name: ${userData['name']}');
        print('   - First Name: ${userData['first_name']}');
        print('   - Last Name: ${userData['last_name']}');

        // TODO: Send token to your backend
        // final response = await http.post(
        //   Uri.parse('YOUR_BACKEND_URL/auth/facebook'),
        //   body: {'accessToken': result.accessToken?.tokenString},
        // );

        return {...userData, 'accessToken': result.accessToken?.tokenString};
      } else {
        print(
          'Facebook Login failed: status=${result.status}, message=${result.message}',
        );
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
      print('🔐 Starting biometric authentication...');

      final prefs = await SharedPreferences.getInstance();
      final biometricAllowed =
          prefs.getBool('user_biometric_allowed') ?? true;
      if (!biometricAllowed) {
        print('❌ Biometric login is disabled for this account (local flag)');
        return (false, 'Biometric login is disabled for this account');
      }

      // First, check if biometrics are available
      final canAuth = await canCheckBiometrics() || await isDeviceSupported();
      if (!canAuth) {
        print('❌ Biometrics not available on this device');
        return (
          false,
          'Biometric authentication is not available on this device',
        );
      }

      // Authenticate with biometrics (Face ID/Fingerprint)
      final authenticated = await authenticateWithBiometrics();
      if (!authenticated) {
        print('❌ Biometric authentication failed or cancelled');
        return (false, 'Biometric authentication failed or cancelled');
      }

      print('✅ Biometric authentication successful');

      // Check for stored credentials
      final jwtToken = prefs.getString('jwt_token');

      // First, try to verify existing token with backend
      if (jwtToken != null && jwtToken.isNotEmpty) {
        print('🔵 Checking existing token with backend...');
        final (profileSuccess, user, profileMessage) =
            await AuthApi.getUserProfile();

        if (profileSuccess && user != null) {
          if (!user.biometricAllowed) {
            print('❌ Biometric login is disabled for this account');
            return (
              false,
              'Biometric login is disabled for this account',
            );
          }
          print('✅ Valid session found, logged in successfully');
          return (true, null);
        } else {
          print('⚠️ Token expired or invalid: $profileMessage');
          // Token is expired, continue to password login
        }
      }

      // If token is invalid/expired, use saved credentials to re-login
      final savedEmail =
          prefs.getString('biometric_email') ?? prefs.getString('user_email');
      final savedPassword = prefs.getString('biometric_password') ??
          prefs.getString('user_password');

      if (savedEmail != null && savedPassword != null) {
        print('🔵 Re-authenticating with backend using saved credentials...');
        final result = await AuthApi.login(
          email: savedEmail,
          password: savedPassword,
        );
        final loginSuccess = result.$1;
        final loginMessage = result.$2;

        if (loginSuccess) {
          print('✅ Biometric login successful via backend');
          return (true, null);
        } else {
          print('❌ Backend login failed: $loginMessage');
          return (
            false,
            loginMessage ?? 'Login failed. Please log in with password.',
          );
        }
      } else {
        print('❌ No saved credentials found');
        return (
          false,
          'No saved credentials found. Please log in with password first.',
        );
      }
    } catch (e) {
      print('❌ Biometric login error: $e');
      return (false, 'Error: ${e.toString()}');
    }
  }
}
