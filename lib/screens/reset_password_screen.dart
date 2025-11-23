import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/animated_bubble_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _handleReset() {
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBubbleBackground(),

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
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
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
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF39A4E6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.lock,
                      size: 48,
                      color: Color(0xFF39A4E6),
                    ),
                  ).animate().scale(delay: 500.ms, duration: 500.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 32),

                  Text(
                    'Create New Password',
                    style: const TextStyle(
                      color: Color(0xFF39A4E6),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 12),

                  Text(
                    'Enter your new password below. Make sure it\'s strong and secure.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 40),

                  CustomTextField(
                    label: 'New Password',
                    placeholder: '••••••••••••',
                    icon: LucideIcons.lock,
                    isPassword: true,
                    controller: _passwordController,
                  ).animate().fadeIn(delay: 700.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Confirm Password',
                    placeholder: '••••••••••••',
                    icon: LucideIcons.lock,
                    isPassword: true,
                    controller: _confirmPasswordController,
                  ).animate().fadeIn(delay: 700.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'Reset Password',
                    onPressed: _handleReset,
                    isLoading: _isLoading,
                  ).animate().fadeIn(delay: 800.ms).moveY(begin: 20, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
