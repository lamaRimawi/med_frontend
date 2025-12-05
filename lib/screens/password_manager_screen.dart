import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> _loadStoredPassword() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storedPassword = prefs.getString('user_password');
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
      final (success, message) = await AuthApi.changePassword(
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
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5F5),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
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
                          'Password Manager',
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
            
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  // Use autovalidateMode disabled initially, we trigger validation manually on blur
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      
                      // Current Password Field
                      _buildModernPasswordField(
                        label: 'Current Password',
                        controller: _currentPasswordController,
                        focusNode: _currentPasswordFocus,
                        touched: _currentPasswordTouched,
                        isVisible: _isCurrentPasswordVisible,
                        textInputAction: TextInputAction.next,
                        onVisibilityToggle: () {
                          setState(() {
                            _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                        showForgotPassword: true,
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // New Password Field
                      _buildModernPasswordField(
                        label: 'New Password',
                        controller: _newPasswordController,
                        focusNode: _newPasswordFocus,
                        touched: _newPasswordTouched,
                        isVisible: _isNewPasswordVisible,
                        textInputAction: TextInputAction.next,
                        onVisibilityToggle: () {
                          setState(() {
                            _isNewPasswordVisible = !_isNewPasswordVisible;
                          });
                        },
                        validator: (value) {
                          // Use strict validation for new password
                          return Validators.validatePassword(value);
                        },
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Confirm New Password Field
                      _buildModernPasswordField(
                        label: 'Confirm New Password',
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        touched: _confirmPasswordTouched,
                        isVisible: _isConfirmPasswordVisible,
                        textInputAction: TextInputAction.done,
                        onVisibilityToggle: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Change Password Button
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF39A4E6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                            disabledBackgroundColor: const Color(0xFF39A4E6).withOpacity(0.6),
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
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
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

  Widget _buildModernPasswordField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool touched,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required String? Function(String?) validator,
    required TextInputAction textInputAction,
    bool showForgotPassword = false,
    required bool isDark,
  }) {
    // Only show error if touched and field has error (validator returns string)
    // We achieve this by letting TextFormField handle it but manually triggering logic
    // Actually, simply using AutovalidateMode.onUserInteraction on the FIELD (if touched)
    // is the standard way.
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: !isVisible,
          validator: validator,
          textInputAction: textInputAction,
          // Only auto-validate if already touched (blurred once)
          autovalidateMode: touched ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: '••••••••••',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              fontSize: 15,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            // Border definitions for modern look
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF39A4E6), // Brand color on focus
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444), // Red on error
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444), // Red on focused error
                width: 2,
              ),
            ),
            // Error style - below input
            errorStyle: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 13,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 20,
                color: const Color(0xFF39A4E6),
              ),
              onPressed: onVisibilityToggle,
            ),
          ),
        ),
        if (showForgotPassword) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot-password');
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Color(0xFF39A4E6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
