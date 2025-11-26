import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/animated_bubble_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/alert_banner.dart';
import '../utils/validators.dart';

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
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _agreedToTerms = false;
  String? _alertMessage;
  bool _isAlertError = true;

  @override
  void initState() {
    super.initState();
    // Add listeners to validate on change
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _alertMessage = null; // Clear alert when user types
    });
  }

  bool _isFormValid() {
    final nameError = Validators.validateName(_nameController.text);
    final emailError = Validators.validateEmail(_emailController.text);
    final phoneError = Validators.validatePhone(_phoneController.text);
    final passwordError = Validators.validatePassword(_passwordController.text);
    final confirmError = Validators.validateConfirmPassword(
      _confirmPasswordController.text,
      _passwordController.text,
    );

    return nameError == null && 
           emailError == null && 
           phoneError == null && 
           passwordError == null && 
           confirmError == null &&
           _agreedToTerms;
  }

  void _handleSignup() {
    // Validate all fields
    final nameError = Validators.validateName(_nameController.text);
    final emailError = Validators.validateEmail(_emailController.text);
    final phoneError = Validators.validatePhone(_phoneController.text);
    final passwordError = Validators.validatePassword(_passwordController.text);
    final confirmError = Validators.validateConfirmPassword(
      _confirmPasswordController.text,
      _passwordController.text,
    );

    if (nameError != null || emailError != null || phoneError != null || 
        passwordError != null || confirmError != null) {
      setState(() {
        _alertMessage = 'Please fix all errors before continuing';
        _isAlertError = true;
      });
      return;
    }

    if (!_agreedToTerms) {
      setState(() {
        _alertMessage = 'Please agree to the Terms and Privacy Policy';
        _isAlertError = true;
      });
      return;
    }

    setState(() => _isLoading = true);

    // Simulate signup
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _alertMessage = 'Account created successfully!';
          _isAlertError = false;
        });
        
        // Navigate after showing success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          ),

          // Main Content
          Positioned.fill(
            top: 100,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9), Color(0xFF39A4E6)],
                    ).createShader(bounds),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: 30, end: 0),

                  const SizedBox(height: 12),

                  Text(
                    'Create your MediScan account to connect with healthcare professionals and manage your medical history.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms).moveY(begin: 30, end: 0),

                  const SizedBox(height: 32),

                  // Alert Banner
                  if (_alertMessage != null)
                    AlertBanner(
                      message: _alertMessage!,
                      isError: _isAlertError,
                      autoDismiss: !_isAlertError,
                      onDismiss: () => setState(() => _alertMessage = null),
                    ),

                  // Signup Form
                  CustomTextField(
                    label: 'Full Name *',
                    placeholder: 'Enter your full name',
                    icon: LucideIcons.user,
                    controller: _nameController,
                    validator: Validators.validateName,
                  ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Email Address *',
                    placeholder: 'example@mediscan.com',
                    icon: LucideIcons.mail,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Phone Number (Optional)',
                    placeholder: '+1 (234) 567-8900',
                    icon: LucideIcons.phone,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ).animate().fadeIn(delay: 700.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Password *',
                    placeholder: 'Create a strong password',
                    icon: LucideIcons.lock,
                    controller: _passwordController,
                    isPassword: true,
                    showPassword: _showPassword,
                    onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                    validator: Validators.validatePassword,
                    validateOnChange: true,
                  ).animate().fadeIn(delay: 800.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Confirm Password *',
                    placeholder: 'Re-enter your password',
                    icon: LucideIcons.lock,
                    controller: _confirmPasswordController,
                    isPassword: true,
                    showPassword: _showConfirmPassword,
                    onTogglePassword: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    validator: (value) => Validators.validateConfirmPassword(value, _passwordController.text),
                  ).animate().fadeIn(delay: 900.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 32),

                  // Terms Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                        activeColor: const Color(0xFF39A4E6),
                      ),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'I agree to the ',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Terms and Conditions',
                                style: TextStyle(
                                  color: Color(0xFF39A4E6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              ' and ',
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
                      ),
                    ],
                  ).animate().fadeIn(delay: 950.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 20),

                  CustomButton(
                    text: 'Sign Up',
                    loadingText: 'Signing up...',
                    onPressed: _isFormValid() ? _handleSignup : null,
                    isLoading: _isLoading,
                  ).animate().fadeIn(delay: 1000.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 32),

                  
                  const SizedBox(height: 24),

                  // Login Link
                  Center(
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
                  ).animate().fadeIn(delay: 1200.ms),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
