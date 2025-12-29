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
      '${ApiConfig.profiles}$id',
      body: profile.toJson(),
      auth: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> deleteProfile(int id) async {
    final response = await _client.delete(
      '${ApiConfig.profiles}$id',
      auth: true,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete profile');
    }
  }

  /// Share a profile with another user by email
  /// access_level: 'view', 'upload', or 'manage'
  static Future<void> shareProfile({
    required int profileId,
    required String email,
    required String accessLevel, // 'view', 'upload', 'manage'
  }) async {
    final response = await _client.post(
      '${ApiConfig.profiles}$profileId/share',
      body: {
        'email': email,
        'access_level': accessLevel,
      },
      auth: true,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
      final message = data['message']?.toString() ?? 
                     data['detail']?.toString() ?? 
                     'Failed to share profile';
      throw Exception(message);
    }
  }

  /// Transfer ownership of a profile to another user by email
  static Future<void> transferOwnership({
    required int profileId,
    required String email,
  }) async {
    final response = await _client.post(
      '${ApiConfig.profiles}$profileId/transfer',
      body: {
        'email': email,
      },
      auth: true,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
      final message = data['message']?.toString() ?? 
                     data['detail']?.toString() ?? 
                     'Failed to transfer ownership';
      throw Exception(message);
    }
  }
}
