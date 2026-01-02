import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart'; // Make sure this is available if needed, or just standard imports
import '../models/user_model.dart';
import '../services/auth_api.dart';
import '../utils/validators.dart';

class PasswordManagerScreen extends StatefulWidget {
  const PasswordManagerScreen({super.key});

  @override
  State<PasswordManagerScreen> createState() => _PasswordManagerScreenState();
}

class _PasswordManagerScreenState extends State<PasswordManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final _currentPasswordFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // Track if fields have been touched/blurred to enable auto-validation
  bool _currentPasswordTouched = false;
  bool _newPasswordTouched = false;
  bool _confirmPasswordTouched = false;

  @override
  void initState() {
    super.initState();
    _loadStoredPassword();
    
    // Add focus listeners for validation on blur
    _currentPasswordFocus.addListener(() {
      if (!_currentPasswordFocus.hasFocus) {
        setState(() => _currentPasswordTouched = true);
        _formKey.currentState?.validate(); // trigger re-validation
      }
    });
    
    _newPasswordFocus.addListener(() {
      if (!_newPasswordFocus.hasFocus) {
        setState(() => _newPasswordTouched = true);
        _formKey.currentState?.validate();
      }
    });

    _confirmPasswordFocus.addListener(() {
      if (!_confirmPasswordFocus.hasFocus) {
        setState(() => _confirmPasswordTouched = true);
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  String? _storedPassword;
  String? _userEmail;

  Future<void> _loadStoredPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await User.loadFromPrefs();
    setState(() {
      _storedPassword = prefs.getString('user_password');
      _userEmail = user?.email;
    });
  }

  Future<void> _saveNewPassword(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_password', newPassword);
    setState(() {
      _storedPassword = newPassword;
    });
  }

  Future<void> _changePassword() async {
    // Trigger validation on all fields
    setState(() {
      _currentPasswordTouched = true;
      _newPasswordTouched = true;
      _confirmPasswordTouched = true;
    });

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Local validation double-check (optional, currently disabled per request)
      /*
      if (_storedPassword != null && _currentPasswordController.text != _storedPassword) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Current password is incorrect')),
         );
         return;
      }
      */

      // Call API to change password
      if (_userEmail == null) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User email not found. Please login again.')),
            );
          }
          return;
      }

      final (success, message) = await AuthApi.changePassword(
        email: _userEmail!,
        oldPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!success) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                   const Icon(LucideIcons.alertCircle, color: Colors.white),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(message ?? 'Failed to change password'),
                   ),
                ],
              ),
              backgroundColor: const Color(0xFFFF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      // Save the new password locally ONLY if API success
      await _saveNewPassword(_newPasswordController.text);

      setState(() {
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(LucideIcons.checkCircle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Password changed successfully!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        // Wait a bit then go back
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Premium Header
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              stretch: false,
              backgroundColor: const Color(0xFF2B8FD9),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  'Password Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Form Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderInfo(isDark),
                      const SizedBox(height: 32),
                      
                      // Input Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildPremiumField(
                              label: 'Current Password',
                              icon: LucideIcons.lock,
                              controller: _currentPasswordController,
                              focusNode: _currentPasswordFocus,
                              touched: _currentPasswordTouched,
                              isVisible: _isCurrentPasswordVisible,
                              onVisibilityToggle: () => setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
                              validator: (value) => value == null || value.isEmpty ? 'Please enter current password' : null,
                              isDark: isDark,
                              showForgot: true,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(height: 1),
                            ),
                            _buildPremiumField(
                              label: 'New Password',
                              icon: LucideIcons.key,
                              controller: _newPasswordController,
                              focusNode: _newPasswordFocus,
                              touched: _newPasswordTouched,
                              isVisible: _isNewPasswordVisible,
                              onVisibilityToggle: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                              validator: (value) => Validators.validatePassword(value),
                              isDark: isDark,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(height: 1),
                            ),
                            _buildPremiumField(
                              label: 'Confirm Password',
                              icon: LucideIcons.checkCircle2,
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocus,
                              touched: _confirmPasswordTouched,
                              isVisible: _isConfirmPasswordVisible,
                              onVisibilityToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Confirm your password';
                                if (value != _newPasswordController.text) return 'Passwords do not match';
                                return null;
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 48),

                      // Action Button
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF39A4E6).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Update Password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      _buildSecurityNote(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Update',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Change your password regularly to keep your account safe and secure.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool touched,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required String? Function(String?) validator,
    required bool isDark,
    bool showForgot = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF39A4E6),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            if (showForgot)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot?',
                  style: TextStyle(
                    color: Color(0xFF39A4E6),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: !isVisible,
          validator: validator,
          autovalidateMode: touched ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: '••••••••••••',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              fontSize: 16,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 20,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              onPressed: onVisibilityToggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNote(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF39A4E6).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF39A4E6).withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.shieldAlert,
            size: 20,
            color: Color(0xFF39A4E6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Make sure your new password is at least 8 characters long and includes a mix of characters.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
