import 'package:flutter/material.dart';
import 'package:kcl_app/screens/home_screen.dart';
import 'package:kcl_app/screens/login_screen.dart';
import 'package:kcl_app/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Supabase
  await SupabaseService.initialize();
  
  // Initialiser l'utilisateur admin si nécessaire
  try {
    await SupabaseService().initializeAdminUser();
  } catch (e) {
    print('⚠️ Impossible d\'initialiser l\'admin: $e');
    print('   Assurez-vous que les tables existent dans Supabase');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KCL App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text('Page non trouvée'),
            ),
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    return _isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
