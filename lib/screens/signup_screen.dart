import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/animated_bubble_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _handleSignup() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate signup
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        // Navigate to home or verification
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBubbleBackground(),

          Column(
            children: [
              // Header
              Container(
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
                        'Sign Up',
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

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      Text(
                        'Create Account',
                        style: const TextStyle(
                          color: Color(0xFF39A4E6),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0),

                      const SizedBox(height: 8),

                      Text(
                        'Join HealthTrack to securely store your medical reports and connect with verified healthcare professionals.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0),

                      const SizedBox(height: 32),

                      // Signup Form
                      CustomTextField(
                        label: 'Full Name *',
                        placeholder: 'Enter your full name',
                        icon: LucideIcons.user,
                        controller: _nameController,
                      ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                      const SizedBox(height: 20),

                      CustomTextField(
                        label: 'Email Address *',
                        placeholder: 'example@healthtrack.com',
                        icon: LucideIcons.mail,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                      const SizedBox(height: 20),

                      CustomTextField(
                        label: 'Phone Number (Optional)',
                        placeholder: '+1 (234) 567-8900',
                        icon: LucideIcons.phone,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                      const SizedBox(height: 20),

                      CustomTextField(
                        label: 'Password *',
                        placeholder: 'Create a strong password',
                        icon: LucideIcons.lock,
                        isPassword: true,
                        controller: _passwordController,
                      ).animate().fadeIn(delay: 700.ms).moveY(begin: 20, end: 0),

                      const SizedBox(height: 20),

                      CustomTextField(
                        label: 'Confirm Password *',
                        placeholder: 'Re-enter your password',
                        icon: LucideIcons.lock,
                        isPassword: true,
                        controller: _confirmPasswordController,
                      ).animate().fadeIn(delay: 700.ms).moveY(begin: 20, end: 0),

                      const SizedBox(height: 32),

                      CustomButton(
                        text: 'Sign Up',
                        onPressed: _handleSignup,
                        isLoading: _isLoading,
                      ).animate().fadeIn(delay: 800.ms).moveY(begin: 20, end: 0),

                      const SizedBox(height: 32),

                      // Terms
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'I agree to the Terms and Conditions and',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  color: Color(0xFF39A4E6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 900.ms),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Login Link - Fixed at bottom
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: Color(0xFF39A4E6),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
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
    );
  }
}
