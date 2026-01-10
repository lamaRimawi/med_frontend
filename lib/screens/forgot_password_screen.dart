import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/animated_bubble_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/auth_api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _handleSubmit() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        // Show error in a way consistent with your app, e.g. AlertBanner or inline error
      });
      return;
    }

    setState(() => _isLoading = true);

    final (success, message, code) = await AuthApi.forgotPassword(
      email: _emailController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      if (code != null) {
        // Show code for testing/dev
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verification Code'),
            content: Text('Your code is: $code'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToVerification();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Optionally show a message in AlertBanner or inline
        _navigateToVerification();
      }
    } else {
      setState(() {
        // Show error in a way consistent with your app, e.g. AlertBanner or inline error
      });
    }
  }

  void _navigateToVerification() {
    Navigator.pushNamed(
      context,
      '/verification',
      arguments: {'email': _emailController.text, 'isPasswordReset': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Glass effect colors
    final cardColor = isDark 
        ? const Color(0xFF122640).withOpacity(0.9) 
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
          // Background
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
          
          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Header Section
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                        LucideIcons.keyRound, // Changed icon for forgot password
                        size: 48,
                        color: Color(0xFF39A4E6),
                      ),
                    ),
                  ).animate().scale(delay: 200.ms),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Enter your email address and we\'ll send you a verification code to reset your password.',
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
                        CustomTextField(
                          label: 'Email Address',
                          placeholder: 'example@example.com',
                          icon: LucideIcons.mail,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0),

                        const SizedBox(height: 32),

                        CustomButton(
                          text: 'Send Reset Code',
                          onPressed: _handleSubmit,
                          isLoading: _isLoading,
                        ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        // Back to Login
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Remember your password? ",
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Back to Login',
                                  style: TextStyle(
                                    color: Color(0xFF39A4E6),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 700.ms),
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
