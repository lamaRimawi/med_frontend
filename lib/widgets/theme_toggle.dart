import 'package:flutter/material.dart';

class ThemeProvider extends InheritedWidget {
  final ThemeMode themeMode;
  final VoidCallback toggleTheme;
  final ValueChanged<ThemeMode> setThemeMode;

  const ThemeProvider({
    super.key,
    required this.themeMode,
    required this.toggleTheme,
    required this.setThemeMode,
    required super.child,
  });

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final isDark = themeProvider?.themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: themeProvider?.toggleTheme,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return RotationTransition(
              turns: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            key: ValueKey(isDark),
            color: isDark ? Colors.amber : const Color(0xFF39A4E6),
            size: 28,
          ),
        ),
      ),
    );
  }
}
