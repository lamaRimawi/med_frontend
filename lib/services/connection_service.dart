import '../config/api_config.dart';
import '../models/connection_model.dart';
import 'api_client.dart';

class ConnectionService {
  static final ApiClient _client = ApiClient.instance;

  static Future<Map<String, List<FamilyConnection>>> getConnections() async {
    final response = await _client.get(ApiConfig.connections, auth: true);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = ApiClient.decodeJson<Map<String, dynamic>>(response);
      
      final sent = (data['sent_requests'] as List<dynamic>?)
          ?.map((json) => FamilyConnection.fromJson(json))
          .toList() ?? [];
          
      final received = (data['received_requests'] as List<dynamic>?)
          ?.map((json) => FamilyConnection.fromJson(json))
          .toList() ?? [];

      return {
        'sent': sent,
        'received': received,
      };
    } else {
      throw Exception('Failed to load connections');
    }
  }

  static Future<int> sendRequest({
    required String receiverEmail,
    required String relationship,
    required String accessLevel,
    int? profileId,  // Add optional profile ID
  }) async {
    final Map<String, dynamic> body = {
      'receiver_email': receiverEmail,
      'relationship': relationship,
      'access_level': accessLevel,
    };
    
    // Add profile_id if provided (as integer)
    if (profileId != null) {
      body['profile_id'] = profileId;
    }
    
    final response = await _client.post(
      ApiConfig.connectionRequest,
      body: body,
      auth: true,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = ApiClient.decodeJson<Map<String, dynamic>>(response);
      return data['id'] as int;
    } else {
      throw Exception('Failed to send connection request');
    }
  }

  static Future<void> respondToRequest(int id, String action) async {
    final response = await _client.post(
      '${ApiConfig.connectionRespond}$id/respond',
      body: {'action': action},
      auth: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to respond to request');
    }
  }
}
