class FamilyConnection {
  final int id;
  final String? fromEmail;
  final String? toEmail;
  final String status; // pending, accepted, rejected
  final String relationship;
  final String? accessLevel; // view, manage
  final int? profileId; // optional profile id associated with this connection

  FamilyConnection({
    required this.id,
    this.fromEmail,
    this.toEmail,
    required this.status,
    required this.relationship,
    this.accessLevel,
    this.profileId,
  });

  factory FamilyConnection.fromJson(Map<String, dynamic> json) {
    return FamilyConnection(
      id: json['id'] as int,
      fromEmail: json['from']?.toString(),
      toEmail: json['to']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      relationship: json['relationship']?.toString() ?? '',
      accessLevel: json['access_level']?.toString(),
      profileId: json['profile_id'] != null ? (json['profile_id'] as num).toInt() : null,
    );
  }
}
