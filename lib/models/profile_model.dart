class UserProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String relationship;
  final String dateOfBirth;
  final String gender;
  final String? createdAt;
  final int? linkedUserId;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.relationship,
    required this.dateOfBirth,
    required this.gender,
    this.createdAt,
    this.linkedUserId,
  });

  String get fullName => '$firstName $lastName';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      dateOfBirth: json['date_of_birth']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      linkedUserId: json['linked_user_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'relationship': relationship,
      'date_of_birth': dateOfBirth,
      'gender': gender,
    };
  }
}
