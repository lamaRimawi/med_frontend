import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../widgets/animated_bubble_background.dart';
import '../widgets/theme_toggle.dart';
import '../models/user_model.dart';
import '../services/auth_api.dart';
import '../services/user_service.dart';
import '../services/reports_service.dart';
import '../models/report_model.dart';
import 'timeline_screen.dart';
import 'reports_screen.dart';
import 'dark_mode_screen.dart';
import 'settings_screen.dart';
import 'password_manager_screen.dart';
import '../config/api_config.dart';

class ProfileScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  String _currentScreen = 'main';
  bool _isLoading = false;
  bool _showCountryPicker = false;
  bool _showCalendarDropdown = false;
  String _calendarView = 'day'; // 'day', 'month', 'year'
  bool _notificationsEnabled = true;
  bool _twoFactorEnabled = false;
  bool _biometricEnabled = false;
  bool _shareMedicalData = true;
  bool _profileVisible = true;
  bool _privacyLoading = false;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Theme getter using ThemeProvider
  bool get _isDarkMode =>
      ThemeProvider.of(context)?.themeMode == ThemeMode.dark ?? false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      // Save image path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', pickedFile.path);
    }
  }

  // Profile Data
  Map<String, dynamic> _profileData = {
    'name': '',
    'email': '',
    'phone': '',
    'phonePrefix': '+1',
    'dateOfBirth': '',
    'gender': '',
    'medicalHistory': '',
    'allergies': '',
    'avatar': '',
  };

  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
    _loadRecentReports();
  }

  Future<void> _loadRecentReports() async {
    try {
      final reports = await ReportsService().getReports();
      if (mounted) {
        setState(() {
          _medicalReports = reports.take(3).map((report) {
            // Determine status based on fields (simple logic)
            String status = 'Analyzed';
            Color statusColor = Colors.green;
            
            // Allow basic types or default
            String type = report.reportType ?? 'Medical Report';
            
            return {
              'id': report.reportId,
              'name': type,
              'date': report.reportDate,
              'type': type,
              'status': status,
              'color': const Color(0xFF39A4E6), // Default blue
            };
          }).toList().cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print('Failed to load recent reports for profile: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _twoFactorEnabled = prefs.getBool('two_factor_enabled') ?? false;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _shareMedicalData = prefs.getBool('share_medical_data') ?? true;
      _profileVisible = prefs.getBool('profile_visible') ?? true;
    });
  }

  Future<void> _loadUserData() async {
    try {
      // Try to fetch from backend first
      final user = await UserService().getUserProfile();
      if (mounted) {
        _updateLocalUserState(user);
      }
    } catch (e) {
      // Fallback to local storage if offline or error
      final user = await User.loadFromPrefs();
      if (user != null && mounted) {
        _updateLocalUserState(user);
      }
    }

    // Load saved profile image
    final prefs = await SharedPreferences.getInstance();
    final savedImagePath = prefs.getString('profile_image_path');
    if (savedImagePath != null && mounted) {
      final file = File(savedImagePath);
      if (await file.exists()) {
        setState(() {
          _imageFile = file;
        });
      }
    }
  }

  void _updateLocalUserState(User user) {
    setState(() {
      _profileData['name'] = user.fullName;
      _profileData['email'] = user.email;

      // Improved Phone Parsing
      String fullPhone = user.phoneNumber;
      String phoneBody = fullPhone;
      String prefix = '+962'; // Default fallback

      // Better prefix matching based on available country codes
      bool prefixFound = false;
      // Sort prefixes by length descending to match longest first (+970 before +9)
      final sortedCodes = List<Map<String, String>>.from(_countryCodes)
        ..sort((a, b) => b['code']!.length.compareTo(a['code']!.length));

      for (final country in sortedCodes) {
        final code = country['code']!;
        if (fullPhone.startsWith(code)) {
          prefix = code;
          phoneBody = fullPhone.substring(code.length).trim();
          prefixFound = true;
          break;
        }
      }

      if (!prefixFound) {
        // Regex to find country code (e.g. +962) and the rest
        // Matches + followed by 1-4 digits, then optionally space, then the rest
        final match = RegExp(r'^(\+\d{1,4})[\s-]*(.*)$').firstMatch(fullPhone);
        
        if (match != null) {
          prefix = match.group(1) ?? '+962';
          phoneBody = match.group(2) ?? '';
        } else {
          // Fallback cleaning if no + found
          phoneBody = fullPhone.replaceFirst(RegExp(r'^\+'), '').trim();
        }
      }

      _profileData['phonePrefix'] = prefix;
      _profileData['phone'] = phoneBody.replaceAll(' ', '').trim();

      _profileData['dateOfBirth'] = user.dateOfBirth;
      _profileData['gender'] = user.gender ?? '';
      _profileData['medicalHistory'] = user.medicalHistory ?? '';
      _profileData['allergies'] = user.allergies ?? '';
      // Use backend profile image if available, else fallback to DiceBear
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      if (user.profileImageUrl!.startsWith('http')) {
        _profileData['avatar'] = user.profileImageUrl;
      } else {
        // Construct full URL connecting to backend
        // Use ApiConfig.baseUrl but remove /api suffix if present
        final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
        _profileData['avatar'] = '$baseUrl${user.profileImageUrl}';
      }
    } else {
      _profileData['avatar'] =
          'https://api.dicebear.com/7.x/avataaars/svg?seed=${user.firstName}';
    }
  });
}

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month - 1;
  int? _selectedDay;

  Map<String, dynamic> _selectedLocation = {
    'city': 'New York',
    'country': 'United States',
    'flag': '🇺🇸',
    'lat': 40.7128,
    'lng': -74.0060,
  };

  String _locationSearch = '';

  // Data Lists
  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'country': 'United States', 'flag': '🇺🇸'},
    {'code': '+1', 'country': 'Canada', 'flag': '🇨🇦'},
    {'code': '+44', 'country': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': '+970', 'country': 'Palestine', 'flag': '🇵🇸'},
    {'code': '+972', 'country': 'Israel', 'flag': '🇮🇱'},
    {'code': '+962', 'country': 'Jordan', 'flag': '🇯🇴'},
    {'code': '+966', 'country': 'Saudi Arabia', 'flag': '🇸🇦'},
    {'code': '+971', 'country': 'UAE', 'flag': '🇦🇪'},
    {'code': '+20', 'country': 'Egypt', 'flag': '🇪🇬'},
    {'code': '+961', 'country': 'Lebanon', 'flag': '🇱🇧'},
    {'code': '+963', 'country': 'Syria', 'flag': '🇸🇾'},
    {'code': '+964', 'country': 'Iraq', 'flag': '🇮🇶'},
    {'code': '+965', 'country': 'Kuwait', 'flag': '🇰🇼'},
    {'code': '+974', 'country': 'Qatar', 'flag': '🇶🇦'},
    {'code': '+973', 'country': 'Bahrain', 'flag': '🇧🇭'},
    {'code': '+968', 'country': 'Oman', 'flag': '🇴🇲'},
    {'code': '+967', 'country': 'Yemen', 'flag': '🇾🇪'},
    {'code': '+91', 'country': 'India', 'flag': '🇮🇳'},
    {'code': '+86', 'country': 'China', 'flag': '🇨🇳'},
    {'code': '+81', 'country': 'Japan', 'flag': '🇯🇵'},
    {'code': '+49', 'country': 'Germany', 'flag': '🇩🇪'},
    {'code': '+33', 'country': 'France', 'flag': '🇫🇷'},
    {'code': '+39', 'country': 'Italy', 'flag': '🇮🇹'},
    {'code': '+34', 'country': 'Spain', 'flag': '🇪🇸'},
    {'code': '+7', 'country': 'Russia', 'flag': '🇷🇺'},
    {'code': '+61', 'country': 'Australia', 'flag': '🇦🇺'},
    {'code': '+55', 'country': 'Brazil', 'flag': '🇧🇷'},
    {'code': '+52', 'country': 'Mexico', 'flag': '🇲🇽'},
    {'code': '+90', 'country': 'Turkey', 'flag': '🇹🇷'},
    {'code': '+82', 'country': 'South Korea', 'flag': '🇰🇷'},
  ];

  final List<Map<String, dynamic>> _locations = [
    {
      'city': 'New York',
      'country': 'United States',
      'flag': '🇺🇸',
      'lat': 40.7128,
      'lng': -74.0060,
    },
    {
      'city': 'London',
      'country': 'United Kingdom',
      'flag': '🇬🇧',
      'lat': 51.5074,
      'lng': -0.1278,
    },
    {
      'city': 'Tokyo',
      'country': 'Japan',
      'flag': '🇯🇵',
      'lat': 35.6762,
      'lng': 139.6503,
    },
    {
      'city': 'Paris',
      'country': 'France',
      'flag': '🇫🇷',
      'lat': 48.8566,
      'lng': 2.3522,
    },
    {
      'city': 'Sydney',
      'country': 'Australia',
      'flag': '🇦🇺',
      'lat': -33.8688,
      'lng': 151.2093,
    },
    {
      'city': 'Dubai',
      'country': 'United Arab Emirates',
      'flag': '🇦🇪',
      'lat': 25.2048,
      'lng': 55.2708,
    },
  ];

  List<Map<String, dynamic>> _medicalReports = [];

  final List<Map<String, dynamic>> _sharedDoctors = [
    {
      'id': 1,
      'name': 'Dr. John Smith',
      'specialty': 'Cardiologist',
      'avatar': '👨‍⚕️',
      'access': 'Full Access',
      'since': 'Jan 2024',
    },
    {
      'id': 2,
      'name': 'Dr. Sarah Johnson',
      'specialty': 'General Physician',
      'avatar': '👩‍⚕️',
      'access': 'Limited',
      'since': 'Mar 2024',
    },
    {
      'id': 3,
      'name': 'Dr. Michael Chen',
      'specialty': 'Neurologist',
      'avatar': '👨‍⚕️',
      'access': 'Full Access',
      'since': 'Feb 2024',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Main Screen
          _buildMainProfileScreen(),

          // Sub Screens (Slide in from right)
          AnimatedSlide(
            offset: _currentScreen == 'main' ? const Offset(1, 0) : Offset.zero,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            child: _buildSubScreen(),
          ),

          // Country Picker Bottom Sheet
          if (_showCountryPicker) _buildCountryBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildSubScreen() {
    switch (_currentScreen) {
      case 'personal-info':
        return _buildPersonalInfoScreen();
      case 'location':
        return _buildLocationScreen();
      case 'reports':
        return ReportsScreen(
          onBack: () => setState(() => _currentScreen = 'main'),
        );
      case 'doctors':
        return _buildDoctorsScreen();
      case 'timeline':
        return TimelineScreen(
          onBack: () => setState(() => _currentScreen = 'main'),
          isDarkMode: _isDarkMode,
        );
      case 'settings':
        return _buildSettingsPrivacyScreen();
      case 'support':
        return _buildHelpSupportScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Main Profile Screen ---
  Widget _buildMainProfileScreen() {
    final isDark = _isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Blue Header with User Info
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
              child: Column(
                children: [
                  // Header with title aligned left
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'My Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Profile Picture and User Info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Row(
                      children: [
                        // Profile Picture
                        Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.transparent,
                                  width: 0,
                                ),
                                image: DecorationImage(
                                  image: _imageFile != null
                                      ? FileImage(_imageFile!) as ImageProvider
                                      : const NetworkImage(
                                          'https://api.dicebear.com/7.x/avataaars/png?seed=Maria',
                                        ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF39A4E6),
                                  ),
                                  child: const Icon(
                                    LucideIcons.camera,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profileData['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _profileData['phone'].isNotEmpty
                                    ? '${_profileData['phonePrefix'] ?? '+962'} ${_profileData['phone']}'
                                    : '+962 79 123 4567',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _profileData['email'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              children: [
                _buildMenuItem(
                  LucideIcons.user,
                  'Edit Profile',
                  () => setState(() => _currentScreen = 'personal-info'),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  LucideIcons.settings,
                  'Settings & Privacy',
                  () => setState(() => _currentScreen = 'settings'),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  LucideIcons.helpCircle,
                  'Help & Support',
                  () => setState(() => _currentScreen = 'support'),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(LucideIcons.logOut, 'Logout', () async {
                  // Show bottom sheet confirmation
                  final shouldLogout = await showModalBottomSheet<bool>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Are you sure you want to log out?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 36),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      border: Border.all(
                                        color: const Color(0xFF39A4E6),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF39A4E6),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Text(
                                      'Yes, Logout',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );

                  // Only logout if user confirmed
                  if (shouldLogout == true) {
                    await User.clearFromPrefs();
                    await AuthApi.logout();
                    widget.onLogout();
                  }
                }, isLogout: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    final isDark = _isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF39A4E6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF39A4E6), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isLogout
                      ? const Color(0xFF39A4E6)
                      : (isDark ? Colors.white : const Color(0xFF111827)),
                ),
              ),
            ),
            if (!isLogout)
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

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    final isDark = _isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF39A4E6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF39A4E6), size: 20),
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

  Widget _buildSwitchSettingItem(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final isDark = _isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF39A4E6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF39A4E6), size: 20),
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
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF39A4E6),
          ),
        ],
      ),
    );
  }

  // --- Personal Info Screen ---
  Widget _buildPersonalInfoScreen() {
    final isDark = _isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB);

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildScreenHeader('Personal Information'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('FULL NAME'),
                        _buildTextField(
                          LucideIcons.user,
                          _profileData['name'],
                          (val) => setState(() => _profileData['name'] = val),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('PHONE NUMBER'),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showCountryPicker = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF111827)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.transparent),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.globe,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _profileData['phonePrefix'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                LucideIcons.phone,
                                _profileData['phone'],
                                (val) => setState(() {
                                  _profileData['phone'] = val;
                                  if (_phoneError != null) _phoneError = null;
                                }),
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(9),
                                ],
                                errorText: _phoneError,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('DATE OF BIRTH'),
                        GestureDetector(
                          onTap: () => setState(
                            () =>
                                _showCalendarDropdown = !_showCalendarDropdown,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF111827)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.calendar,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _profileData['dateOfBirth'].isEmpty
                                        ? 'Select your date of birth'
                                        : _profileData['dateOfBirth'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                Transform.rotate(
                                  angle: _showCalendarDropdown ? math.pi : 0,
                                  child: Icon(
                                    LucideIcons.chevronDown,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Inline Calendar Dropdown
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _showCalendarDropdown
                              ? _buildCalendarDropdown()
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 20),
                        _buildLabel('GENDER'),
                        _buildGenderSelector(),
                        const SizedBox(height: 20),

                        _buildLabel('MEDICAL HISTORY'),
                        _buildTextField(
                          LucideIcons.stethoscope,
                          _profileData['medicalHistory']?.toString() ?? '',
                          (val) => setState(() => _profileData['medicalHistory'] = val),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('ALLERGIES'),
                        _buildTextField(
                          LucideIcons.alertTriangle,
                          _profileData['allergies']?.toString() ?? '',
                          (val) => setState(() => _profileData['allergies'] = val),
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () async {
                            // Validation
                            if (_profileData['name'].toString().trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter your full name'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            // Name Validation (Letters and spaces only)
                            final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
                            if (!nameRegex.hasMatch(_profileData['name'].toString().trim())) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Name must contain only letters'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Phone validation
                            final phone = _profileData['phone'].toString().trim();
                            if (phone.isNotEmpty && phone.length != 9) {
                              setState(
                                () => _phoneError = 'Phone number must be 9 digits',
                              );
                              return;
                            }
                            setState(() => _phoneError = null);
                            
                            if (_profileData['dateOfBirth'].toString().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select your date of birth'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            try {
                              setState(() => _isLoading = true);
                              
                              // Split name into first and last
                              final nameParts = _profileData['name'].toString().trim().split(' ');
                              final firstName = nameParts.isNotEmpty ? nameParts.first : '';
                              final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
                                
                              // Format Date of Birth to YYYY-MM-DD
                              String formattedDob = '';
                              try {
                                  final dobStr = _profileData['dateOfBirth'].toString();
                                  final parts = dobStr.split(' ');
                                  if (parts.length == 3) {
                                      final monthStr = parts[1];
                                      final months = [
                                        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                      ];
                                      if (months.contains(monthStr)) {
                                          final day = int.parse(parts[0]);
                                          final year = int.parse(parts[2]);
                                          final month = months.indexOf(monthStr) + 1;
                                          formattedDob = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                                      } else {
                                          formattedDob = dobStr;
                                      }
                                  } else {
                                      formattedDob = dobStr; // Fallback
                                  }
                              } catch (e) {
                                  print('Error formatting date: $e');
                                  formattedDob = _profileData['dateOfBirth'].toString();
                              }

                              final Map<String, String> updateData = {
                                'first_name': firstName,
                                'last_name': lastName,
                                'phone_number': '${_profileData['phonePrefix']}${_profileData['phone']}',
                                'date_of_birth': formattedDob,
                                'gender': _profileData['gender']?.toString() ?? '',
                                'medical_history': _profileData['medicalHistory']?.toString() ?? '',
                                'allergies': _profileData['allergies']?.toString() ?? '',
                              };

                              await UserService().updateUserProfile(updateData, imageFile: _imageFile);

                              // Refresh data
                              await _loadUserData();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile updated successfully'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                                setState(() {
                                  _showCalendarDropdown = false;
                                  _currentScreen = 'main';
                                });
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update profile: $e'),
                                    backgroundColor: const Color(0xFFFF4444),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF39A4E6), Color(0xFF5BB5ED)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF39A4E6,
                                  ).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isLoading 
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField(
    IconData icon,
    String value,
    Function(String) onChanged, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
  }) {
    final isDark = _isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: errorText != null
            ? Border.all(color: Colors.red, width: 1)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: TextEditingController(text: value)
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: value.length),
          ),
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF111827),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          icon: Icon(
            icon,
            color: errorText != null ? Colors.red : Colors.grey[400],
            size: 20,
          ),
          border: InputBorder.none,
          hintText: 'Enter value',
          hintStyle: TextStyle(color: Colors.grey[400]),
          errorText: errorText,
          errorStyle: const TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // --- Calendar Dropdown ---
  Widget _buildCalendarDropdown() {
    final isDark = _isDarkMode;
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : Colors.grey[100]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month/Year Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  LucideIcons.chevronLeft,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    if (_calendarView == 'year') {
                      _selectedYear -= 12;
                    } else if (_calendarView == 'month') {
                      _selectedYear--;
                    } else {
                      if (_selectedMonth == 0) {
                        _selectedMonth = 11;
                        _selectedYear--;
                      } else {
                        _selectedMonth--;
                      }
                    }
                  });
                },
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_calendarView == 'day')
                      _calendarView = 'year';
                    else if (_calendarView == 'year')
                      _calendarView = 'month';
                    else
                      _calendarView = 'day';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _calendarView == 'year'
                            ? '$_selectedYear - ${_selectedYear + 11}'
                            : _calendarView == 'month'
                            ? '$_selectedYear'
                            : '${months[_selectedMonth]} $_selectedYear',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    if (_calendarView == 'year') {
                      _selectedYear += 12;
                    } else if (_calendarView == 'month') {
                      _selectedYear++;
                    } else {
                      if (_selectedMonth == 11) {
                        _selectedMonth = 0;
                        _selectedYear++;
                      } else {
                        _selectedMonth++;
                      }
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_calendarView == 'day') ...[
            // Week Days
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDays
                  .map(
                    (day) => Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),

            // Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount:
                  DateTime(_selectedYear, _selectedMonth + 1, 0).day +
                  DateTime(_selectedYear, _selectedMonth + 1, 1).weekday % 7,
              itemBuilder: (context, index) {
                final firstDayOffset =
                    DateTime(_selectedYear, _selectedMonth + 1, 1).weekday % 7;
                if (index < firstDayOffset) return const SizedBox.shrink();

                final day = index - firstDayOffset + 1;
                final isSelected = _selectedDay == day;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                      _profileData['dateOfBirth'] =
                          '$day ${months[_selectedMonth].substring(0, 3)} $_selectedYear';
                      _showCalendarDropdown = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                            )
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ] else if (_calendarView == 'month') ...[
            // Months Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final isSelected = _selectedMonth == index;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedMonth = index;
                    _calendarView = 'day';
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF39A4E6)
                          : (isDark
                                ? const Color(0xFF1F2937)
                                : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        months[index],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ] else if (_calendarView == 'year') ...[
            // Years Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final year = _selectedYear + index;
                final isSelected =
                    year ==
                    DateTime.now().year; // Highlight current year or selected
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedYear = year;
                    _calendarView = 'month';
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF39A4E6).withOpacity(0.2)
                          : (isDark
                                ? const Color(0xFF1F2937)
                                : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: const Color(0xFF39A4E6))
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$year',
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF39A4E6)
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // --- Location Screen ---
  Widget _buildLocationScreen() {
    final isDark = _isDarkMode;
    final bgColor = isDark ? const Color(0xFF030712) : const Color(0xFFF9FAFB);

    final filteredLocations = _locations
        .where(
          (loc) =>
              loc['city'].toLowerCase().contains(
                _locationSearch.toLowerCase(),
              ) ||
              loc['country'].toLowerCase().contains(
                _locationSearch.toLowerCase(),
              ),
        )
        .toList();

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildScreenHeader('Location Settings'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Search
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111827) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (val) =>
                            setState(() => _locationSearch = val),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          icon: Icon(
                            LucideIcons.search,
                            color: Colors.grey[400],
                          ),
                          border: InputBorder.none,
                          hintText: 'Search destinations',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Current Location Card
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1F2937),
                                  const Color(0xFF111827),
                                ]
                              : [Colors.grey[100]!, Colors.grey[200]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF374151)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.mapPin,
                                  size: 48,
                                  color: const Color(0xFF39A4E6),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedLocation['city'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  '${_selectedLocation['lat']}, ${_selectedLocation['lng']}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Locations List
                    ...filteredLocations.map((loc) {
                      final isSelected =
                          _selectedLocation['city'] == loc['city'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedLocation = loc),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF39A4E6).withOpacity(0.1)
                                : (isDark
                                      ? const Color(0xFF111827)
                                      : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF39A4E6)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              if (!isSelected)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF39A4E6,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    loc['flag'],
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc['city'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                      ),
                                    ),
                                    Text(
                                      loc['country'],
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  LucideIcons.checkCircle2,
                                  color: Color(0xFF39A4E6),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reports Screen ---
  Widget _buildReportsScreen() {
    final isDark = _isDarkMode;
    final bgColor = isDark ? const Color(0xFF030712) : const Color(0xFFF9FAFB);

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildScreenHeader('My Medical Reports'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF39A4E6), Color(0xFF5BB5ED)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF39A4E6).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.plus, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Upload New Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    ..._medicalReports.map(
                      (report) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF111827)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: (report['color'] as Color)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    LucideIcons.fileText,
                                    color: report['color'],
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        report['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${report['date']} • ${report['type']}',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    report['status'],
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    LucideIcons.eye,
                                    'View',
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildActionButton(
                                    LucideIcons.share2,
                                    'Share',
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  LucideIcons.download,
                                  '',
                                  isDark,
                                  isIconOnly: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    bool isDark, {
    bool isIconOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
          if (!isIconOnly) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Doctors Screen ---
  Widget _buildDoctorsScreen() {
    final isDark = _isDarkMode;
    final bgColor = isDark ? const Color(0xFF030712) : const Color(0xFFF9FAFB);

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildScreenHeader('Shared with Doctors'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: _sharedDoctors
                      .map(
                        (doctor) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF111827)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(
                                            0xFF39A4E6,
                                          ).withOpacity(0.2),
                                          const Color(
                                            0xFF5BB5ED,
                                          ).withOpacity(0.2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        doctor['avatar'],
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doctor['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                          ),
                                        ),
                                        Text(
                                          doctor['specialty'],
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Since ${doctor['since']}',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (doctor['access'] == 'Full Access'
                                                  ? Colors.green
                                                  : Colors.orange)
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      doctor['access'],
                                      style: TextStyle(
                                        color: doctor['access'] == 'Full Access'
                                            ? Colors.green
                                            : Colors.orange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButton(
                                      LucideIcons.messageCircle,
                                      'Message',
                                      isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(
                                                0xFF7F1D1D,
                                              ).withOpacity(0.2)
                                            : const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            LucideIcons.x,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Revoke',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // --- Settings & Privacy Screen ---
  Widget _buildSettingsPrivacyScreen() {
    final isDark = _isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          _buildScreenHeader('Settings & Privacy'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              children: [
                _buildSectionHeader('PREFERENCES'),
                _buildSecurityItem(
                  LucideIcons.bell,
                  'Notifications',
                  'Manage alerts and reminders',
                  onTap: () => Navigator.pushNamed(context, '/notification-settings'),
                ),
                const SizedBox(height: 16),
                _buildSecurityItem(
                  LucideIcons.moon,
                  'Dark Mode',
                  'Customize your app appearance',
                  onTap: () => Navigator.pushNamed(context, '/dark-mode-settings'),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('SECURITY'),
                _buildSecurityItem(
                  LucideIcons.shield,
                  'Password Manager',
                  'Manage your saved passwords',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PasswordManagerScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPrivacySwitchItem(
                  LucideIcons.fingerprint,
                  'Biometric Login',
                  'Use fingerprint or face ID to login',
                  _biometricEnabled,
                  (val) async {
                    setState(() => _biometricEnabled = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('biometric_enabled', val);
                  },
                ),
                const SizedBox(height: 16),
                _buildPrivacySwitchItem(
                  LucideIcons.shieldCheck,
                  'Two-Factor Authentication',
                  'Add an extra layer of security',
                  _twoFactorEnabled,
                  (val) async {
                    setState(() => _twoFactorEnabled = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('two_factor_enabled', val);
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('PRIVACY'),
                _buildPrivacySwitchItem(
                  LucideIcons.share2,
                  'Share Medical Data',
                  'Allow doctors to view your history',
                  _shareMedicalData,
                  (val) async {
                    setState(() => _shareMedicalData = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('share_medical_data', val);
                  },
                ),
                const SizedBox(height: 16),
                _buildPrivacySwitchItem(
                  LucideIcons.eye,
                  'Profile Visibility',
                  'Manage who can see your profile',
                  _profileVisible,
                  (val) async {
                    setState(() => _profileVisible = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('profile_visible', val);
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('ACCOUNT'),
                _buildSecurityItem(
                  LucideIcons.userX,
                  'Delete Account',
                  'Permanently delete your data',
                  isDestructive: true,
                  onTap: () => _showDeleteAccountDialog(context, isDark),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Help & Support Screen ---
  Widget _buildHelpSupportScreen() {
    final isDark = _isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          _buildScreenHeader('Help & Support'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              children: [
                _buildSectionHeader('COMMON QUESTIONS'),
                _buildFAQTile(
                  'How do I upload a medical report?',
                  'Go to the Home screen and click on the "Camera" icon in the center of the navigation bar. You can then take a photo or upload a PDF.',
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildFAQTile(
                  'Is my data secure?',
                  'Yes, we use industry-standard encryption to protect your data. You can manage your privacy settings in the Settings & Privacy section.',
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildFAQTile(
                  'Can I share my reports?',
                  'Absolutely! You can share any analyzed report as a PDF or image using the "Share" button within the report details.',
                  isDark,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          iconColor: const Color(0xFF39A4E6),
          collapsedIconColor: Colors.grey[400],
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    final isDark = _isDarkMode;
    final genders = ['Male', 'Female', 'Other'];
    return Row(
      children: genders.map((gender) {
        final isSelected = _profileData['gender'] == gender;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _profileData['gender'] = gender),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF39A4E6)
                    : (isDark ? const Color(0xFF111827) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF39A4E6)
                      : (isDark ? const Color(0xFF1F2937) : Colors.grey[200]!),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF39A4E6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                gender,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSecurityItem(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = _isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDestructive ? Colors.red : const Color(0xFF39A4E6))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFF39A4E6),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySwitchItem(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final isDark = _isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF39A4E6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF39A4E6),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF39A4E6),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final isDark = _isDarkMode;
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Change Password',
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(LucideIcons.lock, 'Old Password', oldController, true, isDark),
              const SizedBox(height: 16),
              _buildDialogField(LucideIcons.shield, 'New Password', newController, true, isDark),
              const SizedBox(height: 16),
              _buildDialogField(LucideIcons.checkCircle, 'Confirm Password', confirmController, true, isDark),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newController.text != confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                setState(() => _privacyLoading = true);
                
                final (success, message) = await AuthApi.changePassword(
                  email: _profileData['email'],
                  oldPassword: oldController.text,
                  newPassword: newController.text,
                );
                
                setState(() => _privacyLoading = false);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Password changed successfully' : (message ?? 'Failed to change password')),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A4E6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Change', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(IconData icon, String hint, TextEditingController controller, bool obscure, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          icon: Icon(icon, size: 20, color: Colors.grey[500]),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, bool isDark) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action is permanent and cannot be undone. Please enter your password to confirm.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildDialogField(LucideIcons.lock, 'Password', passwordController, true, isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;
              if (password.isEmpty) return;

              Navigator.pop(dialogContext);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                await UserService().deleteAccount(password);
                await AuthApi.logout();

                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account deleted successfully'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderScreen(String title, IconData icon, String message) {
    final isDark = _isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB);

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildScreenHeader(title),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 64, color: const Color(0xFF39A4E6)),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenHeader(String title) {
    final isDark = _isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => setState(() => _currentScreen = 'main'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF374151) : Colors.grey[200]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.chevronLeft,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  // --- Country Bottom Sheet ---
  Widget _buildCountryBottomSheet() {
    final isDark = _isDarkMode;
    return Stack(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showCountryPicker = false),
          child: Container(color: Colors.black.withOpacity(0.7)),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child:
              Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Select Country Code',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _countryCodes.length,
                        itemBuilder: (context, index) {
                          final item = _countryCodes[index];
                          final isSelected =
                              _profileData['phonePrefix'] == item['code'];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _profileData['phonePrefix'] = item['code'];
                                _showCountryPicker = false;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF39A4E6).withOpacity(0.1)
                                    : (isDark
                                          ? const Color(0xFF1F2937)
                                          : Colors.grey[50]),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF39A4E6)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    item['flag']!,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['country']!,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                          ),
                                        ),
                                        Text(
                                          item['code']!,
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      LucideIcons.checkCircle2,
                                      color: Color(0xFF39A4E6),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().moveY(
                begin: 300,
                end: 0,
                duration: 300.ms,
                curve: Curves.easeOutBack,
              ),
        ),
      ],
    );
  }
}
