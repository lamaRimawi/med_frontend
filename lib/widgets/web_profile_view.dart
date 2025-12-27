import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../screens/settings_screen.dart';

class WebProfileView extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onLogout;
  final VoidCallback? onProfileUpdated;

  const WebProfileView({
    super.key,
    required this.isDarkMode,
    required this.onLogout,
    this.onProfileUpdated,
  });

  @override
  State<WebProfileView> createState() => _WebProfileViewState();
}

class _WebProfileViewState extends State<WebProfileView> {
  String _currentView = 'main'; // 'main', 'edit', 'privacy', 'help'
  bool _isLoading = false;
  File? _imageFile;
  String? _token;
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

  List<Map<String, String>> get _uniqueCountryCodes {
    final seen = <String>{};
    return _countryCodes.where((code) {
      final value = code['code'];
      if (value == null || seen.contains(value)) {
        return false;
      } else {
        seen.add(value);
        return true;
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final codes = _uniqueCountryCodes.map((c) => c['code']).toSet();
      if (!codes.contains(_phonePrefix)) {
        setState(() {
          _phonePrefix = _uniqueCountryCodes.isNotEmpty
              ? _uniqueCountryCodes.first['code']!
              : '+962';
        });
      }
    });
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
      _token = await ApiClient.instance.getToken();
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

      String fullPhone = user.phoneNumber;
      String phoneBody = fullPhone;
      String prefix = '+962';

      final match = RegExp(r'^(\+\d{1,4})[\s-]*(.*)$').firstMatch(fullPhone);
      if (match != null) {
        prefix = match.group(1) ?? '+962';
        phoneBody = match.group(2) ?? '';
      }

      final codes = _uniqueCountryCodes.map((c) => c['code']).toSet();
      if (!codes.contains(prefix)) {
        prefix = _uniqueCountryCodes.isNotEmpty
            ? _uniqueCountryCodes.first['code']!
            : '+962';
      }
      _phonePrefix = prefix;
      _profileData['phone'] = phoneBody.replaceAll(' ', '').trim();
      _profileData['dateOfBirth'] = user.dateOfBirth;
      _profileData['gender'] = user.gender ?? '';
      _profileData['medicalHistory'] = user.medicalHistory ?? '';
      _profileData['allergies'] = user.allergies ?? '';

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
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

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
        widget.onProfileUpdated?.call();

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
    return Container(
      color: Colors.transparent,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
            child: Column(
              children: [
                _buildPremiumHeader(),
                _buildContent(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
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

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          Text(
            _getHeaderTitle(),
            style: GoogleFonts.outfit(
              color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
          const SizedBox(height: 30),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [Color(0xFF2193b0), Color(0xFF6dd5ed), Color(0xFF2193b0)],
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat())
               .rotate(duration: 4.seconds),
              
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                  border: Border.all(
                    color: Colors.transparent,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : (_profileData['avatar'] != null && _profileData['avatar']!.isNotEmpty
                        ? Image.network(
                            _profileData['avatar']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.user, size: 40),
                          )
                        : const Icon(LucideIcons.user, size: 40)),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2193b0),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.camera, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            _profileData['name'],
            style: GoogleFonts.outfit(
              color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildModernChip(LucideIcons.phone, '$_phonePrefix ${_profileData['phone']}'),
              _buildModernChip(LucideIcons.mail, _profileData['email']),
            ],
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildModernChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDarkMode 
          ? Colors.white.withOpacity(0.05) 
          : const Color(0xFF2193b0).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode 
            ? Colors.white.withOpacity(0.1) 
            : const Color(0xFF2193b0).withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2193b0)),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              color: widget.isDarkMode ? Colors.grey[300] : const Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildNextGenMenuGrid(),
        ],
      ),
    );
  }

