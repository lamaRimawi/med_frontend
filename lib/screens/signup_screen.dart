import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/animated_bubble_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/alert_banner.dart';
import '../utils/validators.dart';
import '../services/auth_service.dart';
import '../services/auth_api.dart';

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
  DateTime? _dateOfBirth;
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
    final dobError = Validators.validateDateOfBirth(_dateOfBirth);
    final passwordError = Validators.validatePassword(_passwordController.text);
    final confirmError = Validators.validateConfirmPassword(
      _confirmPasswordController.text,
      _passwordController.text,
    );

    return nameError == null && 
           emailError == null && 
           phoneError == null && 
           dobError == null &&
           passwordError == null && 
           confirmError == null &&
           _agreedToTerms;
  }

  void _handleSignup() async {
    // Validate all fields
    final nameError = Validators.validateName(_nameController.text);
    final emailError = Validators.validateEmail(_emailController.text);
    final phoneError = Validators.validatePhone(_phoneController.text);
    final dobError = Validators.validateDateOfBirth(_dateOfBirth);
    final passwordError = Validators.validatePassword(_passwordController.text);
    final confirmError = Validators.validateConfirmPassword(
      _confirmPasswordController.text,
      _passwordController.text,
    );

    if (nameError != null || emailError != null || phoneError != null || dobError != null ||
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

    final (success, message) = await AuthApi.register(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      dateOfBirth: _dateOfBirth!,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (success) {
        _alertMessage = 'Account created successfully!';
        _isAlertError = false;
        
        // Navigate to verification
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context, 
              '/verification',
              arguments: {
                'email': _emailController.text,
                'isPasswordReset': false,
              },
            );
          }
        });
      } else {
        _alertMessage = message ?? 'Registration failed';
        _isAlertError = true;
      }
    });
  }

  void _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    
    try {
      if (provider == 'Google') {
        final result = await AuthService.signInWithGoogle();
        if (result != null && mounted) {
          setState(() {
            _alertMessage = 'Signed up with Google: ${result['email'] ?? 'User'}';
            _isAlertError = false;
            _isLoading = false;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
          });
        } else {
          if (mounted) {
            setState(() {
              _alertMessage = 'Google Sign-In requires Firebase configuration';
              _isAlertError = true;
              _isLoading = false;
            });
          }
        }
      } else if (provider == 'Facebook') {
        final userData = await AuthService.signInWithFacebook();
        if (userData != null && mounted) {
          setState(() {
            _alertMessage = 'Signed up with Facebook: ${userData["email"] ?? userData["name"]}';
            _isAlertError = false;
            _isLoading = false;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
          });
        } else {
          if (mounted) {
            setState(() {
              _alertMessage = 'Facebook Login cancelled or failed';
              _isAlertError = true;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _alertMessage = 'Authentication error: $e';
          _isAlertError = true;
          _isLoading = false;
        });
      }
    }
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

                  // Date of Birth Field
                  GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      final initialDate = _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day);
                      final firstDate = DateTime(now.year - 120);
                      final lastDate = DateTime(now.year - 13);
                      
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initialDate.isBefore(firstDate) || initialDate.isAfter(lastDate) 
                            ? lastDate 
                            : initialDate,
                        firstDate: firstDate,
                        lastDate: lastDate,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF39A4E6),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _dateOfBirth = picked;
                          _alertMessage = null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Validators.validateDateOfBirth(_dateOfBirth) != null
                              ? Colors.red.withOpacity(0.5)
                              : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB)),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            color: Color(0xFF39A4E6),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date of Birth *',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dateOfBirth == null
                                      ? 'Select your date of birth'
                                      : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}',
                                  style: TextStyle(
                                    color: _dateOfBirth == null 
                                        ? (isDark ? Colors.grey[500] : Colors.grey[400]) 
                                        : (isDark ? Colors.white : Colors.black87),
                                    fontSize: 16,
                                    fontWeight: _dateOfBirth == null ? FontWeight.normal : FontWeight.w500,
                                  ),
                                ),
                                if (Validators.validateDateOfBirth(_dateOfBirth) != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      Validators.validateDateOfBirth(_dateOfBirth)!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 750.ms).moveY(begin: 20, end: 0),

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

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[200])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                          ),
                          child: Text(
                            'or sign up with',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[200])),
                    ],
                  ).animate().fadeIn(delay: 1100.ms),

                  const SizedBox(height: 24),

                  // Social Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(LucideIcons.chrome, 'Google'),
                      const SizedBox(width: 20),
                      _buildSocialButton(LucideIcons.facebook, 'Facebook'),
                    ],
                  ).animate().fadeIn(delay: 1200.ms).moveY(begin: 20, end: 0),
                  
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
