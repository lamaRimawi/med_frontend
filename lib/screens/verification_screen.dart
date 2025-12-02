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
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  String _email = '';
  bool _isPasswordReset = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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

    // Verify the code first (even for password reset)
    // We use verifyEmail for both, assuming the backend supports checking the code this way
    final (success, message) = await AuthApi.verifyEmail(
      email: _email,
      code: code,
    );

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
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
                      'Verification',
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
                  const SizedBox(height: 40),

                  // Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF39A4E6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF39A4E6).withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.shield,
                      size: 60,
                      color: Color(0xFF39A4E6),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds)
                  .then()
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .scale(duration: 500.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 32),

                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9), Color(0xFF39A4E6)],
                    ).createShader(bounds),
                    child: Text(
                      _isPasswordReset ? 'Enter Reset Code' : 'Verify Your Email',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 12),

                  Text(
                    'We\'ve sent a 6-digit verification code to',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),
                  
                  Text(
                    _email,
                    style: const TextStyle(
                      color: Color(0xFF39A4E6),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 32),

                  // Alert Banner
                  if (_alertMessage != null)
                    AlertBanner(
                      message: _alertMessage!,
                      isError: _isAlertError,
                      autoDismiss: !_isAlertError,
                      onDismiss: () => setState(() => _alertMessage = null),
                    ).animate().fadeIn(duration: 300.ms),

                  if (_alertMessage != null) const SizedBox(height: 20),

                  // Code Input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return _OTPField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        onChanged: (value) => _onCodeChanged(value, index),
                      );
                    }),
                  ).animate().fadeIn(delay: 700.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 32),



                  const SizedBox(height: 32),



                  const SizedBox(height: 32),

                  CustomButton(
                    text: _isPasswordReset ? 'Reset Password' : 'Verify Code',
                    onPressed: _handleVerify,
                    isLoading: _isLoading,
                  ).animate().fadeIn(delay: 800.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 32),

                  // Resend Code
                  Column(
                    children: [
                      Text(
                        "Didn't receive the code?",
                        style: TextStyle(color: Colors.grey[600]),
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
                  ).animate().fadeIn(delay: 900.ms),
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

  const _OTPField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
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
        color: _isFocused ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? const Color(0xFF39A4E6) : const Color(0xFFE5E7EB),
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
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF39A4E6),
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: widget.onChanged,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    ).animate(target: _isFocused ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 200.ms);
  }
}
