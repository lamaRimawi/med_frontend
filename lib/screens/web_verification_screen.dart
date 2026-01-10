import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/custom_button.dart';
import '../widgets/alert_banner.dart';
import '../widgets/animated_bubble_background.dart';
import '../services/auth_api.dart';

class WebVerificationScreen extends StatefulWidget {
  const WebVerificationScreen({super.key});

  @override
  State<WebVerificationScreen> createState() => _WebVerificationScreenState();
}

class _WebVerificationScreenState extends State<WebVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  String _email = '';
  bool _isPasswordReset = false;
  String? _alertMessage;
  bool _isAlertError = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _email = args['email'] ?? '';
      _isPasswordReset = args['isPasswordReset'] ?? false;
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
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
    if (_alertMessage != null) setState(() => _alertMessage = null);
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
          if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        });
      }
    } else {
      setState(() {
        _alertMessage = message ?? 'Invalid code';
        _isAlertError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glass effect colors
    final cardColor = isDark 
        ? const Color(0xFF111827).withOpacity(0.9) 
        : Colors.white.withOpacity(0.9);
    final borderColor = isDark 
        ? Colors.white.withOpacity(0.1) 
        : Colors.white.withOpacity(0.5);
    final shadowColor = isDark 
        ? Colors.black.withOpacity(0.5) 
        : const Color(0xFF39A4E6).withOpacity(0.15);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1929) : const Color(0xFFF0F4F8),
      body: Stack(
        children: [
          const AnimatedBubbleBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBackBtn(isDark),
                    const SizedBox(height: 20),
                    _buildIcon(),
                    const SizedBox(height: 32),
                    Text(
                      _isPasswordReset ? 'Enter Reset Code' : 'Verify Email',
                      style: GoogleFonts.outfit(
                        color: textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),
                    const SizedBox(height: 12),
                    _buildInstructionText(isDark),
                    const SizedBox(height: 32),
                    if (_alertMessage != null)
                      AlertBanner(
                        message: _alertMessage!,
                        isError: _isAlertError,
                        onDismiss: () => setState(() => _alertMessage = null),
                      ).animate().fadeIn(),
                    const SizedBox(height: 32),
                    _buildOTPFields(isDark),
                    const SizedBox(height: 40),
                    CustomButton(
                      text: _isPasswordReset ? 'Set New Password' : 'Verify My Account',
                      onPressed: _handleVerify,
                      isLoading: _isLoading,
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 32),
                    _buildResendSection(isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPFields(bool isDark) {
    final fillColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 50,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: GoogleFonts.outfit(color: const Color(0xFF39A4E6), fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF39A4E6), width: 2),
              ),
              fillColor: fillColor,
              filled: true,
            ),
            onChanged: (v) => _onCodeChanged(v, index),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ).animate().fadeIn(delay: (400 + (index * 50)).ms);
      }),
    );
  }

  Widget _buildBackBtn(bool isDark) {
    return Align(
      alignment: Alignment.topLeft,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white38 : const Color(0xFF64748B)),
        splashRadius: 20,
      ),
    );
  }

  Widget _buildIcon() {
    return Hero(
      tag: 'verification_icon',
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF39A4E6).withOpacity(0.1),
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
    ).animate().scale(delay: 100.ms, curve: Curves.elasticOut);
  }

  Widget _buildInstructionText(bool isDark) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.outfit(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 16, height: 1.5),
        children: [
          const TextSpan(text: 'We\'ve sent a 6-digit code to\n'),
          TextSpan(text: _email, style: const TextStyle(color: Color(0xFF39A4E6), fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildResendSection(bool isDark) {
    return Column(
      children: [
        Text(
          'Didn\'t receive the code?',
          style: GoogleFonts.outfit(color: isDark ? Colors.white38 : const Color(0xFF94A3B8), fontSize: 14),
        ),
        TextButton(
          onPressed: () {},
          child: Text('Resend Code', style: GoogleFonts.outfit(color: const Color(0xFF39A4E6), fontWeight: FontWeight.bold)),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }
}
