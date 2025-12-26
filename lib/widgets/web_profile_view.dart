import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/settings_screen.dart';

class WebProfileView extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onLogout;

  const WebProfileView({
    super.key,
    required this.isDarkMode,
    required this.onLogout,
  });

  @override
  State<WebProfileView> createState() => _WebProfileViewState();
}

class _WebProfileViewState extends State<WebProfileView> {
  String _currentView = 'main'; // 'main', 'edit', 'privacy', 'help'
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Form controllers for edit profile
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  
  String _phonePrefix = '+962';
  String _selectedGender = '';
  String _dateOfBirth = '';

  Map<String, dynamic> _profileData = {
    'name': 'User Name',
    'email': 'user@example.com',
    'phone': '+962 79 000 0000',
    'avatar': '',
    'gender': '',
    'dateOfBirth': '',
    'medicalHistory': '',
    'allergies': '',
  };

  final List<Map<String, String>> _countryCodes = [
    {'code': '+962', 'country': 'Jordan', 'flag': '🇯🇴'},
    {'code': '+970', 'country': 'Palestine', 'flag': '🇵🇸'},
    {'code': '+966', 'country': 'Saudi Arabia', 'flag': '🇸🇦'},
    {'code': '+971', 'country': 'UAE', 'flag': '🇦🇪'},
    {'code': '+1', 'country': 'United States', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'United Kingdom', 'flag': '🇬🇧'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', pickedFile.path);
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await UserService().getUserProfile();
      if (mounted) {
        _updateLocalUserState(user);
      }
    } catch (e) {
      final user = await User.loadFromPrefs();
      if (user != null && mounted) {
        _updateLocalUserState(user);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

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
      
      // Parse phone
      String fullPhone = user.phoneNumber;
      String phoneBody = fullPhone;
      String prefix = '+962';
      
      final match = RegExp(r'^(\+\d{1,4})[\s-]*(.*)$').firstMatch(fullPhone);
      if (match != null) {
        prefix = match.group(1) ?? '+962';
        phoneBody = match.group(2) ?? '';
      }
      
      _phonePrefix = prefix;
      _profileData['phone'] = phoneBody.replaceAll(' ', '').trim();
      _profileData['dateOfBirth'] = user.dateOfBirth;
      _profileData['gender'] = user.gender ?? '';
      _profileData['medicalHistory'] = user.medicalHistory ?? '';
      _profileData['allergies'] = user.allergies ?? '';

      // Update controllers
      _nameController.text = _profileData['name'];
      _emailController.text = _profileData['email'];
      _phoneController.text = _profileData['phone'];
      _medicalHistoryController.text = _profileData['medicalHistory'];
      _allergiesController.text = _profileData['allergies'];
      _selectedGender = _profileData['gender'];
      _dateOfBirth = _profileData['dateOfBirth'];

      if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
        if (user.profileImageUrl!.startsWith('http')) {
          _profileData['avatar'] = user.profileImageUrl;
        } else {
          final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
          _profileData['avatar'] = '$baseUrl${user.profileImageUrl}';
        }
      } else {
        _profileData['avatar'] =
            'https://api.dicebear.com/7.x/avataaars/svg?seed=${user.firstName}';
      }
    });
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isLoading = true);
      
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      
      final Map<String, String> updateData = {
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': '$_phonePrefix${_phoneController.text}',
        'date_of_birth': _dateOfBirth,
        'medical_history': _medicalHistoryController.text,
        'allergies': _allergiesController.text,
      };

      await UserService().updateUserProfile(updateData, imageFile: _imageFile);
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        setState(() => _currentView = 'main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A9FD8), Color(0xFF3B8BC9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(60, 30, 60, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_currentView != 'main')
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      onPressed: () => setState(() => _currentView = 'main'),
                    ),
                  Text(
                    _getHeaderTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (_currentView == 'main') ...[
                const SizedBox(height: 30),
                Row(
                  children: [
                    Stack(
                      children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 3,
                              ),
                              color: const Color(0xFF4A9FD8).withOpacity(0.2),
                            ),
                            child: _imageFile != null
                                ? ClipOval(
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                      width: 90,
                                      height: 90,
                                    ),
                                  )
                                : (_profileData['avatar'] != null && _profileData['avatar']!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          _profileData['avatar']!,
                                          fit: BoxFit.cover,
                                          width: 90,
                                          height: 90,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              LucideIcons.user,
                                              size: 40,
                                              color: Color(0xFF4A9FD8),
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        LucideIcons.user,
                                        size: 40,
                                        color: Color(0xFF4A9FD8),
                                      )),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.camera,
                                color: Color(0xFF4A9FD8),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _profileData['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$_phonePrefix ${_profileData['phone']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _profileData['email'],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  String _getHeaderTitle() {
    switch (_currentView) {
      case 'edit':
        return 'Edit Profile';
      case 'privacy':
        return 'Privacy Policy';
      case 'help':
        return 'Help & Support';
      default:
        return 'My Profile';
    }
  }

  Widget _buildContent() {
    switch (_currentView) {
      case 'edit':
        return _buildEditProfileView();
      case 'privacy':
        return _buildPrivacyView();
      case 'help':
        return _buildHelpView();
      default:
        return _buildMainView();
    }
  }

  Widget _buildMainView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _buildMenuItem(
                icon: LucideIcons.user,
                title: 'Edit Profile',
                onTap: () => setState(() => _currentView = 'edit'),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
              _buildMenuItem(
                icon: LucideIcons.lock,
                title: 'Privacy Policy',
                onTap: () => setState(() => _currentView = 'privacy'),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
              _buildMenuItem(
                icon: LucideIcons.settings,
                title: 'Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
              _buildMenuItem(
                icon: LucideIcons.helpCircle,
                title: 'Help',
                onTap: () => setState(() => _currentView = 'help'),
              ).animate().fadeIn(delay: 400.ms, duration: 300.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
              _buildMenuItem(
                icon: LucideIcons.logOut,
                title: 'Logout',
                isLogout: true,
                onTap: () async {
                  final shouldLogout = await _showLogoutDialog();
                  if (shouldLogout == true) {
                    widget.onLogout();
                  }
                },
              ).animate().fadeIn(delay: 500.ms, duration: 300.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4A9FD8).withOpacity(0.3),
                          width: 4,
                        ),
                        color: const Color(0xFF4A9FD8).withOpacity(0.1),
                      ),
                      child: _imageFile != null
                          ? ClipOval(
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                            )
                          : (_profileData['avatar'] != null && _profileData['avatar']!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    _profileData['avatar']!,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        LucideIcons.user,
                                        size: 50,
                                        color: Color(0xFF4A9FD8),
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  LucideIcons.user,
                                  size: 50,
                                  color: Color(0xFF4A9FD8),
                                )),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF4A9FD8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.camera,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Form Fields
              _buildTextField('Full Name', _nameController, LucideIcons.user),
              const SizedBox(height: 20),
              _buildTextField('Email', _emailController, LucideIcons.mail, enabled: false),
              const SizedBox(height: 20),
              _buildPhoneField(),
              const SizedBox(height: 20),
              _buildDateField(),
              const SizedBox(height: 20),
              _buildGenderField(),
              const SizedBox(height: 20),
              _buildTextField('Medical History', _medicalHistoryController, LucideIcons.fileText, maxLines: 3),
              const SizedBox(height: 20),
              _buildTextField('Allergies', _allergiesController, LucideIcons.alertCircle, maxLines: 3),
              const SizedBox(height: 40),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9FD8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    bool enabled = true,
  }) {
    final cardColor = widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF4A9FD8), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  maxLines: maxLines,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter $label',
                    hintStyle: TextStyle(
                      color: widget.isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    final cardColor = widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.phone, color: Color(0xFF4A9FD8), size: 20),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _phonePrefix,
                underline: const SizedBox(),
                style: TextStyle(color: textColor, fontSize: 15),
                dropdownColor: cardColor,
                items: _countryCodes.map((code) {
                  return DropdownMenuItem(
                    value: code['code'],
                    child: Text('${code['flag']} ${code['code']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _phonePrefix = value);
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Phone number',
                    hintStyle: TextStyle(
                      color: widget.isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    final cardColor = widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _dateOfBirth = '${date.day} ${_getMonthName(date.month)} ${date.year}';
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, color: Color(0xFF4A9FD8), size: 20),
                const SizedBox(width: 12),
                Text(
                  _dateOfBirth.isEmpty ? 'Select date' : _dateOfBirth,
                  style: TextStyle(
                    color: _dateOfBirth.isEmpty
                        ? (widget.isDarkMode ? Colors.grey[600] : Colors.grey[400])
                        : textColor,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    final cardColor = widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.users, color: Color(0xFF4A9FD8), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedGender.isEmpty ? null : _selectedGender,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: Text(
                    'Select gender',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                  style: TextStyle(color: textColor, fontSize: 15),
                  dropdownColor: cardColor,
                  items: ['Male', 'Female', 'Other'].map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedGender = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildPrivacyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Your privacy is important to us. This privacy policy explains how we collect, use, and protect your personal information.',
                style: TextStyle(
                  fontSize: 16,
                  color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 30),
              _buildPrivacySection(
                'Data Collection',
                'We collect information you provide directly to us, including your name, email, phone number, and medical information.',
              ),
              _buildPrivacySection(
                'Data Usage',
                'Your data is used to provide and improve our services, communicate with you, and ensure the security of your account.',
              ),
              _buildPrivacySection(
                'Data Protection',
                'We implement appropriate security measures to protect your personal information from unauthorized access, alteration, or disclosure.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help & Support',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Need assistance? We\'re here to help!',
                style: TextStyle(
                  fontSize: 16,
                  color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 30),
              _buildHelpCard(
                LucideIcons.mail,
                'Email Support',
                'support@mediscan.com',
                'Send us an email',
              ),
              const SizedBox(height: 16),
              _buildHelpCard(
                LucideIcons.phone,
                'Phone Support',
                '+962 79 123 4567',
                'Call us anytime',
              ),
              const SizedBox(height: 16),
              _buildHelpCard(
                LucideIcons.messageCircle,
                'Live Chat',
                'Available 24/7',
                'Chat with our team',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpCard(IconData icon, String title, String subtitle, String action) {
    final cardColor = widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A9FD8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF4A9FD8), size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            action,
            style: const TextStyle(
              color: Color(0xFF4A9FD8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final cardColor = widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final iconColor = const Color(0xFF4A9FD8);
    final textColor = isLogout 
        ? const Color(0xFF4A9FD8) 
        : (widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (!isLogout)
                Icon(
                  LucideIcons.chevronRight,
                  color: widget.isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9FD8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
