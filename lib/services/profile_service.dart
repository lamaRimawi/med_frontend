import '../config/api_config.dart';
import '../models/profile_model.dart';
import 'api_client.dart';

class ProfileService {
  static final ApiClient _client = ApiClient.instance;

  static Future<List<UserProfile>> getProfiles() async {
    final response = await _client.get(ApiConfig.profiles, auth: true);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = ApiClient.decodeJson<List<dynamic>>(response);
      return data.map((json) => UserProfile.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load profiles');
    }
  }

  static Future<int> createProfile(UserProfile profile) async {
    final response = await _client.post(
      ApiConfig.profiles,
      body: profile.toJson(),
      auth: true,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
      return data['id'] as int;
    } else {
      throw Exception('Failed to create profile: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> updateProfile(int id, UserProfile profile) async {
    final response = await _client.put(
      '${ApiConfig.profiles}$id/',
      body: profile.toJson(),
      auth: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> deleteProfile(int id) async {
    final response = await _client.delete(
      '${ApiConfig.profiles}$id/',
      auth: true,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete profile');
    }
  }
}
