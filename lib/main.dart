import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const KCLApp());
}

class KCLApp extends StatelessWidget {
  const KCLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KCL APP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
