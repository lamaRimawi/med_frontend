import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/user_service.dart';
import '../services/auth_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'password_manager_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      });
    }
  }

  void _showDeleteAccountDialog(BuildContext context, bool isDark) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2137) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.alertTriangle,
                    color: Color(0xFFFF4444),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'Delete Account?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Description
                Text(
                  'Please enter your password to confirm account deletion. This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Password Field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0A1929) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF0F2137) : Colors.grey[200]!,
                    ),
                  ),
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      icon: Icon(
                        LucideIcons.lock,
                        size: 20,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                
                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Delete Button
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final password = passwordController.text;
                            if (password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Please enter your password',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFFEF4444),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                  elevation: 8,
                                ),
                              );
                              return;
                            }

                            Navigator.pop(dialogContext);
                            
                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              await UserService().deleteAccount(password);
                              await AuthApi.logout();

                              if (context.mounted) {
                                // Close loading dialog
                                Navigator.pop(context);
                                
                                // Navigate to onboarding/login and clear stack
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/', // Assuming '/' is onboarding or login
                                  (route) => false,
                                );
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'Account deleted successfully',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                    elevation: 8,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                // Close loading dialog
                                Navigator.pop(context);
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(LucideIcons.xCircle, color: Colors.white, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Failed to delete account: $e',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xFFEF4444),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                      elevation: 8,
                                    ),
                                  );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
                        'Settings',
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
          
          // Settings Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSettingItem(
                  context,
                  LucideIcons.bell,
                  'Notification Setting',
                  const Color(0xFF39A4E6),
                  () {
                    Navigator.pushNamed(context, '/notification-settings');
                  },
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildSettingItem(
                  context,
                  LucideIcons.moon,
                  'Dark mode',
                  const Color(0xFF39A4E6),
                  () {
                    Navigator.pushNamed(context, '/dark-mode');
                  },
                  isDark,
                ),
                const SizedBox(height: 12),
                // Biometric Toggle
                _buildSwitchSettingItem(
                  context,
                  LucideIcons.fingerprint,
                  'Biometric Login',
                  const Color(0xFF39A4E6),
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildSettingItem(
                  context,
                  LucideIcons.key,
                  'Password Manager',
                  const Color(0xFF39A4E6),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PasswordManagerScreen(),
                      ),
                    );
                  },
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildSettingItem(
                  context,
                  LucideIcons.userX,
                  'Delete Account',
                  const Color(0xFFFF4444),
                  () {
                    _showDeleteAccountDialog(context, isDark);
                  },
                  isDark,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    Color iconColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2137) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF0F2137) : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
          Switch(
            value: _biometricEnabled,
            onChanged: (value) async {
              setState(() {
                _biometricEnabled = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('biometric_enabled', value);
            },
            activeColor: const Color(0xFF39A4E6),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    Color iconColor,
    VoidCallback onTap,
    bool isDark, {
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F2137) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark 
                ? const Color(0xFF0F2137) 
                : Colors.grey.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDestructive && !isDark
                      ? const Color(0xFF111827)
                      : isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
