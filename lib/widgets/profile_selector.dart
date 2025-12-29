import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileSelector extends StatefulWidget {
  final Function(UserProfile?) onProfileSelected;
  final UserProfile? initialProfile;

  const ProfileSelector({
    super.key,
    required this.onProfileSelected,
    this.initialProfile,
  });

  @override
  State<ProfileSelector> createState() => _ProfileSelectorState();
}

class _ProfileSelectorState extends State<ProfileSelector> {
  List<UserProfile> _profiles = [];
  UserProfile? _selectedProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await ProfileService.getProfiles();
      setState(() {
        _profiles = profiles;
        _isLoading = false;
        // Default to "Self" profile if found
        if (widget.initialProfile != null) {
          _selectedProfile = _profiles.firstWhere(
            (p) => p.id == widget.initialProfile!.id,
            orElse: () => _profiles.first,
          );
        } else {
          if (_profiles.isEmpty) {
            _selectedProfile = null;
          } else {
            _selectedProfile = _profiles.firstWhere(
              (p) => p.relationship == 'Self',
              orElse: () => _profiles.first,
            );
          }
        }
      });
      widget.onProfileSelected(_selectedProfile);
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading profiles: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_profiles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UserProfile>(
          value: _selectedProfile,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
          items: _profiles.map((profile) {
            return DropdownMenuItem(
              value: profile,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Text(
                      profile.firstName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${profile.firstName} (${profile.relationship})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (UserProfile? value) {
            setState(() => _selectedProfile = value);
            widget.onProfileSelected(value);
          },
        ),
      ),
    );
  }
}
