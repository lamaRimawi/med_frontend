import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _client = ApiClient.instance;

  Future<User> getUserProfile() async {
    try {
      final response = await _client.get(ApiConfig.userProfile, auth: true);

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
        final user = User.fromJson(data);
        // Save to local storage for offline access/caching
        await User.saveToPrefs(user);
        return user;
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  Future<void> updateUserProfile(
    Map<String, String> data, {
    File? imageFile,
  }) async {
    try {
      final response = await _client.putMultipart(
        ApiConfig.userProfile,
        fields: data,
        filePath: imageFile?.path,
        auth: true,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      final response = await _client.put(
        ApiConfig.userProfile,
        body: settings,
        auth: true,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating settings: $e');
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      final response = await _client.delete(
        ApiConfig.deleteAccount,
        auth: true,
        body: {'password': password},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete account: ${response.statusCode}');
      }

      // Clear all local data upon successful deletion
      await User.clearFromPrefs();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all app data to be safe
    } catch (e) {
      throw Exception('Error deleting account: $e');
    }
  }
}
