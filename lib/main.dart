import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'theme/app_typography.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RizzexAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: AppFonts.family,
        textTheme: AppFonts.textTheme(),
      ),
      home: const SplashScreen(),
      routes: {
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}
