import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'admin_screen.dart';
import 'chronopost_screen.dart';
import 'dpd_screen.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  final SupabaseService _supabaseService = SupabaseService();

  bool _rememberMe = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showForm = false;

  late AnimationController _formController;
  late AnimationController _logoController;
  late Animation<double> _formOpacity;
  late Animation<Offset> _formSlide;
  late Animation<Offset> _logoSlide;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();

    // Animation du formulaire
    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeIn),
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic));

    // Animation du logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _logoSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.15),
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeInOut));

    _logoScale = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Démarrer les animations après un court délai
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _logoController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => _showForm = true);
            _formController.forward();
          }
        });
      }
    });
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username');
    final savedPassword = prefs.getString('password');
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe && savedUsername != null && savedPassword != null) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _rememberMe = true;
        _obscurePassword = false;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('username', _usernameController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Authentifier l'utilisateur avec Supabase
      final user = await _supabaseService.authenticateUser(
        _usernameController.text,
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (user == null) {
        _showSnackBar('Identifiant ou mot de passe incorrect', Colors.red);
        return;
      }

      // Sauvegarder les identifiants
      await _saveCredentials();

      // Sauvegarder l'ID utilisateur et les informations
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user['id'] as String);
      await prefs.setBool('isAdmin', user['is_admin'] == true);
      await prefs.setString('group', user['group'] ?? 'admin');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur de connexion: $e', Colors.red);
      return;
    }
    
    // Écouter les notifications
    _notificationService.listenToNotifications();

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final isAdmin = prefs.getBool('isAdmin') ?? false;
      final group = prefs.getString('group') ?? 'admin';
      
      // Rediriger vers l'écran approprié
      Widget targetScreen;
      if (isAdmin) {
        targetScreen = const AdminScreen();
      } else if (group == 'chronopost') {
        targetScreen = const ChronopostScreen();
      } else if (group == 'dpd') {
        targetScreen = const DpdScreen();
      } else {
        targetScreen = const HomeScreen();
      }
      
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _formController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo animé qui se déplace légèrement vers le haut
                  SlideTransition(
                    position: _logoSlide,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'KCL APP',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Formulaire de connexion avec animation
                  if (_showForm)
                    FadeTransition(
                      opacity: _formOpacity,
                      child: SlideTransition(
                        position: _formSlide,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Connexion',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Bienvenue ! Connectez-vous pour continuer',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // Champ utilisateur
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Nom d\'utilisateur',
                                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF3B82F6)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Champ mot de passe
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF3B82F6)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                onSubmitted: (_) => _login(),
                              ),
                              const SizedBox(height: 16),

                              // Case "Se souvenir de moi"
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      activeColor: const Color(0xFF3B82F6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Se souvenir de moi',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Bouton de connexion
                              ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                  disabledBackgroundColor: Colors.grey[300],
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : const Text(
                                  'Connexion',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Lien "Mot de passe oublié"
                              TextButton(
                                onPressed: () {
                                  _showSnackBar(
                                    'Contactez l\'administrateur',
                                    const Color(0xFF3B82F6),
                                  );
                                },
                                child: const Text(
                                  'Mot de passe oublié ?',
                                  style: TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
