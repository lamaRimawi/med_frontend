import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/alert_banner.dart';
import '../services/auth_api.dart';
import '../utils/validators.dart';

class WebResetPasswordScreen extends StatefulWidget {
  const WebResetPasswordScreen({super.key});

  @override
  State<WebResetPasswordScreen> createState() => _WebResetPasswordScreenState();
}

class _WebResetPasswordScreenState extends State<WebResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _alertMessage;
  bool _isAlertError = true;

  String _email = '';
  String _code = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _email = args['email'] ?? '';
      _code = args['code'] ?? '';
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    final passwordError = Validators.validatePassword(_passwordController.text);
    final confirmError = Validators.validateConfirmPassword(
      _confirmPasswordController.text,
      _passwordController.text,
    );

    if (passwordError != null || confirmError != null) {
      setState(() {
        _alertMessage = passwordError ?? confirmError;
        _isAlertError = true;
      });
      return;
    }

    setState(() => _isLoading = true);

    final (success, message) = await AuthApi.resetPassword(
      email: _email,
      code: _code,
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (success) {
        _alertMessage = 'Password reset successfully!';
        _isAlertError = false;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        });
      } else {
        _alertMessage = message ?? 'Reset failed';
        _isAlertError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2137),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBackBtn(),
                const SizedBox(height: 20),
                _buildIcon(),
                const SizedBox(height: 32),
                Text(
                  'New Password',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),
                const SizedBox(height: 12),
                Text(
                  'Create a strong new password that you haven\'t used before.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
                const SizedBox(height: 32),
                if (_alertMessage != null)
                  AlertBanner(
                    message: _alertMessage!,
                    isError: _isAlertError,
                    onDismiss: () => setState(() => _alertMessage = null),
                  ).animate().fadeIn(),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'New Password *',
                  placeholder: 'Enter new password',
                  icon: LucideIcons.lock,
                  controller: _passwordController,
                  isPassword: true,
                  showPassword: !_obscurePassword,
                  onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: Validators.validatePassword,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Confirm Password *',
                  placeholder: 'Re-enter new password',
                  icon: LucideIcons.lock,
                  controller: _confirmPasswordController,
                  isPassword: true,
                  showPassword: !_obscureConfirmPassword,
                  onTogglePassword: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: (val) => Validators.validateConfirmPassword(val, _passwordController.text),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 40),
                CustomButton(
                  text: 'Update Password',
                  onPressed: _handleReset,
                  isLoading: _isLoading,
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackBtn() {
    return Align(
      alignment: Alignment.topLeft,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white38),
        splashRadius: 20,
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF39A4E6).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        LucideIcons.lock,
        size: 48,
        color: Color(0xFF39A4E6),
      ),
    ).animate().scale(delay: 100.ms, curve: Curves.elasticOut);
  }
}
