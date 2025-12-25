import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme_toggle.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String placeholder;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool showPassword;
  final VoidCallback? onTogglePassword;
  final String? Function(String?)? validator;
  final bool validateOnChange;

  const CustomTextField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.showPassword = false,
    this.onTogglePassword,
    this.validator,
    this.validateOnChange = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();
  bool _hasError = false;
  bool _isValid = false;
  bool _hasBeenFocused = false;
  String? _errorMessage;

  bool get _isDarkMode =>
      ThemeProvider.of(context)?.themeMode == ThemeMode.dark ?? false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        
        // When field loses focus, validate
        if (!_isFocused && _hasBeenFocused && widget.validator != null) {
          final error = widget.validator!(widget.controller?.text);
          _hasError = error != null;
          _errorMessage = error;
          _isValid = error == null && (widget.controller?.text.isNotEmpty ?? false);
        }
        
        if (_isFocused) {
          _hasBeenFocused = true;
        }
      });
    });

    // Add listener for real-time validation
    widget.controller?.addListener(() {
      if (widget.validateOnChange && _hasBeenFocused) {
        setState(() {
          final error = widget.validator?.call(widget.controller?.text);
          _hasError = error != null;
          _errorMessage = error;
          _isValid = error == null && (widget.controller?.text.isNotEmpty ?? false);
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Color get _borderColor {
    if (_hasError) return const Color(0xFFEF4444); // Red for error
    if (_isValid) return const Color(0xFF10B981); // Green for valid
    if (_isFocused) return const Color(0xFF39A4E6); // Blue for focused
    return const Color(0xFFE5E7EB).withValues(alpha: 0.6); // Default gray
  }

  Color get _iconColor {
    if (_hasError) return const Color(0xFFEF4444);
    if (_isValid) return const Color(0xFF10B981);
    if (_isFocused) return const Color(0xFF39A4E6);
    return const Color(0xFF9CA3AF);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: _hasError
                ? const Color(0xFFEF4444)
                : _isDarkMode
                    ? Colors.grey[300]
                    : const Color(0xFF374151),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isDarkMode
                ? const Color(0xFF1E1E1E)
                : const Color(0xFFF9FAFB).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _borderColor,
              width: _isFocused || _hasError || _isValid ? 2 : 1.5,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF39A4E6).withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : _hasError
                    ? [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword && !widget.showPassword,
            keyboardType: widget.keyboardType,
            style: TextStyle(
              color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: _iconColor,
                    size: 20,
                  ),
                ),
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        widget.showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _iconColor,
                        size: 20,
                      ),
                      onPressed: widget.onTogglePassword,
                    )
                  : _isValid
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.check_circle,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                        )
                      : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        )
            .animate(target: _isFocused ? 1 : 0)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.01, 1.01),
              duration: 200.ms,
            ),
        // Error Message
        if (_hasError && _errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 14,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 200.ms)
              .moveY(begin: -5, end: 0, duration: 200.ms),
      ],
    );
  }
}
