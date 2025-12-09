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
  bool _showCountryPicker = false;
  bool _showCalendarDropdown = false;
  String _calendarView = 'day'; // 'day', 'month', 'year'
  bool _notificationsEnabled = true;
  bool _twoFactorEnabled = false;

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
      _profileData['phone'] = user.phoneNumber
          .replaceFirst(RegExp(r'^\+[0-9]+'), '')
          .trim();
      _profileData['dateOfBirth'] = user.dateOfBirth;
      _profileData['gender'] = user.gender ?? '';
      _profileData['medicalHistory'] = user.medicalHistory ?? '';
      _profileData['allergies'] = user.allergies ?? '';
      _profileData['avatar'] =
          'https://api.dicebear.com/7.x/avataaars/svg?seed=${user.firstName}';
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
    final bgColor = isDark ? const Color(0xFF030712) : Colors.white;

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
      case 'privacy':
        return _buildPlaceholderScreen(
          'Privacy & Security',
          LucideIcons.lock,
          'Privacy settings coming soon',
        );
      case 'support':
        return _buildPlaceholderScreen(
          'Help & Support',
          LucideIcons.headphones,
          'Support options coming soon',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Main Profile Screen ---
  Widget _buildMainProfileScreen() {
    final isDark = _isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
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
                  LucideIcons.lock,
                  'Privacy Policy',
                  () => setState(() => _currentScreen = 'privacy'),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  LucideIcons.settings,
                  'Settings',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  LucideIcons.helpCircle,
                  'Help',
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
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
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
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
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
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          // Background Animation removed as requested
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
                        _buildTextField(
                          LucideIcons.user,
                          _profileData['gender'],
                          (val) => setState(() => _profileData['gender'] = val),
                        ),
                        const SizedBox(height: 20),

                        // Medical History and Allergies removed as requested
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () async {
                            // Validation
                            if (_profileData['name']
                                .toString()
                                .trim()
                                .isEmpty) {
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
                            final phone = _profileData['phone']
                                .toString()
                                .trim();
                            if (phone.isNotEmpty && phone.length != 9) {
                              setState(
                                () => _phoneError =
                                    'Phone number must be 9 digits',
                              );
                              return;
                            }
                            setState(() => _phoneError = null);
                            
                            if (_profileData['dateOfBirth']
                                .toString()
                                .isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select your date of birth',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            try {
                              // Split name into first and last
                              final nameParts = _profileData['name']
                                  .toString()
                                  .trim()
                                  .split(' ');
                              final firstName = nameParts.isNotEmpty
                                  ? nameParts.first
                                  : '';
                              final lastName = nameParts.length > 1
                                  ? nameParts.sublist(1).join(' ')
                                  : '';
                                
                                // Format Date of Birth to YYYY-MM-DD
                                String formattedDob = '';
                                try {
                                    // Parse from "d MMM yyyy" format (e.g. "1 Jan 2024") to YYYY-MM-DD
                                    // We can reuse the stored day/month/year if available or parse string
                                    // Since we have _selectedYear, _selectedMonth, _selectedDay, use them securely if match
                                    // Or parse the string
                                    final dobStr = _profileData['dateOfBirth'].toString();
                                    final parts = dobStr.split(' ');
                                    if (parts.length == 3) {
                                        final day = int.parse(parts[0]);
                                        final monthStr = parts[1];
                                        final year = int.parse(parts[2]);
                                        
                                        final months = [
                                          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                        ];
                                        final month = months.indexOf(monthStr) + 1;
                                        
                                        formattedDob = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                                    } else {
                                        formattedDob = dobStr; // Fallback
                                    }
                                } catch (e) {
                                    print('Error formatting date: $e');
                                    formattedDob = _profileData['dateOfBirth'].toString();
                                }

                                await UserService().updateUserProfile({
                                  'first_name': firstName,
                                  'last_name': lastName,
                                  'phone_number':
                                      '${_profileData['phonePrefix']}${_profileData['phone']}',
                                  'date_of_birth': formattedDob,
                                  'gender': _profileData['gender'],
                                  'medical_history':
                                      _profileData['medicalHistory'],
                                  'allergies': _profileData['allergies'],
                                });

                              // Refresh data
                              await _loadUserData();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Profile updated successfully',
                                    ),
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
                                    content: Text(
                                      'Failed to update profile: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
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
                            child: const Center(
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

  // --- Placeholder Screen ---
  Widget _buildPlaceholderScreen(String title, IconData icon, String message) {
    final isDark = _isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);

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
