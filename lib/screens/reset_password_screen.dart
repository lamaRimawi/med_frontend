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
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Stack(
        children: [
          AnimatedBubbleBackground(isDark: isDark),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF39A4E6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ).animate().fadeIn(delay: 200.ms).moveX(begin: -20, end: 0),
                  const Expanded(
                    child: Text(
                      'Reset Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: -20, end: 0),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // Main Content
          Positioned.fill(
            top: 100,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Icon
                  Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF39A4E6).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF39A4E6,
                              ).withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.lock,
                          size: 60,
                          color: Color(0xFF39A4E6),
                        ),
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 2.seconds,
                      )
                      .then()
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .scale(duration: 500.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 32),

                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF39A4E6),
                        Color(0xFF2B8FD9),
                        Color(0xFF39A4E6),
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'Create New Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 12),

                  Text(
                    'Enter your new password below. Make sure it\'s strong and secure.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 40),

                  // Alert Banner
                  if (_alertMessage != null)
                    AlertBanner(
                      message: _alertMessage!,
                      isError: _isAlertError,
                      autoDismiss: !_isAlertError,
                      onDismiss: () => setState(() => _alertMessage = null),
                    ),

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
                  ).animate().fadeIn(delay: 700.ms).moveY(begin: 20, end: 0),

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
                  ).animate().fadeIn(delay: 800.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'Reset Password',
                    loadingText: 'Resetting...',
                    onPressed: _isFormValid() ? _handleReset : null,
                    isLoading: _isLoading,
                  ).animate().fadeIn(delay: 900.ms).moveY(begin: 20, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
