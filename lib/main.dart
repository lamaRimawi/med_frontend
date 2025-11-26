import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';
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
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }


  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      themeMode: _themeMode,
      toggleTheme: _toggleTheme,
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
