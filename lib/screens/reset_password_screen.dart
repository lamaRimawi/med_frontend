import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/animated_bubble_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/alert_banner.dart';
import '../utils/validators.dart';
import '../services/auth_api.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _alertMessage;
  bool _isAlertError = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _alertMessage = null;
    });
  }

  bool _isFormValid() {
    final passwordError = Validators.validatePassword(_passwordController.text);
    final confirmError = Validators.validateConfirmPassword(
      _confirmPasswordController.text,
      _passwordController.text,
    );
    return passwordError == null && confirmError == null;
  }

  String _email = '';
  String _code = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _email = args['email'] ?? '';
      _code = args['code'] ?? '';
    }
  }

  void _handleReset() async {
    final passwordError = Validators.validatePassword(_passwordController.text);
    final confirmError = Validators.validateConfirmPassword(
      _confirmPasswordController.text,
      _passwordController.text,
    );

    if (passwordError != null || confirmError != null) {
      setState(() {
        _alertMessage = 'Please fix all errors before continuing';
        _isAlertError = true;
      });
      return;
    }

    // The backend should handle same password check. We only show AlertBanner for errors.

    setState(() => _isLoading = true);

    final (success, message) = await AuthApi.resetPassword(
      email: _email,
      code: _code,
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (success) {
        _alertMessage = 'Password reset successfully!';
        _isAlertError = false;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        });
      } else {
        // If backend returns specific message for same password, show it
        if (message != null && message.toLowerCase().contains('same')) {
          _alertMessage =
              'New password cannot be the same as the old password.';
        } else {
          _alertMessage = message ?? 'Reset failed';
        }
        _isAlertError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Glass effect colors
    final cardColor = isDark 
        ? const Color(0xFF111827).withOpacity(0.9) 
        : Colors.white;
    final borderColor = isDark 
        ? Colors.white.withOpacity(0.1) 
        : Colors.transparent;
    final bgColor = isDark ? const Color(0xFF0A1929) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (isDark) AnimatedBubbleBackground(isDark: isDark),
          if (!isDark)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    const Color(0xFFF0F9FF).withOpacity(0.5),
                  ],
                ),
              ),
            ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Hero(
                    tag: 'reset_password_icon',
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF39A4E6).withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF39A4E6).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.lock,
                        size: 48,
                        color: Color(0xFF39A4E6),
                      ),
                    ),
                  ).animate().scale(delay: 200.ms),

                  const SizedBox(height: 24),

                  Text(
                    'Create New Password',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    'Enter your new password below. Make sure it\'s strong and secure.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 32),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Alert Banner
                        if (_alertMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: AlertBanner(
                              message: _alertMessage!,
                              isError: _isAlertError,
                              autoDismiss: !_isAlertError,
                              onDismiss: () => setState(() => _alertMessage = null),
                            ),
                          ).animate().fadeIn(duration: 300.ms),

                        // Form
                        CustomTextField(
                          label: 'New Password *',
                          placeholder: '••••••••••••',
                          icon: LucideIcons.lock,
                          controller: _passwordController,
                          isPassword: true,
                          showPassword: _showPassword,
                          onTogglePassword: () =>
                              setState(() => _showPassword = !_showPassword),
                          validator: Validators.validatePassword,
                          validateOnChange: true,
                        ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0),

                        const SizedBox(height: 20),

                        CustomTextField(
                          label: 'Confirm Password *',
                          placeholder: '••••••••••••',
                          icon: LucideIcons.lock,
                          controller: _confirmPasswordController,
                          isPassword: true,
                          showPassword: _showConfirmPassword,
                          onTogglePassword: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                          validator: (value) => Validators.validateConfirmPassword(
                            value,
                            _passwordController.text,
                          ),
                        ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                        const SizedBox(height: 32),

                        CustomButton(
                          text: 'Reset Password',
                          loadingText: 'Resetting...',
                          onPressed: _isFormValid() ? _handleReset : null,
                          isLoading: _isLoading,
                        ).animate().fadeIn(delay: 700.ms).moveY(begin: 20, end: 0),
                      ],
                    ),
                  ).animate().fadeIn(delay: 450.ms).moveY(begin: 40, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
