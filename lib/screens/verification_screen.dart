import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/animated_bubble_background.dart';
import '../widgets/custom_button.dart';
import '../widgets/alert_banner.dart';
import '../widgets/custom_text_field.dart';
import '../utils/validators.dart';
import '../services/auth_api.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  String _email = '';
  bool _isPasswordReset = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _email = args['email'] ?? '';
      _isPasswordReset = args['isPasswordReset'] ?? false;
    }
  }

  String? _alertMessage;
  bool _isAlertError = true;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    // Clear error when user types
    if (_alertMessage != null) {
      setState(() => _alertMessage = null);
    }
  }

  void _handleVerify() async {
    String code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() {
        _alertMessage = 'Please enter all 6 digits';
        _isAlertError = true;
      });
      return;
    }

    setState(() => _isLoading = true);

    bool success;
    String? message;

    if (_isPasswordReset) {
      final result = await AuthApi.verifyResetCode(email: _email, code: code);
      success = result.$1;
      message = result.$2;
    } else {
      final result = await AuthApi.verifyEmail(email: _email, code: code);
      success = result.$1;
      message = result.$2;
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      if (_isPasswordReset) {
        Navigator.pushNamed(
          context,
          '/reset-password',
          arguments: {'email': _email, 'code': code},
        );
      } else {
        setState(() {
          _alertMessage = 'Email verified successfully!';
          _isAlertError = false;
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        });
      }
    } else {
      setState(() {
        _alertMessage = message ?? 'Invalid verification code';
        _isAlertError = true;
      });
    }
  }

  void _handleResend() async {
    setState(() => _isResending = true);

    final (success, message) = await AuthApi.resendVerification(email: _email);

    if (!mounted) return;

    setState(() => _isResending = false);

    if (success) {
      setState(() {
        _alertMessage = 'Verification code sent! Check your email.';
        _isAlertError = false;
      });
    } else {
      setState(() {
        _alertMessage = message ?? 'Failed to resend code';
        _isAlertError = true;
      });
    }
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
          
          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Hero(
                    tag: 'verification_icon',
                    child: Container(
                      width: 100,
                      height: 100,
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
                        LucideIcons.shieldCheck,
                        size: 48,
                        color: Color(0xFF39A4E6),
                      ),
                    ),
                  ).animate().scale(delay: 200.ms),

                  const SizedBox(height: 24),
                  
                  Text(
                    _isPasswordReset
                        ? 'Reset Password'
                        : 'Verify Email',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
                  
                  const SizedBox(height: 8),

                  Text(
                    'We\'ve sent a 6-digit verification code to',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
                  
                  Text(
                    _email,
                    style: const TextStyle(
                      color: Color(0xFF39A4E6),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
                        // Alert Banner
                        if (_alertMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: AlertBanner(
                              message: _alertMessage!,
                              isError: _isAlertError,
                              autoDismiss: !_isAlertError,
                              onDismiss: () => setState(() => _alertMessage = null),
                            ),
                          ).animate().fadeIn(duration: 300.ms),

                        // Code Input
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            return _OTPField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              onChanged: (value) => _onCodeChanged(value, index),
                              isDark: isDark,
                            );
                          }),
                        ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0),

                        const SizedBox(height: 32),

                        CustomButton(
                          text: _isPasswordReset ? 'Reset Password' : 'Verify Code',
                          onPressed: _handleVerify,
                          isLoading: _isLoading,
                        ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        // Resend Code
                        Center(
                          child: Column(
                            children: [
                              Text(
                                "Didn't receive the code?",
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              TextButton(
                                onPressed: _isResending ? null : _handleResend,
                                child: Text(
                                  _isResending ? 'Sending...' : 'Resend Code',
                                  style: const TextStyle(
                                    color: Color(0xFF39A4E6),
                                    fontWeight: FontWeight.w600,
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

class _OTPField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _OTPField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.isDark,
  });

  @override
  State<_OTPField> createState() => _OTPFieldState();
}

class _OTPFieldState extends State<_OTPField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
          duration: 200.ms,
          width: 45,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _isFocused 
                ? (widget.isDark ? const Color(0xFF0F2137) : Colors.white) 
                : (widget.isDark ? const Color(0xFF0A1929) : const Color(0xFFF9FAFB)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? const Color(0xFF39A4E6)
                  : (widget.isDark ? const Color(0xFF0F2137) : const Color(0xFFE5E7EB)),
              width: _isFocused ? 2 : 1.5,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF39A4E6).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF39A4E6), // Keep blue text for OTP
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
            onChanged: widget.onChanged,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        )
        .animate(target: _isFocused ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
        );
  }
}
