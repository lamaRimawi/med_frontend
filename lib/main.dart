import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'screens/notification_settings_screen.dart';
import 'screens/dark_mode_screen.dart';
import 'screens/web_landing_screen.dart';
import 'screens/web_forgot_password_screen.dart';
import 'screens/web_verification_screen.dart';
import 'screens/web_reset_password_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }

  // Lock orientation to portrait mode only
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    });
  }

  void _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = mode;
      prefs.setBool('isDarkMode', mode == ThemeMode.dark);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: ThemeProvider(
        themeMode: _themeMode,
        toggleTheme: _toggleTheme,
        setThemeMode: _setThemeMode,
        child: Builder(
          builder: (context) {
            return MaterialApp(
              title: 'MediScan',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF39A4E6),
                  primary: const Color(0xFF39A4E6),
                ),
                useMaterial3: true,
                scaffoldBackgroundColor: Colors.white,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF39A4E6),
                  primary: const Color(0xFF39A4E6),
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
                scaffoldBackgroundColor: const Color(0xFF121212),
              ),
              themeMode: _themeMode,
              initialRoute: '/',
              routes: {
                '/': (context) => kIsWeb ? const WebLandingScreen() : const SplashScreen(),
                '/landing': (context) => const WebLandingScreen(),
                '/onboarding': (context) => const OnboardingScreen(),
                '/home': (context) => const HomeScreen(),
                '/login': (context) => const LoginScreen(),
                '/signup': (context) => const SignupScreen(),
                '/forgot-password': (context) => kIsWeb ? const WebForgotPasswordScreen() : const ForgotPasswordScreen(),
                '/verification': (context) => kIsWeb ? const WebVerificationScreen() : const VerificationScreen(),
                '/reset-password': (context) => kIsWeb ? const WebResetPasswordScreen() : const ResetPasswordScreen(),
                '/reports': (context) => const ReportsScreen(),
                '/notification-settings': (context) => const NotificationSettingsScreen(),
                '/dark-mode-settings': (context) => const DarkModeScreen(),
              },
            );
          },
        ),
      ),
    );
  }
}
