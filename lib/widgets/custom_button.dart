import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum ButtonState { disabled, enabled, loading }

class CustomButton extends StatelessWidget {
  final String text;
  final String? loadingText; // e.g., "Logging in...", "Signing up..."
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    this.loadingText,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
  });

  ButtonState get _state {
    if (isLoading) return ButtonState.loading;
    if (onPressed == null) return ButtonState.disabled;
    return ButtonState.enabled;
  }

  Color get _buttonColor {
    switch (_state) {
      case ButtonState.disabled:
        return Colors.grey[300]!;
      case ButtonState.enabled:
      case ButtonState.loading:
        return backgroundColor ?? const Color(0xFF39A4E6);
    }
  }

  Color get _textColorValue {
    switch (_state) {
      case ButtonState.disabled:
        return Colors.grey[500]!;
      case ButtonState.enabled:
      case ButtonState.loading:
        return textColor ?? Colors.white;
    }
  }

  String get _buttonText {
    switch (_state) {
      case ButtonState.loading:
        return loadingText ?? '${text}...';
      case ButtonState.disabled:
      case ButtonState.enabled:
        return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _state == ButtonState.disabled || _state == ButtonState.loading
            ? null
            : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _buttonColor,
          foregroundColor: _textColorValue,
          elevation: _state == ButtonState.disabled ? 0 : 4,
          shadowColor: _buttonColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.zero,
          disabledBackgroundColor: _buttonColor,
          disabledForegroundColor: _textColorValue,
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (_state == ButtonState.disabled) return 0;
            if (states.contains(WidgetState.pressed)) return 2;
            if (states.contains(WidgetState.hovered)) return 8;
            return 4;
          }),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: child,
              ),
            );
          },
          child: _state == ButtonState.loading
              ? Row(
                  key: const ValueKey('loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                )
              : Text(
                  _buttonText,
                  key: ValueKey(_buttonText),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    )
        .animate(target: _state == ButtonState.enabled ? 1 : 0)
        .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.2));
  }
}