  Widget _buildNextGenMenuGrid() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildPremiumMenuCard(
          icon: LucideIcons.user,
          title: 'Edit Profile',
          subtitle: 'Personal info',
          color: const Color(0xFF3498db),
          onTap: () => setState(() => _currentView = 'edit'),
        ),
        _buildPremiumMenuCard(
          icon: LucideIcons.shieldCheck,
          title: 'Privacy',
          subtitle: 'Security data',
          color: const Color(0xFF2ecc71),
          onTap: () => setState(() => _currentView = 'privacy'),
        ),
        _buildPremiumMenuCard(
          icon: LucideIcons.helpCircle,
          title: 'Support',
          subtitle: 'FAQs & help',
          color: const Color(0xFFf1c40f),
          onTap: () => setState(() => _currentView = 'help'),
        ),
        _buildPremiumMenuCard(
          icon: LucideIcons.settings,
          title: 'Settings',
          subtitle: 'Preferences',
          color: const Color(0xFF95a5a6),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
        _buildPremiumMenuCard(
          icon: LucideIcons.logOut,
          title: 'Logout',
          subtitle: 'Sign out safely',
          color: const Color(0xFFe74c3c),
          isLogout: true,
          onTap: () async {
            final confirmed = await _showLogoutDialog();
            if (confirmed == true) {
              widget.onLogout();
            }
          },
        ),
      ],
    );
  }

  Widget _buildPremiumMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 200, // Slightly wider for better spacing
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
              ? Colors.white.withOpacity(0.03) 
              : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isLogout 
                ? const Color(0xFFe74c3c).withOpacity(0.2) 
                : Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: isLogout 
                    ? const Color(0xFFe74c3c) 
                    : (widget.isDarkMode ? Colors.white : const Color(0xFF1E293B)),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: widget.isDarkMode ? Colors.grey[500] : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .shimmer(duration: 3.seconds, delay: 2.seconds, color: Colors.white.withOpacity(0.02)),
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
                                    headers: _token != null ? {'Authorization': 'Bearer $_token'} : null,
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
              _buildPremiumButton(
                onPressed: _isLoading ? null : _saveProfile,
                isLoading: _isLoading,
                text: 'Save Changes',
              ),
              const SizedBox(height: 20),
              _buildPremiumButton(
                onPressed: () => setState(() => _currentView = 'main'),
                text: 'Back to Profile',
                isSecondary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumButton({
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
    bool isSecondary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.transparent : const Color(0xFF2193b0),
          foregroundColor: isSecondary 
            ? (widget.isDarkMode ? Colors.white : const Color(0xFF2193b0)) 
            : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isSecondary 
              ? BorderSide(color: const Color(0xFF2193b0).withOpacity(0.5)) 
              : BorderSide.none,
          ),
          elevation: isSecondary ? 0 : 10,
          shadowColor: const Color(0xFF2193b0).withOpacity(0.3),
        ),
        child: isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
          : Text(
              text,
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.grey[400] : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
              ? Colors.white.withOpacity(0.05) 
              : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDarkMode 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2193b0), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  maxLines: maxLines,
                  style: GoogleFonts.inter(
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 15,
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.grey[400] : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
              ? Colors.white.withOpacity(0.05) 
              : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDarkMode 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.phone, color: Color(0xFF2193b0), size: 20),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _phonePrefix,
                underline: const SizedBox(),
                style: GoogleFonts.inter(
                  color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 15,
                ),
                dropdownColor: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                items: _uniqueCountryCodes.map((code) {
                  return DropdownMenuItem(
                    value: code['code'],
                    child: Text('${code['flag']} ${code['code']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _phonePrefix = value);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 15,
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.grey[400] : const Color(0xFF64748B),
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
              color: widget.isDarkMode 
                ? Colors.white.withOpacity(0.05) 
                : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isDarkMode 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, color: Color(0xFF2193b0), size: 20),
                const SizedBox(width: 12),
                Text(
                  _dateOfBirth.isEmpty ? 'Select date' : _dateOfBirth,
                  style: GoogleFonts.inter(
                    color: _dateOfBirth.isEmpty
                        ? (widget.isDarkMode ? Colors.grey[600] : Colors.grey[400])
                        : (widget.isDarkMode ? Colors.white : const Color(0xFF1E293B)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.grey[400] : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
              ? Colors.white.withOpacity(0.05) 
              : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDarkMode 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.users, color: Color(0xFF2193b0), size: 20),
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
                  style: GoogleFonts.inter(
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 15,
                  ),
                  dropdownColor: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  items: ['Male', 'Female', 'Other'].map((gender) {
                    return DropdownMenuItem(value: gender, child: Text(gender));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedGender = value);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 30),
          _buildPremiumButton(
            onPressed: () => setState(() => _currentView = 'main'),
            text: 'Back to Profile',
            isSecondary: true,
          ),
        ],
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
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: widget.isDarkMode ? Colors.grey[400] : const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need assistance? We\'re here to help!',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: widget.isDarkMode ? Colors.grey[300] : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 30),
          _buildHelpCard(
            icon: LucideIcons.mail,
            title: 'Email Support',
            content: 'support@medtrack.com',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildHelpCard(
            icon: LucideIcons.phone,
            title: 'Call Us',
            content: '+962 70 000 0000',
            onTap: () {},
          ),
          const SizedBox(height: 40),
          _buildPremiumButton(
            onPressed: () => setState(() => _currentView = 'main'),
            text: 'Back to Profile',
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required String content,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDarkMode 
          ? Colors.white.withOpacity(0.05) 
          : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode 
            ? Colors.white.withOpacity(0.1) 
            : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2193b0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF2193b0), size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: widget.isDarkMode ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.externalLink, color: Colors.grey[400], size: 18),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(
            color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.inter(
            color: widget.isDarkMode ? Colors.grey[300] : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey[500]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFe74c3c),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
