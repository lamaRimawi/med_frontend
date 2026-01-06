import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../services/profile_state_service.dart';
import '../services/user_service.dart';
import '../widgets/theme_toggle.dart';

/// Instagram-style profile switcher widget
/// Shows a button that opens a modal to switch between profiles
class ProfileSwitcher extends StatefulWidget {
  final Function(UserProfile)? onProfileSwitched;

  const ProfileSwitcher({super.key, this.onProfileSwitched});

  @override
  State<ProfileSwitcher> createState() => _ProfileSwitcherState();
}

class _ProfileSwitcherState extends State<ProfileSwitcher> {
  List<UserProfile> _profiles = [];
  UserProfile? _currentProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await ProfileService.getProfiles();
      final currentProfile = await ProfileStateService().getSelectedProfile();

      // Fetch current user details to ensure "Self" profile is up-to-date
      try {
        final user = await UserService().getUserProfile();

        // Update the "Self" profile in the list with the latest user details
        for (var i = 0; i < profiles.length; i++) {
          if (profiles[i].relationship == 'Self') {
            profiles[i] = UserProfile(
              id: profiles[i].id,
              firstName: user.firstName,
              lastName: user.lastName,
              relationship: profiles[i].relationship,
              dateOfBirth: user.dateOfBirth,
              gender: user.gender ?? profiles[i].gender,
              createdAt: profiles[i].createdAt,
              linkedUserId: profiles[i].linkedUserId,
              isShared: profiles[i].isShared,
              creatorId: profiles[i].creatorId,
            );
            break;
          }
        }
      } catch (e) {
        print('Error fetching user details for switcher: $e');
      }

      // Identify the primary self profile ID for strict labeling
      int? primarySelfId;
      try {
        primarySelfId = profiles.firstWhere((p) => !p.isShared && p.relationship == 'Self').id;
      } catch (_) {
        if (profiles.any((p) => !p.isShared)) {
           primarySelfId = profiles.firstWhere((p) => !p.isShared).id;
        }
      }

      setState(() {
        _profiles = profiles;

        // Find the updated "Self" profile to use as current if it was selected
        final updatedSelfProfile = profiles.firstWhere(
          (p) => p.id == primarySelfId,
          orElse: () => profiles.first,
        );

        // If we have a persisted profile, try to find it in the new list
        if (currentProfile != null) {
          _currentProfile = profiles.firstWhere(
            (p) => p.id == currentProfile.id,
            orElse: () => updatedSelfProfile,
          );
        } else {
          // Fallback to Self if no persisted profile
          _currentProfile = updatedSelfProfile;
        }

        // Additional check: if _currentProfile is still null or not in list (edge case), default to Self
        if (_currentProfile == null) {
           _currentProfile = updatedSelfProfile;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading profiles for switcher: $e');
    }
  }

  void _showProfileSwitcherModal() {
    final isDark =
        ThemeProvider.of(context)?.themeMode == ThemeMode.dark ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF132F4C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Switch Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Profiles list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _profiles.length,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemBuilder: (context, index) {
                  final profile = _profiles[index];
                  final isSelected = _currentProfile?.id == profile.id;

                  return _buildProfileItem(profile, isSelected, isDark);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(UserProfile profile, bool isSelected, bool isDark) {
    return InkWell(
      onTap: () async {
        // Switch to this profile
        await ProfileStateService().setSelectedProfile(profile);
        setState(() {
          _currentProfile = profile;
        });

        if (widget.onProfileSwitched != null) {
          widget.onProfileSwitched!(profile);
        }

        Navigator.pop(context);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    LucideIcons.checkCircle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text('Switched to ${profile.fullName}'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? const Color(0xFF1E4976)
                    : Colors.blue.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : (isDark
                      ? const Color(0xFF1E4976)
                      : Colors.grey.withOpacity(0.2)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text(
                profile.firstName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Name and relationship
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        (profile.relationship == 'Self' && profile.id != _currentProfile?.id && profile.isShared)
                            ? 'Sender'
                            : (profile.relationship == 'Self' && profile.id != _currentProfile?.id)
                                ? 'Family Member'
                                : profile.relationship,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      if (profile.isShared) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Shared',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Selected indicator
            if (isSelected)
              const Icon(LucideIcons.checkCircle, color: Colors.blue, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _profiles.length <= 1) {
      return const SizedBox.shrink();
    }

    final isDark =
        ThemeProvider.of(context)?.themeMode == ThemeMode.dark ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showProfileSwitcherModal,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4), // High contrast for both modes
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentProfile?.fullName ?? 'Switch Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.chevronDown, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
