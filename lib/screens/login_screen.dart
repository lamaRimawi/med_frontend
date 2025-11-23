import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/animated_bubble_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  final bool isReturningUser;

  const LoginScreen({super.key, this.isReturningUser = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulate login
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  void _handleSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider login would be integrated here')),
    );
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
                        'Log In',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).moveY(begin: -20, end: 0),
                    const SizedBox(width: 40), // Balance the back button
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
                      
                      // Welcome Section
                      Text(
                        widget.isReturningUser ? 'Welcome Back' : 'Hello, Welcome',
                        style: const TextStyle(
                          color: Color(0xFF39A4E6),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        widget.isReturningUser 
                          ? 'Sign in to access your medical reports and connect with verified healthcare professionals.'
                          : 'Sign in to HealthTrack to securely manage your medical reports and health data.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0),

                      const SizedBox(height: 32),

                      // Login Form
                      CustomTextField(
                        label: 'Email or Mobile Number',
                        placeholder: 'example@healthtrack.com',
                        icon: LucideIcons.mail,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),
                      
                      const SizedBox(height: 20),
                      
                      CustomTextField(
                        label: 'Password',
                        placeholder: 'Enter your password',
                        icon: LucideIcons.lock,
                        isPassword: true,
                        controller: _passwordController,
                      ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF39A4E6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                      
                      const SizedBox(height: 20),
                      
                      // Recaptcha placeholder
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Checkbox(value: false, onChanged: (v) {}),
                            const Text('I\'m not a robot', style: TextStyle(color: Colors.black87)),
                            const Spacer(),
                            const Icon(Icons.security, color: Colors.grey, size: 20),
                          ],
                        ),
                      ).animate().fadeIn(delay: 700.ms),

                      const SizedBox(height: 24),

                      CustomButton(
                        text: 'Log In',
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                      ).animate().fadeIn(delay: 800.ms).moveY(begin: 20, end: 0),

                      const SizedBox(height: 32),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or sign in with',
                              style: TextStyle(color: Colors.grey[400], fontSize: 14),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ).animate().fadeIn(delay: 900.ms),

                      const SizedBox(height: 24),

                      // Social Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(LucideIcons.chrome, 'Google'),
                          const SizedBox(width: 20),
                          _buildSocialButton(LucideIcons.facebook, 'Facebook'),
                          const SizedBox(width: 20),
                          _buildSocialButton(LucideIcons.fingerprint, 'Fingerprint'),
                        ],
                      ).animate().fadeIn(delay: 1000.ms).moveY(begin: 20, end: 0),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Sign Up Link - Fixed at bottom
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
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text(
                          'Sign Up',
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

  Widget _buildSocialButton(IconData icon, String provider) {
    return InkWell(
      onTap: () => _handleSocialLogin(provider),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF39A4E6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF39A4E6).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
      begin: const Offset(1, 1),
      end: const Offset(1.05, 1.05),
      duration: 2.seconds,
    );
  }
}
