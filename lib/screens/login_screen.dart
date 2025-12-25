import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/animated_bubble_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/alert_banner.dart';
import '../widgets/theme_toggle.dart';
import '../utils/validators.dart';
import '../services/auth_service.dart';
import '../services/auth_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _showPassword = false;
  String? _alertMessage;
  bool _isAlertError = true;

  bool get _isDarkMode =>
      ThemeProvider.of(context)?.themeMode == ThemeMode.dark ?? false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _alertMessage = null;
    });
  }

  bool _isFormValid() {
    final emailError = Validators.validateEmail(_emailController.text);
    final passwordError = _passwordController.text.isEmpty
        ? 'Password is required'
        : null;
    return emailError == null && passwordError == null;
  }

  void _handleLogin() async {
    final emailError = Validators.validateEmail(_emailController.text);
    final passwordError = _passwordController.text.isEmpty
        ? 'Password is required'
        : null;

    if (emailError != null || passwordError != null) {
      setState(() {
        _alertMessage = 'Please fix all errors before continuing';
        _isAlertError = true;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call backend login
      final result = await AuthApi.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.$1) {
        // Fetch user profile after successful login
        final (profileSuccess, user, profileMessage) =
            await AuthApi.getUserProfile();

        if (!mounted) return;

        if (profileSuccess) {
          setState(() {
            _alertMessage = 'Login successful!';
            _isAlertError = false;
            _isLoading = false;
          });

          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) Navigator.pushReplacementNamed(context, '/home');
          });
        } else {
          // Login succeeded but profile fetch failed - still navigate but warn
          print('Warning: Profile fetch failed: $profileMessage');
          setState(() {
            _alertMessage = 'Login successful!';
            _isAlertError = false;
            _isLoading = false;
          });

          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) Navigator.pushReplacementNamed(context, '/home');
          });
        }
      } else {
        setState(() {
          _alertMessage = result.$2 ?? 'Login failed';
          _isAlertError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _alertMessage = 'Login error: $e';
        _isAlertError = true;
        _isLoading = false;
      });
    }
  }

  void _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);

    try {
      if (provider == 'Google') {
        final result = await AuthService.signInWithGoogle();
        if (result != null && mounted) {
          setState(() {
            _alertMessage =
                'Signed in with Google: ${result['email'] ?? 'User'}';
            _isAlertError = false;
            _isLoading = false;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pushReplacementNamed(context, '/home');
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
            _alertMessage =
                'Signed in with Facebook: ${userData['email'] ?? userData['name']}';
            _isAlertError = false;
            _isLoading = false;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pushReplacementNamed(context, '/home');
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
      } else if (provider == 'Fingerprint') {
        // Check if enabled first
        final prefs = await SharedPreferences.getInstance();
        final isEnabled = prefs.getBool('biometric_enabled') ?? false;

        if (!isEnabled) {
           if (!mounted) return;
           setState(() {
             _alertMessage = 'Biometric login is not enabled in Settings';
             _isAlertError = true;
             _isLoading = false;
           });
           return;
        }

        final (success, message) = await AuthService.loginWithBiometrics();
        
        if (!mounted) return;

        if (success) {
          setState(() {
            _alertMessage = 'Biometric login successful!';
            _isAlertError = false;
            _isLoading = false;
          });
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) Navigator.pushReplacementNamed(context, '/home');
          });
        } else {
          setState(() {
            _alertMessage = message ?? 'Biometric login failed';
            _isAlertError = true;
            _isLoading = false;
          });
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
    final isDark = _isDarkMode;
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
          ),

          // Main Content
          Positioned.fill(
            top: 100,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Welcome Section
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF39A4E6),
                        Color(0xFF2B8FD9),
                        Color(0xFF39A4E6),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Welcome Back',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: 30, end: 0),

                  const SizedBox(height: 12),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                        fontSize: 18,
                      ),
                      children: [
                        const TextSpan(text: 'Sign in to '),
                        TextSpan(
                          text: 'MediScan',
                          style: const TextStyle(
                            color: Color(0xFF39A4E6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' to continue'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).moveY(begin: 30, end: 0),

                  const SizedBox(height: 40),

                  // Alert Banner
                  if (_alertMessage != null)
                    AlertBanner(
                      message: _alertMessage!,
                      isError: _isAlertError,
                      autoDismiss: !_isAlertError,
                      onDismiss: () => setState(() => _alertMessage = null),
                    ),

                  // Login Form
                  CustomTextField(
                    label: 'Email or Mobile Number',
                    placeholder: 'example@mediscan.com',
                    icon: LucideIcons.mail,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    validateOnChange: true,
                  ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 24),

                  CustomTextField(
                    label: 'Password',
                    placeholder: 'Enter your password',
                    icon: LucideIcons.lock,
                    controller: _passwordController,
                    isPassword: true,
                    showPassword: _showPassword,
                    onTogglePassword: () =>
                        setState(() => _showPassword = !_showPassword),
                    validateOnChange: true,
                    validator: Validators.validatePassword,
                  ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/forgot-password'),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF39A4E6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 20),

                  // ...existing code...
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Log In',
                    loadingText: 'Logging in...',
                    onPressed: _isFormValid() ? _handleLogin : null,
                    isLoading: _isLoading,
                  ).animate().fadeIn(delay: 800.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 32),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]!,
                            ),
                          ),
                          child: Text(
                            'or sign in with',
                            style: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                          thickness: 1,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 900.ms),

                  const SizedBox(height: 32),

                  // Social Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(LucideIcons.chrome, 'Google'),
                      const SizedBox(width: 24),
                      _buildSocialButton(LucideIcons.facebook, 'Facebook'),
                      const SizedBox(width: 24),
                      _buildSocialButton(
                        LucideIcons.fingerprint,
                        'Fingerprint',
                      ),
                    ],
                  ).animate().fadeIn(delay: 1000.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 40),

                  // Sign Up Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 15,
                          ),
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
                  ).animate().fadeIn(delay: 1100.ms),

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
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 2.seconds,
        );
  }
}
