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
import '../services/profile_state_service.dart';
import '../services/notification_service.dart';
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
  bool _obscurePassword = true;
  String? _alertMessage;
  bool _isAlertError = true;
  String _biometricType = 'Fingerprint';
  IconData _biometricIcon = LucideIcons.fingerprint;

  bool get _isDarkMode =>
      ThemeProvider.of(context)?.themeMode == ThemeMode.dark ?? false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _loadBiometricType();
  }

  Future<void> _loadBiometricType() async {
    try {
      final biometricType = await AuthService.getBiometricType();
      final availableBiometrics = await AuthService.getAvailableBiometrics();

      setState(() {
        _biometricType = biometricType;
        // Keep the fingerprint icon as it was before
        _biometricIcon = LucideIcons.fingerprint;
      });

      print(
        '✅ Loaded biometric type: $biometricType (Available: $availableBiometrics)',
      );
    } catch (e) {
      print('⚠️ Error loading biometric type: $e');
      // Keep default values
    }
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

          // Initialize default profile after login
          try {
            final profileStateService = ProfileStateService();
            await profileStateService.initializeDefaultProfile();
          } catch (e) {
            debugPrint('Error initializing default profile: $e');
          }

          // Initialize Notifications (Register FCM Token)
          try {
            NotificationService().initialize(context);
          } catch (e) {
            debugPrint('Error initializing notifications after login: $e');
          }

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
        final userData = await AuthService.signInWithGoogle();
        if (userData != null && mounted) {
          // Send ID token and access token to backend - backend should check if user exists and login/register accordingly
          // accessToken is needed to get birthday and phone number from Google
          final (success, message) = await AuthApi.loginWithGoogle(
            userData['idToken'] as String,
            accessToken: userData['accessToken'] as String?,
          );

          if (mounted) {
            if (success) {
              // Fetch user profile after successful login
              final (profileSuccess, user, profileMessage) =
                  await AuthApi.getUserProfile();

              if (!mounted) return;

              if (profileSuccess) {
                // Initialize default profile after login
                try {
                  final profileStateService = ProfileStateService();
                  await profileStateService.initializeDefaultProfile();
                } catch (e) {
                  debugPrint('Error initializing default profile: $e');
                }

                // Initialize Notifications (Register FCM Token)
                try {
                  NotificationService().initialize(context);
                } catch (e) {
                  debugPrint('Error initializing notifications after login: $e');
                }

                setState(() {
                  _alertMessage = 'Signed in as ${userData['email']}';
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
                  _alertMessage = 'Signed in as ${userData['email']}';
                  _isAlertError = false;
                  _isLoading = false;
                });
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) Navigator.pushReplacementNamed(context, '/home');
                });
              }
            } else {
              setState(() {
                _alertMessage = message ?? 'Backend login failed';
                _isAlertError = true;
                _isLoading = false;
              });
            }
          }
        } else {
          setState(() => _isLoading = false);
        }
      } else if (provider == 'Facebook') {
        final userData = await AuthService.signInWithFacebook();
        if (userData != null && mounted) {
          // Send access token to backend - backend should check if user exists and login/register accordingly
          final (success, message) = await AuthApi.loginWithFacebook(
            userData['accessToken'] as String,
          );

          if (mounted) {
            if (success) {
              // Fetch user profile after successful login
              final (profileSuccess, user, profileMessage) =
                  await AuthApi.getUserProfile();

              if (!mounted) return;

              if (profileSuccess) {
                // Initialize default profile after login
                try {
                  final profileStateService = ProfileStateService();
                  await profileStateService.initializeDefaultProfile();
                } catch (e) {
                  debugPrint('Error initializing default profile: $e');
                }

                setState(() {
                  _alertMessage =
                      'Signed in with Facebook: ${userData['email'] ?? userData['name']}';
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
                  _alertMessage =
                      'Signed in with Facebook: ${userData['email'] ?? userData['name']}';
                  _isAlertError = false;
                  _isLoading = false;
                });
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) Navigator.pushReplacementNamed(context, '/home');
                });
              }
            } else {
              setState(() {
                _alertMessage = message ?? 'Facebook backend login failed';
                _isAlertError = true;
                _isLoading = false;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _alertMessage = 'Facebook Login cancelled or failed';
              _isAlertError = true;
              _isLoading = false;
            });
          }
        }
      } else if (provider == _biometricType) {
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
      body: Stack(
        children: [
          // Background
          if (isDark) AnimatedBubbleBackground(isDark: isDark),
          if (!isDark)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF39A4E6).withOpacity(0.05),
                      Colors.white,
                    ],
                  ),
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
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF39A4E6).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ).animate().scale(delay: 200.ms),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Sign in to your MediScan account',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  // Login Card
                  Container(
                    width: 450,
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
                        if (_alertMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: AlertBanner(
                              message: _alertMessage!,
                              isError: _isAlertError,
                              autoDismiss: !_isAlertError,
                              onDismiss: () => setState(() => _alertMessage = null),
                            ),
                          ),
                          
                        CustomTextField(
                          label: 'Email Address',
                          placeholder: 'name@example.com',
                          icon: LucideIcons.mail,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                          validateOnChange: true,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        CustomTextField(
                          label: 'Password',
                          placeholder: 'Password',
                          icon: LucideIcons.lock,
                          controller: _passwordController,
                          isPassword: true,
                          showPassword: !_obscurePassword,
                          onTogglePassword: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          validateOnChange: true,
                          validator: Validators.validatePassword,
                        ),
                        
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
                        ),
                        
                        const SizedBox(height: 24),
                        
                        CustomButton(
                          text: 'Sign In',
                          loadingText: 'Signing in...',
                          onPressed: _isFormValid() ? _handleLogin : null,
                          isLoading: _isLoading,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey[300])),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Social Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildModernSocialButton(
                              Image.network(
                                'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                                height: 28,
                                width: 28,
                                errorBuilder: (context, error, stackTrace) => const Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              'Google',
                              null,
                            ),
                            const SizedBox(width: 20),
                            _buildModernSocialButton(LucideIcons.facebook, 'Facebook', Colors.blue),
                            const SizedBox(width: 20),
                            _buildModernSocialButton(_biometricIcon, _biometricType, isDark ? Colors.white : Colors.black87),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms).moveY(begin: 40, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF39A4E6),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSocialButton(dynamic iconOrWidget, String label, Color? iconColor) {
    final isDark = _isDarkMode;
    return InkWell(
      onTap: () => _handleSocialLogin(label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A3450) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: iconOrWidget is Widget
              ? iconOrWidget
              : Icon(
                  iconOrWidget as IconData,
                  color: iconColor,
                  size: 28,
                ),
        ),
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
