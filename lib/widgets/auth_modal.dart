import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'custom_text_field.dart';
import 'custom_button.dart';
import 'alert_banner.dart';
import '../utils/validators.dart';
import '../services/auth_service.dart';
import '../services/auth_api.dart';
import '../services/web_authn_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_toggle.dart';

class AuthModal extends StatefulWidget {
  final bool initialIsLogin;
  const AuthModal({super.key, this.initialIsLogin = true});

  static void show(BuildContext context, {bool isLogin = true}) {
    final themeProvider = ThemeProvider.of(context);
    final bool isDark = themeProvider?.themeMode == ThemeMode.dark;

    showDialog(
      context: context,
      barrierColor: isDark 
          ? Colors.black.withOpacity(0.85) 
          : Colors.black.withOpacity(0.4),
      builder: (context) => AuthModal(initialIsLogin: isLogin),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  late bool _isLogin;
  bool _isLoading = false;
  String? _alertMessage;
  bool _isAlertError = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _dateOfBirth;
  bool _agreedToTerms = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
    _loadSavedEmail();
    
    // Listeners for real-time validation (optional but good for parity)
    _emailController.addListener(_clearAlert);
    _passwordController.addListener(_clearAlert);
    _nameController.addListener(_clearAlert);
    _phoneController.addListener(_clearAlert);
    _confirmPasswordController.addListener(_clearAlert);
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null && mounted) {
      _emailController.text = email;
    }
  }

