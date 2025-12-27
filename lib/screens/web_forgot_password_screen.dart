import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/alert_banner.dart';
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2137),
        title: Text('Dev Tip', style: GoogleFonts.outfit(color: Colors.white)),
        content: Text('Verification Code: $code', style: GoogleFonts.outfit(color: Colors.white70)),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2137),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBackBtn(),
                const SizedBox(height: 20),
                _buildIcon(),
                const SizedBox(height: 32),
                Text(
                  'Reset Password',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),
                const SizedBox(height: 12),
                Text(
                  'Enter your email address and we\'ll send you a code to reset your password.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white60,
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
    );
  }

  Widget _buildBackBtn() {
    return Align(
      alignment: Alignment.topLeft,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white38),
        splashRadius: 20,
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF39A4E6).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        LucideIcons.mail,
        size: 48,
        color: Color(0xFF39A4E6),
      ),
    ).animate().scale(delay: 100.ms, curve: Curves.elasticOut);
  }
}
