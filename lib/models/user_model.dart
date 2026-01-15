import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String dateOfBirth;
  final String? gender;
  final String? medicalHistory;
  final String? allergies;
  final String? profileImageUrl;

  final bool notificationsEnabled;
  final bool twoFactorEnabled;
  final bool biometricEnabled;
  final bool shareMedicalData;
  final bool profileVisible;
  final bool biometricAllowed;

  User({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.dateOfBirth,
    this.gender,
    this.medicalHistory,
    this.allergies,
    this.profileImageUrl,
    this.notificationsEnabled = true,
    this.twoFactorEnabled = false,
    this.biometricEnabled = false,
    this.shareMedicalData = true,
    this.profileVisible = true,
    this.biometricAllowed = true,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      dateOfBirth: json['date_of_birth']?.toString() ?? '',
      gender: json['gender']?.toString(),
      medicalHistory: json['medical_history']?.toString(),
      allergies: json['allergies']?.toString(),
      profileImageUrl: json['profile_image_url']?.toString(),
      notificationsEnabled: json['notifications_enabled'] ?? true,
      twoFactorEnabled: json['two_factor_enabled'] ?? false,
      biometricEnabled: json['biometric_enabled'] ?? false,
      shareMedicalData: json['share_medical_data'] ?? true,
      profileVisible: json['profile_visible'] ?? true,
      biometricAllowed: json.containsKey('biometric_allowed')
          ? json['biometric_allowed'] ?? true
          : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'medical_history': medicalHistory,
      'allergies': allergies,
      'profile_image_url': profileImageUrl,
      'notifications_enabled': notificationsEnabled,
      'two_factor_enabled': twoFactorEnabled,
      'biometric_enabled': biometricEnabled,
      'share_medical_data': shareMedicalData,
      'profile_visible': profileVisible,
      'biometric_allowed': biometricAllowed,
    };
  }

  // Save to SharedPreferences
  static Future<void> saveToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_first_name', user.firstName);
    await prefs.setString('user_last_name', user.lastName);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_phone', user.phoneNumber);
    await prefs.setString('user_dob', user.dateOfBirth);
    if (user.gender != null) {
      await prefs.setString('user_gender', user.gender!);
    }
    if (user.medicalHistory != null) {
      await prefs.setString('user_medical_history', user.medicalHistory!);
    }
    if (user.allergies != null) {
      await prefs.setString('user_allergies', user.allergies!);
    }
    if (user.profileImageUrl != null) {
      await prefs.setString('user_profile_image_url', user.profileImageUrl!);
    }
    await prefs.setBool('user_notifications_enabled', user.notificationsEnabled);
    await prefs.setBool('user_two_factor_enabled', user.twoFactorEnabled);
    await prefs.setBool('user_biometric_enabled', user.biometricEnabled);
    await prefs.setBool('user_share_medical_data', user.shareMedicalData);
    await prefs.setBool('user_profile_visible', user.profileVisible);
    await prefs.setBool('user_biometric_allowed', user.biometricAllowed);
  }

  // Load from SharedPreferences
  static Future<User?> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = prefs.getString('user_first_name');
    final lastName = prefs.getString('user_last_name');
    final email = prefs.getString('user_email');
    final phone = prefs.getString('user_phone');
    final dob = prefs.getString('user_dob');

    if (firstName != null &&
        lastName != null &&
        email != null &&
        phone != null &&
        dob != null) {
      return User(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phone,
        dateOfBirth: dob,
        gender: prefs.getString('user_gender'),
        medicalHistory: prefs.getString('user_medical_history'),
        allergies: prefs.getString('user_allergies'),
        profileImageUrl: prefs.getString('user_profile_image_url'),
        notificationsEnabled: prefs.getBool('user_notifications_enabled') ?? true,
        twoFactorEnabled: prefs.getBool('user_two_factor_enabled') ?? false,
        biometricEnabled: prefs.getBool('user_biometric_enabled') ?? false,
        shareMedicalData: prefs.getBool('user_share_medical_data') ?? true,
        profileVisible: prefs.getBool('user_profile_visible') ?? true,
        biometricAllowed: prefs.getBool('user_biometric_allowed') ?? true,
      );
    }
    return null;
  }

  // Clear from SharedPreferences
  static Future<void> clearFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_first_name');
    await prefs.remove('user_last_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_dob');
    await prefs.remove('user_gender');
    await prefs.remove('user_medical_history');
    await prefs.remove('user_allergies');
    await prefs.remove('user_profile_image_url');
    await prefs.remove('user_notifications_enabled');
    await prefs.remove('user_two_factor_enabled');
    await prefs.remove('user_biometric_enabled');
    await prefs.remove('user_share_medical_data');
    await prefs.remove('user_profile_visible');
    await prefs.remove('user_biometric_allowed');
  }
}