  void _clearAlert() {
    if (_alertMessage != null) {
      setState(() => _alertMessage = null);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSignupFormValid() {
    final nameError = Validators.validateName(_nameController.text);
    final emailError = Validators.validateEmail(_emailController.text);
    final passwordError = Validators.validatePassword(_passwordController.text);
    final confirmError = Validators.validateConfirmPassword(
      _confirmPasswordController.text,
      _passwordController.text,
    );
    final dobError = Validators.validateDateOfBirth(_dateOfBirth);

    return nameError == null && 
           emailError == null && 
           passwordError == null && 
           confirmError == null && 
           dobError == null &&
           _agreedToTerms;
  }

  Future<void> _handleLogin() async {
    final emailError = Validators.validateEmail(_emailController.text);
    if (emailError != null || _passwordController.text.isEmpty) {
      setState(() {
        _alertMessage = emailError ?? 'Password is required';
        _isAlertError = true;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await AuthApi.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.$1) {
        // Fetch user profile after successful login (parity with mobile)
        final (profileSuccess, user, profileMessage) = await AuthApi.getUserProfile();
        
        if (!mounted) return;

        setState(() {
          _alertMessage = 'Login successful!';
          _isAlertError = false;
          _isLoading = false;
        });
        
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        });
      } else {
        setState(() {
          _alertMessage = result.$2 ?? 'Login failed';
          _isAlertError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _alertMessage = 'Login error: $e';
        _isAlertError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignup() async {
    // Parity validation
    final nameError = Validators.validateName(_nameController.text);
    final emailError = Validators.validateEmail(_emailController.text);
    final phoneError = Validators.validatePhone(_phoneController.text);
    final dobError = Validators.validateDateOfBirth(_dateOfBirth);
    final passwordError = Validators.validatePassword(_passwordController.text);
    final confirmError = Validators.validateConfirmPassword(
      _confirmPasswordController.text,
      _passwordController.text,
    );

    if (nameError != null || emailError != null || dobError != null || passwordError != null || confirmError != null) {
      setState(() {
        _alertMessage = nameError ?? emailError ?? dobError ?? passwordError ?? confirmError;
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

    if (success) {
      setState(() {
        _alertMessage = 'Account created successfully!';
        _isAlertError = false;
        _isLoading = false;
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/verification', arguments: {
            'email': _emailController.text,
            'isPasswordReset': false,
          });
        }
      });
    } else {
      setState(() {
        _alertMessage = message ?? 'Registration failed';
        _isAlertError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    try {
      if (provider == 'Google') {
        final userData = await AuthService.signInWithGoogle();
        if (userData != null && mounted) {
          final email = userData['email'] as String?;
          
          // If in signup mode, check if account already exists
          if (!_isLogin && email != null) {
            final accountExists = await AuthApi.hasGoogleAccount(email);
            if (accountExists) {
              // Account already exists, show message and switch to login mode
              setState(() {
                _alertMessage = 'This Google account is already registered. Please log in instead.';
                _isAlertError = true;
                _isLoading = false;
                _isLogin = true; // Switch to login mode
              });
              return;
            }
          }
          
          // Send ID token to backend - backend should check if user exists and login/register accordingly
          final (success, message) = await AuthApi.loginWithGoogle(userData['idToken'] as String);
          if (mounted) {
            if (success) {
              // Fetch user profile after successful login/registration
              final (profileSuccess, _, profileMessage) = await AuthApi.getUserProfile();
              if (profileSuccess) {
                Navigator.pushReplacementNamed(context, '/home');
              } else {
                // Still navigate even if profile fetch fails
                print('Warning: Profile fetch failed: $profileMessage');
                Navigator.pushReplacementNamed(context, '/home');
              }
            } else {
              setState(() {
                _alertMessage = message ?? 'Google sync failed';
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
          
          // If in signup mode, check if account already exists
          if (!_isLogin && email != null) {
            final accountExists = await AuthApi.hasFacebookAccount(email);
            if (accountExists) {
              // Account already exists, show message and switch to login mode
              setState(() {
                _alertMessage = 'This Facebook account is already registered. Please log in instead.';
                _isAlertError = true;
                _isLoading = false;
                _isLogin = true; // Switch to login mode
              });
              return;
            }
          }
          
          // Send access token to backend - backend should check if user exists and login/register accordingly
          final (success, message) = await AuthApi.loginWithFacebook(userData['accessToken'] as String);
          if (mounted) {
            if (success) {
              // Fetch user profile after successful login/registration
              final (profileSuccess, _, profileMessage) = await AuthApi.getUserProfile();
              if (profileSuccess) {
                Navigator.pushReplacementNamed(context, '/home');
              } else {
                // Still navigate even if profile fetch fails
                print('Warning: Profile fetch failed: $profileMessage');
                Navigator.pushReplacementNamed(context, '/home');
              }
            } else {
              setState(() {
                _alertMessage = message ?? 'Facebook sync failed';
                _isAlertError = true;
                _isLoading = false;
              });
            }
          }
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _alertMessage = 'Auth error: $e';
          _isAlertError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleWebAuthnLogin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || Validators.validateEmail(email) != null) {
      setState(() {
        _alertMessage = 'Please enter a valid email to use Passkey';
        _isAlertError = true;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('🔐 Starting WebAuthn login for email: $email');
      
      // 1. Get Login Options from backend
      print('🔵 Step 1: Getting login options from backend...');
      final (optionsSuccess, options, optionsMessage) = await AuthApi.getWebAuthnLoginOptions(email);
      
      if (!optionsSuccess || options == null) {
        print('❌ Failed to get login options: $optionsMessage');
        throw optionsMessage ?? 'Failed to get login options';
      }

      print('✅ Login options received');

      // 2. Invoke Browser API (Face ID/Fingerprint)
      print('🔵 Step 2: Invoking browser biometric authentication...');
      final assertion = await WebAuthnService.getAssertion(options);
      
      if (assertion == null) {
        print('❌ Biometric authentication cancelled or failed');
        throw 'Biometric authentication cancelled or failed';
      }

      print('✅ Biometric authentication successful');

      // 3. Verify Assertion with backend
      print('🔵 Step 3: Verifying assertion with backend...');
      final (verifySuccess, verifyMessage) = await AuthApi.verifyWebAuthnLogin(
        email: email, 
        assertion: assertion,
      );

      if (!mounted) return;

      if (verifySuccess) {
        // Fetch user profile after successful login
        print('🔵 Fetching user profile...');
        final (profileSuccess, _, profileMessage) = await AuthApi.getUserProfile();
        
        if (profileSuccess) {
          print('✅ WebAuthn login completed successfully');
          setState(() {
            _alertMessage = 'Biometric login successful!';
            _isAlertError = false;
            _isLoading = false;
          });
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) Navigator.pushReplacementNamed(context, '/home');
          });
        } else {
          print('⚠️ Profile fetch failed: $profileMessage');
          // Still navigate even if profile fetch fails
          setState(() {
            _alertMessage = 'Biometric login successful!';
            _isAlertError = false;
            _isLoading = false;
          });
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) Navigator.pushReplacementNamed(context, '/home');
          });
        }
      } else {
        print('❌ Verification failed: $verifyMessage');
        throw verifyMessage ?? 'Verification failed';
      }
    } catch (e) {
      print('❌ WebAuthn login error: $e');
      if (mounted) {
        setState(() {
          _alertMessage = e.toString();
          _isAlertError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final bool isDark = themeProvider?.themeMode == ThemeMode.dark;
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 900;
    
    // Theme-aware colors
    final Color modalBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final Color subTextColor = isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF64748B);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: isDesktop ? 1000 : math.min(size.width - 40, 500.0),
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 20),
          constraints: BoxConstraints(
            maxHeight: size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: modalBgColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1),
                blurRadius: 50,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. FORM SIDE (Behind Visual initially)
              Align(
                alignment: isDesktop ? Alignment.centerRight : Alignment.center,
                child: SizedBox(
                  width: isDesktop ? (1000 * 12 / 23) : double.infinity,
                  child: Column(
                    children: [
                      _buildHeader(isDark),
                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                      if (_alertMessage != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
                          child: AlertBanner(
                            message: _alertMessage!,
                            isError: _isAlertError,
                            onDismiss: () => setState(() => _alertMessage = null),
                          ),
                        ),
                      Flexible(
                        child: Scrollbar(
                          controller: _scrollController,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(40, 30, 40, 40),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _isLogin 
                                ? _buildLoginForm(isDark, textColor, subTextColor, !isDesktop) 
                                : _buildSignupForm(isDark, textColor, subTextColor, !isDesktop),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate()
                   .fadeIn(duration: 400.ms, delay: 400.ms)
                   .slideX(begin: -0.05, end: 0, duration: 600.ms, delay: 400.ms, curve: Curves.easeOut), // "Uncover" effect
                ),
              ),

              // 2. VISUAL SIDE (Top Layer, slides to reveal)
              if (isDesktop)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 1000 * 11 / 23,
                  child: _buildVisualSide(isDark)
                    .animate()
                    .moveX(
                      begin: 1.1, // Starts slightly over the form side
                      end: 0, 
                      duration: 900.ms, 
                      curve: Curves.easeInOutQuart,
                    )
                    .fadeIn(duration: 300.ms),
                ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildVisualSide(bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: AssetImage('assets/images/web_intro_3.png'),
          fit: BoxFit.cover,
          opacity: 0.6,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(50),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [
              const Color(0xFF39A4E6).withOpacity(0.7),
              (isDark ? Colors.black : const Color(0xFF0F172A)).withOpacity(0.4),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'AI-POWERED MEDICINE',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'Intelligent\nHealthcare.',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.bold,
                height: 0.95,
                letterSpacing: -2.0,
              ),
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, duration: 500.ms),
            const SizedBox(height: 24),
            Text(
              'Experience the future of personal medicine with AI-driven insights and total record security.',
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.95),
                fontSize: 19,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, duration: 500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _tabItem('Login', _isLogin, isDark, () => setState(() => _isLogin = true)),
          const SizedBox(width: 12),
          _tabItem('Sign Up', !_isLogin, isDark, () => setState(() => _isLogin = false)),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.x, color: isDark ? Colors.white38 : Colors.black26, size: 22),
            splashRadius: 25,
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String title, bool isActive, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF39A4E6).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            color: isActive 
              ? const Color(0xFF39A4E6) 
              : (isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.4)),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isDark, Color textColor, Color subTextColor, bool isMobile) {
    return Column(
      key: const ValueKey('login_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back', 
          style: GoogleFonts.outfit(
            color: textColor, 
            fontSize: 40, 
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          )
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to manage your health records.', 
          style: GoogleFonts.outfit(
            color: subTextColor, 
            fontSize: 16,
          )
        ),
        const SizedBox(height: 35),
        CustomTextField(
          label: 'Email Address',
          placeholder: 'example@mediscan.com',
          icon: LucideIcons.mail,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
          validateOnChange: true,
          labelColor: textColor,
          hintColor: Colors.black54,
        ),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Password',
          placeholder: 'Enter your password',
          icon: LucideIcons.lock,
          controller: _passwordController,
          isPassword: true,
          showPassword: !_obscurePassword,
          onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
          validator: Validators.validatePassword,
          labelColor: textColor,
          hintColor: Colors.black54,
        ),
        const SizedBox(height: 15),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
            child: Text('Forgot Password?', style: GoogleFonts.outfit(color: const Color(0xFF39A4E6), fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 35),
        CustomButton(
          text: 'Login Now',
          loadingText: 'Signing in...',
          isLoading: _isLoading,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 35),
        _socialSection(isDark, isMobile),
      ],
    );
  }

  Widget _buildSignupForm(bool isDark, Color textColor, Color subTextColor, bool isMobile) {
    return Column(
      key: const ValueKey('signup_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Account', 
          style: GoogleFonts.outfit(
            color: textColor, 
            fontSize: 40, 
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          )
        ),
        const SizedBox(height: 8),
        Text(
          'Join MediScan for real-time health insights.', 
          style: GoogleFonts.outfit(
            color: subTextColor, 
            fontSize: 16,
          )
        ),
        const SizedBox(height: 35),
        
        CustomTextField(
          label: 'Full Name *',
          placeholder: 'Enter your full name',
          icon: LucideIcons.user,
          controller: _nameController,
          validator: Validators.validateName,
          labelColor: textColor,
          hintColor: Colors.black54,
        ),
        const SizedBox(height: 24),
        
        CustomTextField(
          label: 'Email Address *',
          placeholder: 'example@mediscan.com',
          icon: LucideIcons.mail,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
          labelColor: textColor,
          hintColor: Colors.black54,
        ),
        const SizedBox(height: 24),

        CustomTextField(
          label: 'Phone Number (Optional)',
          placeholder: '+1 (234) 567-8900',
          icon: LucideIcons.phone,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: Validators.validatePhone,
          labelColor: textColor,
          hintColor: Colors.black54,
        ),
        const SizedBox(height: 24),

        _buildDatePicker(isDark, textColor),
        const SizedBox(height: 24),

        CustomTextField(
          label: 'Password *',
          placeholder: 'Create a strong password',
          icon: LucideIcons.lock,
          controller: _passwordController,
          isPassword: true,
          showPassword: !_obscurePassword,
          onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
          validator: Validators.validatePassword,
          labelColor: textColor,
          hintColor: Colors.black54,
        ),
        const SizedBox(height: 24),

        CustomTextField(
          label: 'Confirm Password *',
          placeholder: 'Re-enter your password',
          icon: LucideIcons.lock,
          controller: _confirmPasswordController,
          isPassword: true,
          showPassword: !_obscureConfirmPassword,
          onTogglePassword: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          validator: (val) => Validators.validateConfirmPassword(val, _passwordController.text),
          labelColor: textColor,
          hintColor: Colors.black54,
        ),
        const SizedBox(height: 32),

        _buildTermsCheckbox(isDark),
        const SizedBox(height: 32),

        CustomButton(
          text: 'Complete Signup',
          loadingText: 'Creating account...',
          isLoading: _isLoading,
          onPressed: _handleSignup,
        ),
        const SizedBox(height: 35),
        _socialSection(isDark, isMobile),
      ],
    );
  }

  Widget _buildDatePicker(bool isDark, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth *', style: GoogleFonts.outfit(color: labelColor, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final lastDate = DateTime(now.year - 13);
            final picked = await showDatePicker(
              context: context,
              initialDate: _dateOfBirth ?? lastDate,
              firstDate: DateTime(now.year - 120),
              lastDate: lastDate,
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.dark(primary: Color(0xFF39A4E6), surface: Color(0xFF1E1E1E)),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _dateOfBirth = picked);
          },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.calendar, color: Color(0xFF39A4E6), size: 20),
                const SizedBox(width: 15),
                Text(
                  _dateOfBirth == null 
                    ? 'Select your birthday' 
                    : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                  style: GoogleFonts.outfit(
                    color: _dateOfBirth == null 
                      ? (isDark ? Colors.white38 : Colors.black38) 
                      : (isDark ? Colors.white : Colors.black87), 
                    fontSize: 16
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
      children: [
        Theme(
          data: ThemeData(unselectedWidgetColor: isDark ? Colors.white24 : Colors.black26),
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            activeColor: const Color(0xFF39A4E6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        Expanded(
          child: Wrap(
            children: [
              Text('I agree to the ', style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
              Text('Terms & Conditions', style: GoogleFonts.outfit(color: const Color(0xFF39A4E6), fontSize: 14, fontWeight: FontWeight.bold)),
              Text(' and ', style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
              Text('Privacy Policy', style: GoogleFonts.outfit(color: const Color(0xFF39A4E6), fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialSection(bool isDark, bool isMobile) {
    final actionText = _isLogin ? 'Sign in' : 'Sign up';
    final dividerColor = isDark ? Colors.white10 : Colors.black.withOpacity(0.05);
    
    // Stack vertically on mobile or very small widths
    final bool stackButtons = isMobile;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR CONTINUE WITH', style: GoogleFonts.outfit(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            Expanded(child: Divider(color: dividerColor)),
          ],
        ),
        const SizedBox(height: 30),
        if (stackButtons)
          Column(
            children: [
              _socialBtn(LucideIcons.chrome, '$actionText with Google', isDark, _isLoading ? null : () => _handleSocialLogin('Google')),
              const SizedBox(height: 16),
              _socialBtn(LucideIcons.facebook, '$actionText with Facebook', isDark, _isLoading ? null : () => _handleSocialLogin('Facebook')),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _socialBtn(LucideIcons.chrome, 'Google', isDark, _isLoading ? null : () => _handleSocialLogin('Google'))),
              const SizedBox(width: 20),
              Expanded(child: _socialBtn(LucideIcons.facebook, 'Facebook', isDark, _isLoading ? null : () => _handleSocialLogin('Facebook'))),
            ],
          ),
      ],
    );
  }

  Widget _socialBtn(IconData icon, String label, bool isDark, VoidCallback? onTap) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: 200.ms,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isHovered 
                    ? const Color(0xFF39A4E6).withOpacity(0.5) 
                    : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
                  width: isHovered ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(15),
                color: isHovered 
                  ? const Color(0xFF39A4E6).withOpacity(0.05) 
                  : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon, 
                    color: isHovered ? const Color(0xFF39A4E6) : (isDark ? Colors.white : Colors.black87), 
                    size: 20
                  ),
                  const SizedBox(width: 15),
                  Flexible(
                    child: Text(
                      label, 
                      style: GoogleFonts.outfit(
                        color: isHovered ? (isDark ? Colors.white : const Color(0xFF39A4E6)) : (isDark ? Colors.white70 : Colors.black87), 
                        fontWeight: FontWeight.w600, 
                        fontSize: 16
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
