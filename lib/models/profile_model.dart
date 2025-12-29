class UserProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String relationship;
  final String dateOfBirth;
  final String gender;
  final String? createdAt;
  final int? linkedUserId;
  final bool isShared; // Whether this profile is shared with the current user
  final int? creatorId; // ID of the user who created/owns this profile

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.relationship,
    required this.dateOfBirth,
    required this.gender,
    this.createdAt,
    this.linkedUserId,
    this.isShared = false,
    this.creatorId,
  });

  String get fullName => '$firstName $lastName';

  /// Check if current user is the owner of this profile
  /// Note: This requires the current user ID to be passed in
  bool isOwner(int? currentUserId) {
    if (currentUserId == null || creatorId == null) {
      // If no creator_id, assume it's owned by current user (Self profile)
      return relationship == 'Self' || !isShared;
    }
    return creatorId == currentUserId;
  }

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
      isShared: json['is_shared'] as bool? ?? false,
      creatorId: json['creator_id'] as int?,
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
