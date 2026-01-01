import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _generalNotification = true;
  bool _sound = true;
  bool _vibrate = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = await User.loadFromPrefs();
    if (user != null) {
      setState(() {
        _generalNotification = user.notificationsEnabled;
      });
    }
  }

  Future<void> _updateNotificationSetting(bool value) async {
    setState(() {
      _generalNotification = value;
      _isLoading = true;
    });
    try {
      await UserService().updateUserSettings({
        'notifications_enabled': value,
      });
      // Refresh local data
      final user = await UserService().getUserProfile();
      await User.saveToPrefs(user);
    } catch (e) {
      debugPrint('Error updating notification setting: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1929) : const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Blue Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Notification Setting',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39A4E6)),
              minHeight: 2,
            ),

          // Settings List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSettingTile(
                  title: 'General Notification',
                  value: _generalNotification,
                  onChanged: (value) => _updateNotificationSetting(value),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  title: 'Sound',
                  value: _sound,
                  onChanged: (value) => setState(() => _sound = value),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  title: 'Vibrate',
                  value: _vibrate,
                  onChanged: (value) => setState(() => _vibrate = value),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2137) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        activeColor: const Color(0xFF39A4E6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
