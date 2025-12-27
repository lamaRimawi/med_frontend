import 'package:flutter/material.dart';
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

class AuthModal extends StatefulWidget {
  final bool initialIsLogin;
  const AuthModal({super.key, this.initialIsLogin = true});

  static void show(BuildContext context, {bool isLogin = true}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
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
    
    // Listeners for real-time validation (optional but good for parity)
    _emailController.addListener(_clearAlert);
    _passwordController.addListener(_clearAlert);
    _nameController.addListener(_clearAlert);
    _phoneController.addListener(_clearAlert);
    _confirmPasswordController.addListener(_clearAlert);
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
          final (success, message) = await AuthApi.loginWithGoogle(userData['idToken']);
          if (mounted) {
            if (success) {
              Navigator.pushReplacementNamed(context, '/home');
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
          final (success, message) = await AuthApi.loginWithFacebook(userData['accessToken']);
          if (mounted) {
            if (success) {
              Navigator.pushReplacementNamed(context, '/home');
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
      // 1. Get Login Options from backend
      final (optionsSuccess, options, optionsMessage) = await AuthApi.getWebAuthnLoginOptions(email);
      
      if (!optionsSuccess || options == null) {
        throw optionsMessage ?? 'Failed to get login options';
      }

      // 2. Invoke Browser API
      final assertion = await WebAuthnService.getAssertion(options);
      
      if (assertion == null) {
        throw 'Biometric authentication cancelled or failed';
      }

      // 3. Verify Assertion with backend
      final (verifySuccess, verifyMessage) = await AuthApi.verifyWebAuthnLogin(
        email: email, 
        assertion: assertion,
      );

      if (!mounted) return;

      if (verifySuccess) {
        setState(() {
          _alertMessage = 'Biometric login successful!';
          _isAlertError = false;
          _isLoading = false;
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        });
      } else {
        throw verifyMessage ?? 'Verification failed';
      }
    } catch (e) {
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
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 550,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2C), // Deep navy/slate instead of plain dark grey
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 50,
                offset: const Offset(0, 25),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const Divider(height: 1, color: Colors.white10),
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
                child: Theme(
                  data: Theme.of(context).copyWith(
                    scrollbarTheme: ScrollbarThemeData(
                      thumbColor: WidgetStateProperty.all(const Color(0xFF39A4E6)),
                      trackColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
                      thickness: WidgetStateProperty.all(10.0),
                      radius: const Radius.circular(10),
                      thumbVisibility: WidgetStateProperty.all(true),
                    ),
                  ),
                  child: Scrollbar(
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(40, 30, 40, 50),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isLogin ? _buildLoginForm() : _buildSignupForm(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _tabItem('Login', _isLogin, () => setState(() => _isLogin = true)),
          const SizedBox(width: 12),
          _tabItem('Sign Up', !_isLogin, () => setState(() => _isLogin = false)),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.x, color: Colors.white38, size: 22),
            splashRadius: 25,
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String title, bool isActive, VoidCallback onTap) {
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
            color: isActive ? const Color(0xFF39A4E6) : Colors.white.withOpacity(0.9),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome Back', style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('Sign in to continue managing your health records.', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 17)),
        const SizedBox(height: 35),
        CustomTextField(
          label: 'Email Address',
          placeholder: 'example@mediscan.com',
          icon: LucideIcons.mail,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
          validateOnChange: true,
          labelColor: Colors.white,
          hintColor: Colors.black,
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
          labelColor: Colors.white,
          hintColor: Colors.black,
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
        if (WebAuthnService.isSupported) ...[
          const SizedBox(height: 16),
          _socialBtn(LucideIcons.fingerprint, 'Sign in with Passkey', _handleWebAuthnLogin),
        ],
        const SizedBox(height: 35),
        _socialSection(),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      key: const ValueKey('signup_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Create Account', style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('Join MediScan for real-time health insights.', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 17)),
        const SizedBox(height: 35),
        
        CustomTextField(
          label: 'Full Name *',
          placeholder: 'Enter your full name',
          icon: LucideIcons.user,
          controller: _nameController,
          validator: Validators.validateName,
          labelColor: Colors.white,
          hintColor: Colors.black,
        ),
        const SizedBox(height: 24),
        
        CustomTextField(
          label: 'Email Address *',
          placeholder: 'example@mediscan.com',
          icon: LucideIcons.mail,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
          labelColor: Colors.white,
          hintColor: Colors.black,
        ),
        const SizedBox(height: 24),

        CustomTextField(
          label: 'Phone Number (Optional)',
          placeholder: '+1 (234) 567-8900',
          icon: LucideIcons.phone,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: Validators.validatePhone,
          labelColor: Colors.white,
          hintColor: Colors.black,
        ),
        const SizedBox(height: 24),

        _buildDatePicker(),
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
          labelColor: Colors.white,
          hintColor: Colors.black,
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
          labelColor: Colors.white,
          hintColor: Colors.black,
        ),
        const SizedBox(height: 32),

        _buildTermsCheckbox(),
        const SizedBox(height: 32),

        CustomButton(
          text: 'Complete Signup',
          loadingText: 'Creating account...',
          isLoading: _isLoading,
          onPressed: _handleSignup,
        ),
        const SizedBox(height: 35),
        _socialSection(),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth *', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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
              color: const Color(0xFFF9FAFB).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, color: Color(0xFF39A4E6), size: 20),
                const SizedBox(width: 15),
                Text(
                  _dateOfBirth == null 
                    ? 'Select your birthday' 
                    : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                  style: GoogleFonts.outfit(color: _dateOfBirth == null ? Colors.black.withValues(alpha: 0.7) : Colors.black, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Theme(
          data: ThemeData(unselectedWidgetColor: Colors.white24),
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
              Text('I agree to the ', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
              Text('Terms & Conditions', style: GoogleFonts.outfit(color: const Color(0xFF39A4E6), fontSize: 14, fontWeight: FontWeight.bold)),
              Text(' and ', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
              Text('Privacy Policy', style: GoogleFonts.outfit(color: const Color(0xFF39A4E6), fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.05))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR CONTINUE WITH', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.05))),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(child: _socialBtn(LucideIcons.chrome, 'Google', () => _handleSocialLogin('Google'))),
            const SizedBox(width: 20),
            Expanded(child: _socialBtn(LucideIcons.facebook, 'Facebook', () => _handleSocialLogin('Facebook'))),
          ],
        ),
      ],
    );
  }

  Widget _socialBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(15),
          color: Colors.white.withOpacity(0.02),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 15),
            Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
