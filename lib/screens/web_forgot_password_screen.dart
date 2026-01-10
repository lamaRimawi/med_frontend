import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/alert_banner.dart';
import '../widgets/animated_bubble_background.dart';
import '../services/auth_api.dart';
import '../utils/validators.dart';

class WebForgotPasswordScreen extends StatefulWidget {
  const WebForgotPasswordScreen({super.key});

  @override
  State<WebForgotPasswordScreen> createState() => _WebForgotPasswordScreenState();
}

class _WebForgotPasswordScreenState extends State<WebForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _alertMessage;
  bool _isAlertError = true;

  void _handleSubmit() async {
    final emailError = Validators.validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() {
        _alertMessage = emailError;
        _isAlertError = true;
      });
      return;
    }

    setState(() => _isLoading = true);

    final (success, message, code) = await AuthApi.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _alertMessage = 'Verification code sent to your email!';
        _isAlertError = false;
      });
      
      // If code is returned (dev mode), show it
      if (code != null) {
        _showDevCode(code);
      } else {
        _navigateToVerification();
      }
    } else {
      setState(() {
        _alertMessage = message ?? 'Failed to send reset code';
        _isAlertError = true;
      });
    }
  }

  void _showDevCode(String code) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F2137) : Colors.white,
        title: Text('Dev Tip', style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1E293B))),
        content: Text('Verification Code: $code', style: GoogleFonts.outfit(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToVerification();
            },
            child: Text('OK', style: GoogleFonts.outfit(color: const Color(0xFF39A4E6))),
          ),
        ],
      ),
    );
  }

  void _navigateToVerification() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/verification',
          arguments: {'email': _emailController.text, 'isPasswordReset': true},
        );
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
    final shadowColor = isDark 
        ? Colors.black.withOpacity(0.5) 
        : const Color(0xFF39A4E6).withOpacity(0.15);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final bgColor = isDark ? const Color(0xFF0A1929) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          if (isDark) const AnimatedBubbleBackground(),
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBackBtn(isDark),
                    const SizedBox(height: 20),
                    _buildIcon(),
                    const SizedBox(height: 32),
                    Text(
                      'Reset Password',
                      style: GoogleFonts.outfit(
                        color: textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),
                    const SizedBox(height: 12),
                    Text(
                      'Enter your email address and we\'ll send you a code to reset your password.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: subtitleColor,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
                    const SizedBox(height: 32),
                    if (_alertMessage != null)
                      AlertBanner(
                        message: _alertMessage!,
                        isError: _isAlertError,
                        onDismiss: () => setState(() => _alertMessage = null),
                      ).animate().fadeIn(),
                    const SizedBox(height: 32),
                    CustomTextField(
                      label: 'Email Address',
                      placeholder: 'name@example.com',
                      icon: LucideIcons.mail,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 40),
                    CustomButton(
                      text: 'Send Reset Code',
                      onPressed: _handleSubmit,
                      isLoading: _isLoading,
                    ).animate().fadeIn(delay: 500.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackBtn(bool isDark) {
    return Align(
      alignment: Alignment.topLeft,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white38 : const Color(0xFF64748B)),
        splashRadius: 20,
      ),
    );
  }

  Widget _buildIcon() {
    return Hero(
      tag: 'forgot_password_icon',
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF39A4E6).withOpacity(0.1),
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
          LucideIcons.mail,
          size: 48,
          color: Color(0xFF39A4E6),
        ),
      ),
    ).animate().scale(delay: 100.ms, curve: Curves.elasticOut);
  }
}
