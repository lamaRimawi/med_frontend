import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';
import 'profile_service.dart';

/// Global service to manage the currently selected profile across the app
/// Similar to Instagram's account switching feature
class ProfileStateService {
  static final ProfileStateService _instance = ProfileStateService._internal();
  factory ProfileStateService() => _instance;
  ProfileStateService._internal();

  static const String _selectedProfileIdKey = 'selected_profile_id';
  static const String _selectedProfileRelationKey = 'selected_profile_relation';

  // Notifier to notify listeners when profile changes
  final ValueNotifier<UserProfile?> _profileNotifier = ValueNotifier<UserProfile?>(null);
  ValueNotifier<UserProfile?> get profileNotifier => _profileNotifier;

  /// Get the currently selected profile ID
  Future<int?> getSelectedProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    final profileId = prefs.getInt(_selectedProfileIdKey);
    return profileId;
  }

  /// Get the currently selected profile relation
  Future<String?> getSelectedProfileRelation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedProfileRelationKey);
  }

  /// Set the currently selected profile
  /// This will be used across all screens to filter data
  /// Notifies all listeners when profile changes
  Future<void> setSelectedProfile(UserProfile? profile) async {
    final prefs = await SharedPreferences.getInstance();
    if (profile == null) {
      await prefs.remove(_selectedProfileIdKey);
      await prefs.remove(_selectedProfileRelationKey);
      _profileNotifier.value = null;
    } else {
      await prefs.setInt(_selectedProfileIdKey, profile.id);
      await prefs.setString(_selectedProfileRelationKey, profile.relationship);
      _profileNotifier.value = profile;
    }
  }

  /// Get the currently selected profile object
  Future<UserProfile?> getSelectedProfile() async {
    final profileId = await getSelectedProfileId();
    if (profileId == null) return null;

    try {
      final profiles = await ProfileService.getProfiles();
      return profiles.firstWhere(
        (p) => p.id == profileId,
        orElse: () => profiles.firstWhere(
          (p) => p.relationship == 'Self',
          orElse: () => profiles.first,
        ),
      );
    } catch (e) {
      // If profile not found, default to Self profile
      try {
        final profiles = await ProfileService.getProfiles();
        return profiles.firstWhere(
          (p) => p.relationship == 'Self',
          orElse: () => profiles.first,
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Initialize with default profile (Self) if none is selected
  Future<void> initializeDefaultProfile() async {
    final currentId = await getSelectedProfileId();
    if (currentId == null) {
      try {
        final profiles = await ProfileService.getProfiles();
        if (profiles.isNotEmpty) {
          final selfProfile = profiles.firstWhere(
            (p) => p.relationship == 'Self',
            orElse: () => profiles.first,
          );
          await setSelectedProfile(selfProfile);
        }
      } catch (e) {
        print('Error initializing default profile: $e');
      }
    } else {
      // Load and notify current profile
      final profile = await getSelectedProfile();
      _profileNotifier.value = profile;
    }
  }

  /// Clear the selected profile (logout scenario)
  Future<void> clearSelectedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedProfileIdKey);
    await prefs.remove(_selectedProfileRelationKey);
  }
}

