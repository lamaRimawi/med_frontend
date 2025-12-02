import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String dateOfBirth;

  User({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.dateOfBirth,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      dateOfBirth: json['date_of_birth']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth,
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
  }

  // Load from SharedPreferences
  static Future<User?> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = prefs.getString('user_first_name');
    
    if (firstName == null) return null;
    
    return User(
      firstName: firstName,
      lastName: prefs.getString('user_last_name') ?? '',
      email: prefs.getString('user_email') ?? '',
      phoneNumber: prefs.getString('user_phone') ?? '',
      dateOfBirth: prefs.getString('user_dob') ?? '',
    );
  }

  // Clear from SharedPreferences
  static Future<void> clearFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_first_name');
    await prefs.remove('user_last_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_dob');
  }
}
