class FamilyConnection {
  final int id;
  final String? fromEmail;
  final String? toEmail;
  final String status; // pending, accepted, rejected
  final String relationship;
  final String? accessLevel; // view, manage
  final String? name;

  FamilyConnection({
    required this.id,
    this.fromEmail,
    this.toEmail,
    required this.status,
    required this.relationship,
    this.accessLevel,
    this.name,
  });

  factory FamilyConnection.fromJson(Map<String, dynamic> json) {
    return FamilyConnection(
      id: json['id'] as int,
      fromEmail: json['from']?.toString(),
      toEmail: json['to']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      relationship: json['relationship']?.toString() ?? '',
      accessLevel: json['access_level']?.toString(),
      name: json['name']?.toString(),
    );
  }
}
