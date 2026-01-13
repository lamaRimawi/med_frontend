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
import '../services/notification_service.dart';

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
  String _selectedCountryCode = '+970';
  
  final List<Map<String, String>> _countryCodes = [
    {'code': '+970', 'flag': '🇵🇸', 'name': 'Palestine'},
    {'code': '+962', 'flag': '🇯🇴', 'name': 'Jordan'},
    {'code': '+20', 'flag': '🇪🇬', 'name': 'Egypt'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'Saudi Arabia'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
    {'code': '+965', 'flag': '🇰🇼', 'name': 'Kuwait'},
    {'code': '+974', 'flag': '🇶🇦', 'name': 'Qatar'},
    {'code': '+973', 'flag': '🇧🇭', 'name': 'Bahrain'},
    {'code': '+968', 'flag': '🇴🇲', 'name': 'Oman'},
    {'code': '+961', 'flag': '🇱🇧', 'name': 'Lebanon'},
    {'code': '+964', 'flag': '🇮🇶', 'name': 'Iraq'},
    {'code': '+963', 'flag': '🇸🇾', 'name': 'Syria'},
    {'code': '+967', 'flag': '🇾🇪', 'name': 'Yemen'},
    {'code': '+212', 'flag': '🇲🇦', 'name': 'Morocco'},
    {'code': '+213', 'flag': '🇩🇿', 'name': 'Algeria'},
    {'code': '+216', 'flag': '🇹🇳', 'name': 'Tunisia'},
    {'code': '+218', 'flag': '🇱🇾', 'name': 'Libya'},
    {'code': '+249', 'flag': '🇸🇩', 'name': 'Sudan'},
    {'code': '+90', 'flag': '🇹🇷', 'name': 'Turkey'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA/Canada'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'UK'},
    {'code': '+49', 'flag': '🇩🇪', 'name': 'Germany'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
    {'code': '+39', 'flag': '🇮🇹', 'name': 'Italy'},
    {'code': '+34', 'flag': '🇪🇸', 'name': 'Spain'},
    {'code': '+86', 'flag': '🇨🇳', 'name': 'China'},
    {'code': '+91', 'flag': '🇮🇳', 'name': 'India'},
    {'code': '+81', 'flag': '🇯🇵', 'name': 'Japan'},
    {'code': '+61', 'flag': '🇦🇺', 'name': 'Australia'},
    {'code': '+55', 'flag': '🇧🇷', 'name': 'Brazil'},
  ];

  DateTime? _dateOfBirth;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _agreedToTerms = false;
  String? _alertMessage;
  bool _isAlertError = true;

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

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
      phone: '$_selectedCountryCode${_phoneController.text.trim()}',
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
        final userData = await AuthService.signInWithGoogle();
        if (userData != null && mounted) {
          final email = userData['email'] as String?;
          
          // Check if this Google account already exists
          if (email != null) {
            final accountExists = await AuthApi.hasGoogleAccount(email);
            if (accountExists) {
              // Account already exists, redirect to login
              setState(() {
                _alertMessage = 'This Google account is already registered. Please log in instead.';
                _isAlertError = true;
                _isLoading = false;
              });
              
              // Navigate to login screen after a delay
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              });
              return;
            }
          }
          
          // Send ID token and access token to backend - backend should check if user exists and login/register accordingly
          // accessToken is needed to get birthday and phone number from Google
          final (success, message) = await AuthApi.loginWithGoogle(
            userData['idToken'] as String,
            accessToken: userData['accessToken'] as String?,
          );
          
          if (mounted) {
            if (success) {
              // Fetch user profile after successful login/registration
              final (profileSuccess, user, profileMessage) = await AuthApi.getUserProfile();
              
              if (!mounted) return;
              
              if (profileSuccess) {
                // Initialize Notifications (Register FCM Token)
                try {
                  NotificationService().initialize(context);
                } catch (e) {
                  debugPrint('Error initializing notifications after social signup: $e');
                }
                setState(() {
                  _alertMessage = 'Account created and logged in with Google as ${userData['email']}';
                  _isAlertError = false;
                  _isLoading = false;
                });
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) Navigator.pushReplacementNamed(context, '/home');
                });
              } else {
                // Login/registration succeeded but profile fetch failed - still navigate but warn
                print('Warning: Profile fetch failed: $profileMessage');
                setState(() {
                  _alertMessage = 'Account created and logged in with Google as ${userData['email']}';
                  _isAlertError = false;
                  _isLoading = false;
                });
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) Navigator.pushReplacementNamed(context, '/home');
                });
              }
            } else {
              setState(() {
                _alertMessage = message ?? 'Backend synchronization failed';
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
          final email = userData['email'] as String?;
          
          // Check if this Facebook account already exists
          if (email != null) {
            final accountExists = await AuthApi.hasFacebookAccount(email);
            if (accountExists) {
              // Account already exists, redirect to login
              setState(() {
                _alertMessage = 'This Facebook account is already registered. Please log in instead.';
                _isAlertError = true;
                _isLoading = false;
              });
              
              // Navigate to login screen after a delay
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              });
              return;
            }
          }
          
          // Send access token to backend - backend should check if user exists and login/register accordingly
          final (success, message) =
              await AuthApi.loginWithFacebook(userData['accessToken'] as String);

          if (mounted) {
            if (success) {
              // Fetch user profile after successful login/registration
              final (profileSuccess, user, profileMessage) = await AuthApi.getUserProfile();
              
              if (!mounted) return;
              
              if (profileSuccess) {
                // Initialize Notifications (Register FCM Token)
                try {
                  NotificationService().initialize(context);
                } catch (e) {
                  debugPrint('Error initializing notifications after social signup: $e');
                }
                setState(() {
                  _alertMessage =
                      'Account created and logged in with Facebook: ${userData['email'] ?? userData['name']}';
                  _isAlertError = false;
                  _isLoading = false;
                });

                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) Navigator.pushReplacementNamed(context, '/home');
                });
              } else {
                // Login/registration succeeded but profile fetch failed - still navigate but warn
                print('Warning: Profile fetch failed: $profileMessage');
                setState(() {
                  _alertMessage =
                      'Account created and logged in with Facebook: ${userData['email'] ?? userData['name']}';
                  _isAlertError = false;
                  _isLoading = false;
                });
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) Navigator.pushReplacementNamed(context, '/home');
                });
              }
            } else {
              setState(() {
                _alertMessage = message ?? 'Facebook backend synchronization failed';
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
    // Glass effect colors - Only for Dark Mode
    final cardColor = isDark 
        ? const Color(0xFF122640).withOpacity(0.9) 
        : Colors.white;
    final borderColor = isDark 
        ? Colors.white.withOpacity(0.1) 
        : Colors.transparent;
    
    // Background color
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
                  const SizedBox(height: 40), // Spacing for back button if needed
                  
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
                    'Create Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Join MediScan today',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  // Signup Card
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
                            label: 'Full Name',
                            placeholder: 'Enter your full name',
                            icon: LucideIcons.user,
                            controller: _nameController,
                            validator: Validators.validateName,
                         ),
                         const SizedBox(height: 20),
                         CustomTextField(
                            label: 'Email Address',
                            placeholder: 'name@example.com',
                            icon: LucideIcons.mail,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                         ),
                         const SizedBox(height: 20),
                         
                         // Phone Number Field with Country Code
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               'Phone Number',
                               style: TextStyle(
                                 color: isDark ? Colors.white : const Color(0xFF1F2937),
                                 fontWeight: FontWeight.bold,
                                 fontSize: 14,
                               ),
                             ),
                             const SizedBox(height: 8),
                             Row(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 // Country Code Dropdown
                                 Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                   decoration: BoxDecoration(
                                     color: isDark
                                         ? Colors.white.withOpacity(0.08)
                                         : const Color(0xFFF9FAFB).withValues(alpha: 0.8),
                                     borderRadius: BorderRadius.circular(16),
                                     border: Border.all(
                                       color: isDark ? Colors.white.withOpacity(0.2) : Colors.black12,
                                       width: 1.5,
                                     ),
                                   ),
                                   child: DropdownButtonHideUnderline(
                                     child: DropdownButton<String>(
                                       value: _selectedCountryCode,
                                       dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                                       icon: Icon(
                                         LucideIcons.chevronDown,
                                         color: isDark ? Colors.white70 : Colors.grey[600],
                                         size: 20,
                                       ),
                                       items: _countryCodes.map((country) {
                                         return DropdownMenuItem<String>(
                                           value: country['code'],
                                           child: Row(
                                             children: [
                                               Text(
                                                 country['flag']!,
                                                 style: const TextStyle(fontSize: 24),
                                               ),
                                               const SizedBox(width: 8),
                                               Text(
                                                 country['code']!,
                                                 style: TextStyle(
                                                   color: isDark ? Colors.white : const Color(0xFF1F2937),
                                                   fontWeight: FontWeight.w500,
                                                 ),
                                               ),
                                             ],
                                           ),
                                         );
                                       }).toList(),
                                       onChanged: (value) {
                                         if (value != null) {
                                           setState(() => _selectedCountryCode = value);
                                         }
                                       },
                                     ),
                                   ),
                                 ),
                                 const SizedBox(width: 12),
                                 // Phone Number Input
                                 Expanded(
                                   child: CustomTextField(
                                     label: '',
                                     placeholder: '(234) 567-8900',
                                     icon: LucideIcons.phone,
                                     controller: _phoneController,
                                     keyboardType: TextInputType.phone,
                                     validator: Validators.validatePhone,
                                   ),
                                 ),
                               ],
                             ),
                           ],
                         ),
                         const SizedBox(height: 20),
                         
                         // Date of Birth (styled to match CustomTextField)
                         _buildDatePicker(isDark),

                         const SizedBox(height: 20),
                         CustomTextField(
                            label: 'Password',
                            placeholder: 'Create a password',
                            icon: LucideIcons.lock,
                            controller: _passwordController,
                            isPassword: true,
                            showPassword: _showPassword,
                            onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                            validator: Validators.validatePassword,
                            validateOnChange: true,
                         ),
                         const SizedBox(height: 20),
                         CustomTextField(
                            label: 'Confirm Password',
                            placeholder: 'Confirm your password',
                            icon: LucideIcons.lock,
                            controller: _confirmPasswordController,
                            isPassword: true,
                            showPassword: _showConfirmPassword,
                            onTogglePassword: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                            validator: (value) => Validators.validateConfirmPassword(value, _passwordController.text),
                         ),
                         
                         const SizedBox(height: 24),
                         
                         // Terms
                         _buildTermsCheckbox(isDark),

                         const SizedBox(height: 24),
                         
                         CustomButton(
                            text: 'Sign Up',
                            loadingText: 'Creating account...',
                            onPressed: _isFormValid() ? _handleSignup : null,
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
                            ],
                         ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms).moveY(begin: 40, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Sign In',
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

  Widget _buildDatePicker(bool isDark) {
    final hasError = Validators.validateDateOfBirth(_dateOfBirth) != null && _dateOfBirth == null; // Logic tweak: only show error if attempted or null? Validator logic handled in _isFormValid and display.
    // The original code showed error if != null. Let's stick to that logic but style it better.
    final errorText = Validators.validateDateOfBirth(_dateOfBirth);
    final showError = errorText != null && _dateOfBirth != null; // Show error if date selected is invalid (e.g. too young)? Or if null and validated?
    // Wait, previous code was: border color if validateDateOfBirth != null. 
    // Validators.validateDateOfBirth returns "Age must be between..." or "Required" if null.
    // So if it returns string, we show error.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: TextStyle(
            color: errorText != null && _dateOfBirth != null // Only show red label if explicitly invalid? Original didn't do this. Let's keep it simple.
                ? const Color(0xFFEF4444)
                : (isDark ? Colors.white : const Color(0xFF1F2937)),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFF9FAFB).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: errorText != null && _dateOfBirth == null // Only show error border if validation fails?
                    ? (isDark ? Colors.white.withOpacity(0.2) : Colors.black12) // Default if null (haven't touched yet?)
                    // Actually let's use the logic: if errorText is not null, it might be "Required". 
                    // But we don't want to show red immediately.
                    // The previous code showed red if validateDateOfBirth != null. That means it was red by default?
                    // Validators.validateDateOfBirth returns "Date of birth is required" if null.
                    // So it was always red? Let's check previous code.
                    // Previous code: color: Validators.validateDateOfBirth(_dateOfBirth) != null ? Colors.red : ...
                    // Yes, it seems it was always red if null. That's annoying.
                    // But wait, `_isFormValid` is called on submit.
                    // Let's improve this: only show red if `_alertMessage` is not null (meaning submit attempted) AND error exists?
                    // Or just keep it simple.
                    : (errorText != null ? const Color(0xFFEF4444) : (isDark ? Colors.white.withOpacity(0.2) : Colors.black12)),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (errorText != null ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF)).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.calendar,
                    color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dateOfBirth == null
                        ? 'Select your date of birth'
                        : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}',
                    style: TextStyle(
                      color: _dateOfBirth == null 
                          ? (isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey[500]) 
                          : (isDark ? Colors.white : const Color(0xFF1F2937)),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTermsCheckbox(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
            activeColor: const Color(0xFF39A4E6),
            side: BorderSide(
              color: isDark ? Colors.white54 : Colors.grey[400]!,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'I agree to the ',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Terms and Conditions',
                  style: TextStyle(
                    color: Color(0xFF39A4E6),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                ' and ',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Color(0xFF39A4E6),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
}
