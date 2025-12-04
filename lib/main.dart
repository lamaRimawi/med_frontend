import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/theme_toggle.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/reports_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  late SharedPreferences _prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initTheme();
  }

  Future<void> _initTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs.getString('theme_mode') ?? 'system';
    setState(() {
      _themeMode = _getThemeModeFromString(savedTheme);
      _isLoading = false;
    });
  }

  ThemeMode _getThemeModeFromString(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _getStringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
      _prefs.setString('theme_mode', _getStringFromThemeMode(mode));
    });
  }

  void _toggleTheme() {
    // Legacy toggle support, cycles between light and dark
    final newMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _setThemeMode(newMode);
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      themeMode: _themeMode,
      toggleTheme: _toggleTheme,
      setThemeMode: _setThemeMode,
      child: ToastificationWrapper(
        config: const ToastificationConfig(
          alignment: Alignment.topRight,
          animationDuration: Duration(milliseconds: 300),
        ),
        child: MaterialApp(
          title: 'MediScan',
          debugShowCheckedModeBanner: false,
          themeMode: _themeMode,

          // Light Theme
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF39A4E6),
              primary: const Color(0xFF39A4E6),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Inter',
            scaffoldBackgroundColor: Colors.white,
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF39A4E6),
              foregroundColor: Colors.white,
            ),
          ),

          // Dark Theme
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF39A4E6),
              primary: const Color(0xFF39A4E6),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Inter',
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
            ),
          ),

          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/home': (context) => const HomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/verification': (context) => const VerificationScreen(),
            '/reset-password': (context) => const ResetPasswordScreen(),
            '/reports': (context) => const ReportsScreen(),
          },
        ),
      ),
    );
  }
}
