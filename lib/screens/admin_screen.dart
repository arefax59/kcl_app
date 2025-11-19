import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  String _adminName = '';
  String? _adminId;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'Admin';
    final userId = prefs.getString('userId');
    setState(() {
      _adminName = username;
      _adminId = userId;
    });
  }

  Future<void> _showAddUserDialog() async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    String selectedGroup = 'admin';

    // Générer un mot de passe aléatoire
    final generatedPassword = _supabaseService.generatePassword();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un utilisateur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur (ID)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Sélecteur de groupe
              const Text(
                'Groupe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings, size: 14),
                            SizedBox(width: 4),
                            Text('Admin', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        selected: selectedGroup == 'admin',
                        onSelected: (selected) {
                          setStateDialog(() {
                            selectedGroup = 'admin';
                          });
                        },
                        selectedColor: Colors.orange[100],
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_shipping, size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text('Chronopost', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        selected: selectedGroup == 'chronopost',
                        onSelected: (selected) {
                          setStateDialog(() {
                            selectedGroup = 'chronopost';
                          });
                        },
                        selectedColor: Colors.blue[100],
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_shipping, size: 14, color: Colors.red),
                            SizedBox(width: 4),
                            Text('DPD', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        selected: selectedGroup == 'dpd',
                        onSelected: (selected) {
                          setStateDialog(() {
                            selectedGroup = 'dpd';
                          });
                        },
                        selectedColor: Colors.red[100],
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Mot de passe généré :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            generatedPassword,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          color: Colors.green[700],
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: generatedPassword));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mot de passe copié !'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          tooltip: 'Copier',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Notez-le, il ne sera plus visible après',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              usernameController.dispose();
              nameController.dispose();
              emailController.dispose();
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.isEmpty ||
                  nameController.text.isEmpty ||
                  emailController.text.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez remplir tous les champs'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Sauvegarder les valeurs avant de fermer la boîte
              final String username = usernameController.text;
              final String name = nameController.text;
              final String email = emailController.text;

              try {
                await _supabaseService.insertUser({
                  'username': username,
                  'password': generatedPassword,
                  'name': name,
                  'email': email,
                  'is_admin': false,
                  'group': selectedGroup,
                  'points': 0,
                  'created_at': DateTime.now().toIso8601String(),
                  'fcm_token': '',
                });

                // Fermer la boîte de dialogue et disposer des contrôleurs
                if (!mounted) {
                  usernameController.dispose();
                  nameController.dispose();
                  emailController.dispose();
                  return;
                }
                final navigator = Navigator.of(context);
                navigator.pop();
                usernameController.dispose();
                nameController.dispose();
                emailController.dispose();

                // Afficher le mot de passe généré
                if (mounted) {
                  _showPasswordDialog(username, generatedPassword);
                }
              } catch (e) {
                if (!mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                String errorMessage = e.toString();
                
                // Nettoyer le message d'erreur
                errorMessage = errorMessage.replaceAll('Exception: ', '');
                errorMessage = errorMessage.replaceAll('Error: ', '');
                
                messenger.showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Erreur lors de la création',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(errorMessage),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(String username, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Utilisateur créé !'),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[300]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identifiant : $username',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Mot de passe : $password',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: password));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mot de passe copié !'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '⚠️ Notez ces informations maintenant, elles ne seront plus affichées.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK, noté'),
          ),
        ],
      ),
    );
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final TextEditingController nameController = TextEditingController(text: user['name'] ?? '');
    final TextEditingController emailController = TextEditingController(text: user['email'] ?? '');
    final String userId = user['id'] as String;
    final String username = user['username'] as String;
    String selectedGroup = user['group'] ?? 'admin';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'utilisateur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username (non modifiable)
              TextField(
                enabled: false,
                controller: TextEditingController(text: username),
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur (ID)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              // Nom
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              // Email
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Sélecteur de groupe
              const Text(
                'Groupe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings, size: 14),
                            SizedBox(width: 4),
                            Text('Admin', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        selected: selectedGroup == 'admin',
                        onSelected: (selected) {
                          setStateDialog(() {
                            selectedGroup = 'admin';
                          });
                        },
                        selectedColor: Colors.orange[100],
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_shipping, size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text('Chronopost', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        selected: selectedGroup == 'chronopost',
                        onSelected: (selected) {
                          setStateDialog(() {
                            selectedGroup = 'chronopost';
                          });
                        },
                        selectedColor: Colors.blue[100],
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_shipping, size: 14, color: Colors.red),
                            SizedBox(width: 4),
                            Text('DPD', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        selected: selectedGroup == 'dpd',
                        onSelected: (selected) {
                          setStateDialog(() {
                            selectedGroup = 'dpd';
                          });
                        },
                        selectedColor: Colors.red[100],
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              nameController.dispose();
              emailController.dispose();
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || emailController.text.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez remplir tous les champs'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await _supabaseService.updateUser(userId, {
                  'name': nameController.text,
                  'email': emailController.text,
                  'group': selectedGroup,
                });

                if (!mounted) return;
                Navigator.of(context).pop();
                nameController.dispose();
                emailController.dispose();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Utilisateur modifié avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String id, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer l\'utilisateur "$username" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteUser(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur supprimé')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _resetPassword(String id, String username) async {
    final newPassword = _supabaseService.generatePassword();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Utilisateur : $username'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nouveau mot de passe :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          newPassword,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        color: Colors.orange[700],
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: newPassword));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mot de passe copié !'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.updateUser(id, {'password': newPassword});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe réinitialisé')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _showSendNotificationDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController bodyController = TextEditingController();
    String selectedTarget = 'all'; // 'all', 'chronopost', 'dpd', ou 'user'
    String? selectedUserId;
    
    // Capturer le contexte du widget parent avant d'ouvrir le dialog
    final parentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Envoyer un message'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.message),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Destinataire',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public, size: 14),
                          SizedBox(width: 4),
                          Text('Tous', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      selected: selectedTarget == 'all',
                      onSelected: (selected) {
                        setStateDialog(() {
                          selectedTarget = 'all';
                          selectedUserId = null;
                        });
                      },
                      selectedColor: Colors.blue[100],
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    ChoiceChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_shipping, size: 14, color: Colors.blue),
                          SizedBox(width: 4),
                          Text('Chronopost', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      selected: selectedTarget == 'chronopost',
                      onSelected: (selected) {
                        setStateDialog(() {
                          selectedTarget = 'chronopost';
                          selectedUserId = null;
                        });
                      },
                      selectedColor: Colors.blue[100],
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    ChoiceChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_shipping, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text('DPD', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      selected: selectedTarget == 'dpd',
                      onSelected: (selected) {
                        setStateDialog(() {
                          selectedTarget = 'dpd';
                          selectedUserId = null;
                        });
                      },
                      selectedColor: Colors.red[100],
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    ChoiceChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, size: 14),
                          SizedBox(width: 4),
                          Text('Utilisateur', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      selected: selectedTarget == 'user',
                      onSelected: (selected) {
                        setStateDialog(() {
                          selectedTarget = 'user';
                        });
                      },
                      selectedColor: Colors.green[100],
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ],
                ),
                if (selectedTarget == 'user') ...[
                  const SizedBox(height: 16),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabaseService.getUsersStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final users = snapshot.data ?? [];
                      final nonAdminUsers = users.where((u) => u['is_admin'] != true).toList();
                      
                      if (nonAdminUsers.isEmpty) {
                        return const Text('Aucun utilisateur disponible');
                      }
                      
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Sélectionner un utilisateur',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        value: selectedUserId,
                        items: nonAdminUsers.map((user) {
                          return DropdownMenuItem<String>(
                            value: user['id'] as String,
                            child: Text('${user['name']} (${user['username']})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedUserId = value;
                          });
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                titleController.dispose();
                bodyController.dispose();
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || bodyController.text.isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedTarget == 'user' && selectedUserId == null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez sélectionner un utilisateur'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Déterminer les valeurs de ciblage
                  String? targetGroup;
                  String? targetUserId;
                  
                  if (selectedTarget == 'all') {
                    targetGroup = 'all';
                  } else if (selectedTarget == 'chronopost' || selectedTarget == 'dpd') {
                    targetGroup = selectedTarget;
                  } else if (selectedTarget == 'user') {
                    targetUserId = selectedUserId;
                  }

                  // Ajouter les données dans Supabase
                  final dataId = await _supabaseService.insertData({
                    'title': titleController.text,
                    'content': bodyController.text,
                    'user_id': _adminId ?? '',
                    'created_at': DateTime.now().toIso8601String(),
                    'from_admin': true,
                    'target_group': targetGroup,
                    'target_user_id': targetUserId,
                  });
                  
                  // Envoyer une notification
                  await _supabaseService.sendNotificationToAllUsers(
                    title: titleController.text,
                    body: bodyController.text.isNotEmpty 
                        ? bodyController.text 
                        : 'Une nouvelle information a été ajoutée',
                    dataId: dataId,
                  );

                  // Fermer le dialog avant d'afficher le SnackBar
                  Navigator.of(dialogContext).pop();
                  titleController.dispose();
                  bodyController.dispose();

                  // Vérifier que le widget parent est toujours monté avant d'afficher le SnackBar
                  if (!mounted) return;
                  String targetText = '';
                  if (selectedTarget == 'all') {
                    targetText = 'tous les utilisateurs';
                  } else if (selectedTarget == 'chronopost') {
                    targetText = 'les utilisateurs Chronopost';
                  } else if (selectedTarget == 'dpd') {
                    targetText = 'les utilisateurs DPD';
                  } else if (selectedTarget == 'user') {
                    targetText = 'l\'utilisateur sélectionné';
                  }
                  
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('Message envoyé à $targetText'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  // Fermer le dialog même en cas d'erreur
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }
                  titleController.dispose();
                  bodyController.dispose();
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', false);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _adminName,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Statistiques
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabaseService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                  final users = snapshot.data ?? [];
                  final admins = users.where((u) => u['is_admin'] == true || (u['group'] ?? 'admin') == 'admin').toList();
                  final chronopostUsers = users.where((u) => (u['group'] ?? 'admin') == 'chronopost').toList();
                  final dpdUsers = users.where((u) => (u['group'] ?? 'admin') == 'dpd').toList();

                  return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.admin_panel_settings,
                        'Admin',
                        admins.length.toString(),
                        Colors.orange,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      _buildStatItem(
                        Icons.local_shipping,
                        'Chronopost',
                        chronopostUsers.length.toString(),
                        Colors.blue,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      _buildStatItem(
                        Icons.local_shipping,
                        'DPD',
                        dpdUsers.length.toString(),
                        Colors.red,
                      ),
                    ],
                  ),
                );
              },
            ),

            // Liste des utilisateurs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Liste des utilisateurs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_active),
                    onPressed: _showSendNotificationDialog,
                    tooltip: 'Envoyer une notification',
                    color: const Color(0xFF3B82F6),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabaseService.getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erreur: ${snapshot.error}'),
                    );
                  }

                  final users = snapshot.data ?? [];

                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun utilisateur',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isAdmin = user['is_admin'] == true;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar
                              CircleAvatar(
                                backgroundColor: isAdmin
                                    ? Colors.orange[600]
                                    : const Color(0xFF3B82F6),
                                child: Icon(
                                  isAdmin ? Icons.admin_panel_settings : Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Contenu principal
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Nom et badge admin
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            user['name'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (isAdmin)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[100],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.orange[300]!),
                                            ),
                                            child: Text(
                                              'ADMIN',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange[900],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // ID
                                    Row(
                                      children: [
                                        Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ID: ${user['username']}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Email
                                    Row(
                                      children: [
                                        Icon(Icons.email, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            user['email'] ?? '',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Points
                                    Row(
                                      children: [
                                        Icon(Icons.stars, size: 14, color: Colors.amber[700]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Points: ${user['points'] ?? 0}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Groupe
                                    Row(
                                      children: [
                                        Icon(
                                          (user['group'] ?? 'admin') == 'chronopost'
                                              ? Icons.local_shipping
                                              : (user['group'] ?? 'admin') == 'dpd'
                                                  ? Icons.local_shipping
                                                  : Icons.admin_panel_settings,
                                          size: 14,
                                          color: (user['group'] ?? 'admin') == 'chronopost'
                                              ? Colors.blue
                                              : (user['group'] ?? 'admin') == 'dpd'
                                                  ? Colors.red
                                                  : Colors.orange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Groupe: ${_getGroupLabel(user['group'] ?? 'admin')}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Date
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Créé le ${_formatDate(user['created_at'])}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Boutons d'action
                              if (!isAdmin)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Bouton Modifier
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Color(0xFF3B82F6)),
                                      iconSize: 20,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _editUser(user),
                                      tooltip: 'Modifier',
                                    ),
                                    // Bouton Réinitialiser mot de passe
                                    IconButton(
                                      icon: const Icon(Icons.lock_reset, color: Colors.orange),
                                      iconSize: 20,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _resetPassword(user['id'], user['username']),
                                      tooltip: 'Réinitialiser mot de passe',
                                    ),
                                    // Bouton Supprimer
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      iconSize: 20,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _deleteUser(user['id'], user['username']),
                                      tooltip: 'Supprimer',
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.person_add),
        label: const Text('Nouvel utilisateur'),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, [Color? iconColor]) {
    return Column(
      children: [
        Icon(icon, color: iconColor ?? Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getGroupLabel(String group) {
    switch (group) {
      case 'chronopost':
        return 'Chronopost';
      case 'dpd':
        return 'DPD';
      default:
        return 'Admin';
    }
  }

  String _formatDate(dynamic dateStr) {
    try {
      if (dateStr == null) return 'N/A';
      final date = dateStr is String ? DateTime.parse(dateStr) : dateStr as DateTime;
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
