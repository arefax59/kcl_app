import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'map_screen.dart';

class DpdScreen extends StatefulWidget {
  const DpdScreen({super.key});

  @override
  State<DpdScreen> createState() => _DpdScreenState();
}

class _DpdScreenState extends State<DpdScreen> {
  final NotificationService _notificationService = NotificationService();
  final SupabaseService _supabaseService = SupabaseService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _username = '';
  String? _userId;
  
  // Données pour le tableau des horaires (par jour du mois)
  Map<int, Map<String, dynamic>> _horairesData = {};
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadHorairesData();
    Future.delayed(const Duration(milliseconds: 500), () {
      _notificationService.listenToNotifications();
    });
  }
  
  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Utilisateur';
      _userId = prefs.getString('userId');
    });
  }


  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _editTime(BuildContext context, int day, String field) async {
    if (!_horairesData.containsKey(day)) {
      _horairesData[day] = _getDefaultDayData();
    }
    final currentTime = _horairesData[day]![field] as String? ?? '--:--';
    TimeOfDay initialTime = TimeOfDay.now();
    
    if (currentTime != '--:--' && currentTime.isNotEmpty) {
      try {
        final parts = currentTime.split(':');
        if (parts.length >= 2) {
          initialTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (e) {
        // Utiliser l'heure actuelle par défaut
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        if (!_horairesData.containsKey(day)) {
          _horairesData[day] = _getDefaultDayData();
        }
        _horairesData[day]![field] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _updateTotalHours(day);
      });
      // Sauvegarder après la mise à jour de l'état
      await _saveHorairesData();
    }
  }

  Future<void> _editNumber(BuildContext context, int day, String field) async {
    if (!_horairesData.containsKey(day)) {
      _horairesData[day] = _getDefaultDayData();
    }
    final currentValue = _horairesData[day]![field] as int? ?? 0;
    final controller = TextEditingController(text: currentValue.toString());

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getFieldLabel(field)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _getFieldLabel(field),
            border: const OutlineInputBorder(),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (result != null) {
      final value = int.tryParse(result) ?? 0;
      setState(() {
        if (!_horairesData.containsKey(day)) {
          _horairesData[day] = _getDefaultDayData();
        }
        _horairesData[day]![field] = value;
      });
      // Sauvegarder après la mise à jour de l'état
      await _saveHorairesData();
    }
  }

  Map<String, dynamic> _getDefaultDayData() {
    return {
      'heure_depart': '--:--',
      'heure_fin': '--:--',
      'points': 0,
      'retours': 0,
      'esd': 0,
      'ramasse': false,
      'kilometrage': 0,
      'total_heures': '0h00',
    };
  }

  void _updateTotalHours(int day) {
    if (!_horairesData.containsKey(day)) return;
    final data = _horairesData[day]!;
    final heureDepart = data['heure_depart'] as String? ?? '--:--';
    final heureFin = data['heure_fin'] as String? ?? '--:--';
    
    if (heureDepart != '--:--' && heureFin != '--:--' && heureDepart.isNotEmpty && heureFin.isNotEmpty) {
      try {
        final partsDepart = heureDepart.split(':');
        final partsFin = heureFin.split(':');
        if (partsDepart.length >= 2 && partsFin.length >= 2) {
          final hDepart = int.parse(partsDepart[0]);
          final mDepart = int.parse(partsDepart[1]);
          final hFin = int.parse(partsFin[0]);
          final mFin = int.parse(partsFin[1]);
          
          final totalMinutes = (hFin * 60 + mFin) - (hDepart * 60 + mDepart);
          if (totalMinutes >= 0) {
            final heures = totalMinutes ~/ 60;
            final minutes = totalMinutes % 60;
            data['total_heures'] = '${heures}h${minutes.toString().padLeft(2, '0')}';
          } else {
            data['total_heures'] = '0h00';
          }
        }
      } catch (e) {
        data['total_heures'] = '0h00';
      }
    } else {
      data['total_heures'] = '0h00';
    }
  }

  String _getTotalMonthHours() {
    int totalMinutes = 0;
    for (var dayData in _horairesData.values) {
      final totalHeures = dayData['total_heures'] as String? ?? '0h00';
      if (totalHeures != '0h00' && totalHeures.isNotEmpty) {
        try {
          final parts = totalHeures.split('h');
          if (parts.length >= 2) {
            final heures = int.tryParse(parts[0]) ?? 0;
            final minutes = int.tryParse(parts[1]) ?? 0;
            totalMinutes += heures * 60 + minutes;
          }
        } catch (e) {
          // Ignorer les erreurs de parsing
        }
      }
    }
    final heures = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${heures}h${minutes.toString().padLeft(2, '0')}';
  }

  Future<void> _saveHorairesData() async {
    // Sauvegarder automatiquement dans SharedPreferences avec JSON
    try {
      final prefs = await SharedPreferences.getInstance();
      final monthKey = 'horaires_${_selectedMonth.year}_${_selectedMonth.month}';
      final jsonData = jsonEncode(_horairesData.map((key, value) => 
        MapEntry(key.toString(), value)));
      await prefs.setString(monthKey, jsonData);
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  Future<void> _loadHorairesData() async {
    // Charger les données depuis SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final monthKey = 'horaires_${_selectedMonth.year}_${_selectedMonth.month}';
      final jsonData = prefs.getString(monthKey);
      if (jsonData != null && jsonData.isNotEmpty) {
        final decoded = jsonDecode(jsonData) as Map<String, dynamic>;
        setState(() {
          _horairesData = decoded.map((key, value) => 
            MapEntry(int.parse(key), Map<String, dynamic>.from(value)));
        });
      }
    } catch (e) {
      print('Erreur lors du chargement: $e');
    }
  }

  List<int> _getDaysInMonth() {
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    return List.generate(lastDay.day, (index) => index + 1);
  }

  String _getMonthName() {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[_selectedMonth.month - 1];
  }

  Future<void> _sendEmail() async {
    final monthName = _getMonthName();
    final year = _selectedMonth.year;
    final totalHours = _getTotalMonthHours();
    
    // Construire le corps de l'email avec tableau HTML
    String emailBodyHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; }
    h2 { color: #C62828; }
    table { border-collapse: collapse; width: 100%; margin-top: 20px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #C62828; color: white; font-weight: bold; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    .total { font-weight: bold; color: #C62828; }
  </style>
</head>
<body>
  <h2>Résumé des horaires - $monthName $year</h2>
  <p><strong>Utilisateur:</strong> $_username</p>
  <p><strong>Total heures du mois:</strong> <span class="total">$totalHours</span></p>
  
  <table>
    <thead>
      <tr>
        <th>Jour</th>
        <th>Heure de départ</th>
        <th>Heure de fin</th>
        <th>Points</th>
        <th>Retours</th>
        <th>ESD</th>
        <th>Ramassé</th>
        <th>Kilométrage</th>
        <th>Total heures</th>
      </tr>
    </thead>
    <tbody>
''';
    
    for (var day in _getDaysInMonth()) {
      if (_horairesData.containsKey(day)) {
        final data = _horairesData[day]!;
        emailBodyHtml += '      <tr>\n';
        emailBodyHtml += '        <td>${day.toString().padLeft(2, '0')}</td>\n';
        emailBodyHtml += '        <td>${data['heure_depart'] ?? '--:--'}</td>\n';
        emailBodyHtml += '        <td>${data['heure_fin'] ?? '--:--'}</td>\n';
        emailBodyHtml += '        <td>${data['points'] ?? 0}</td>\n';
        emailBodyHtml += '        <td>${data['retours'] ?? 0}</td>\n';
        emailBodyHtml += '        <td>${data['esd'] ?? 0}</td>\n';
        emailBodyHtml += '        <td>${data['ramasse'] == true ? 'Oui' : 'Non'}</td>\n';
        emailBodyHtml += '        <td>${data['kilometrage'] ?? 0} km</td>\n';
        emailBodyHtml += '        <td class="total">${data['total_heures'] ?? '0h00'}</td>\n';
        emailBodyHtml += '      </tr>\n';
      }
    }
    
    emailBodyHtml += '''
    </tbody>
  </table>
</body>
</html>
''';
    
    // Version texte simple pour les clients email qui ne supportent pas HTML
    String emailBodyText = 'Résumé des horaires - $monthName $year\n\n';
    emailBodyText += 'Utilisateur: $_username\n';
    emailBodyText += 'Total heures du mois: $totalHours\n\n';
    emailBodyText += 'Détail par jour:\n';
    emailBodyText += '┌──────┬──────────────┬──────────┬────────┬─────────┬─────┬─────────┬────────────┬──────────────┐\n';
    emailBodyText += '│ Jour │ Départ       │ Fin      │ Points │ Retours │ ESD │ Ramassé │ Kilométrage│ Total heures │\n';
    emailBodyText += '├──────┼──────────────┼──────────┼────────┼─────────┼─────┼─────────┼────────────┼──────────────┤\n';
    
    for (var day in _getDaysInMonth()) {
      if (_horairesData.containsKey(day)) {
        final data = _horairesData[day]!;
        final jour = day.toString().padLeft(2, '0');
        final depart = (data['heure_depart'] ?? '--:--').toString().padRight(12);
        final fin = (data['heure_fin'] ?? '--:--').toString().padRight(8);
        final points = (data['points'] ?? 0).toString().padLeft(6);
        final retours = (data['retours'] ?? 0).toString().padLeft(7);
        final esd = (data['esd'] ?? 0).toString().padLeft(3);
        final ramasse = (data['ramasse'] == true ? 'Oui' : 'Non').padRight(7);
        final km = '${data['kilometrage'] ?? 0} km'.padRight(10);
        final total = (data['total_heures'] ?? '0h00').toString().padRight(12);
        emailBodyText += '│ $jour  │ $depart │ $fin │ $points │ $retours │ $esd │ $ramasse │ $km │ $total │\n';
      }
    }
    
    emailBodyText += '└──────┴──────────────┴──────────┴────────┴─────────┴─────┴─────────┴────────────┴──────────────┘\n';
    
    // Utiliser la version texte pour mailto (car mailto ne supporte pas bien HTML)
    final emailBody = emailBodyText;
    
    final email = 'johann.kcl@gmail.com';
    final subject = 'Résumé horaires - $monthName $year';
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(emailBody)}',
    );
    
    try {
      // Essayer d'ouvrir avec choix de l'application
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      
      if (!launched) {
        // Si l'ouverture a échoué, proposer de copier dans le presse-papiers
        if (!mounted) return;
        final shouldCopy = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Email non disponible'),
            content: const Text(
              'Aucune application email n\'est configurée.\n\n'
              'Souhaitez-vous copier le résumé dans le presse-papiers ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Copier'),
              ),
            ],
          ),
        );
        
        if (shouldCopy == true) {
          // Copier la version HTML dans le presse-papiers
          await Clipboard.setData(ClipboardData(text: emailBodyHtml));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Résumé HTML copié dans le presse-papiers'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // En cas d'erreur, proposer de copier dans le presse-papiers
      if (!mounted) return;
      final shouldCopy = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur lors de l\'envoi'),
          content: Text(
            'Impossible d\'ouvrir le client email.\n\n'
            'Souhaitez-vous copier le résumé dans le presse-papiers ?\n\n'
            'Erreur: $e',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Copier'),
            ),
          ],
        ),
      );
      
      if (shouldCopy == true) {
        // Copier la version HTML dans le presse-papiers
        await Clipboard.setData(ClipboardData(text: emailBodyHtml));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Résumé HTML copié dans le presse-papiers'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'points':
        return 'Points';
      case 'retours':
        return 'Retours';
      case 'esd':
        return 'ESD';
      case 'kilometrage':
        return 'Kilométrage';
      default:
        return field;
    }
  }

  void _showHorairesDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                // En-tête avec sélection du mois
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () async {
                            setStateDialog(() {
                              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                            });
                            await _loadHorairesData();
                            setState(() {});
                          },
                        ),
                        Text(
                          '${_getMonthName()} ${_selectedMonth.year}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () async {
                            setStateDialog(() {
                              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                            });
                            await _loadHorairesData();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Total heures du mois
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total heures du mois:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getTotalMonthHours(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tableau avec tous les jours du mois
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        border: TableBorder.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        dividerThickness: 1,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.red[100],
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Jour',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Heure de départ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Heure de fin',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Points',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Retours',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'ESD',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Ramassé',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Kilométrage',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Total heures',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: _getDaysInMonth().map((day) {
                          if (!_horairesData.containsKey(day)) {
                            _horairesData[day] = _getDefaultDayData();
                          }
                          final row = _horairesData[day]!;
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  day.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataCell(
                                GestureDetector(
                                  onTap: () => _editTime(context, day, 'heure_depart').then((_) {
                                    setStateDialog(() {});
                                    setState(() {});
                                  }),
                                  child: Text(
                                    row['heure_depart'] ?? '--:--',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                GestureDetector(
                                  onTap: () => _editTime(context, day, 'heure_fin').then((_) {
                                    setStateDialog(() {});
                                    setState(() {});
                                  }),
                                  child: Text(
                                    row['heure_fin'] ?? '--:--',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                GestureDetector(
                                  onTap: () => _editNumber(context, day, 'points').then((_) {
                                    setStateDialog(() {});
                                    setState(() {});
                                  }),
                                  child: Text(
                                    (row['points'] ?? 0).toString(),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                GestureDetector(
                                  onTap: () => _editNumber(context, day, 'retours').then((_) {
                                    setStateDialog(() {});
                                    setState(() {});
                                  }),
                                  child: Text(
                                    (row['retours'] ?? 0).toString(),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                GestureDetector(
                                  onTap: () => _editNumber(context, day, 'esd').then((_) {
                                    setStateDialog(() {});
                                    setState(() {});
                                  }),
                                  child: Text(
                                    (row['esd'] ?? 0).toString(),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Checkbox(
                                  value: row['ramasse'] ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      if (!_horairesData.containsKey(day)) {
                                        _horairesData[day] = _getDefaultDayData();
                                      }
                                      _horairesData[day]!['ramasse'] = value ?? false;
                                      _saveHorairesData();
                                    });
                                    setStateDialog(() {});
                                  },
                                ),
                              ),
                              DataCell(
                                GestureDetector(
                                  onTap: () => _editNumber(context, day, 'kilometrage').then((_) {
                                    setStateDialog(() {});
                                    setState(() {});
                                  }),
                                  child: Text(
                                    '${row['kilometrage'] ?? 0} km',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  row['total_heures'] ?? '0h00',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _sendEmail,
                      icon: const Icon(Icons.send),
                      label: const Text('Envoyer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showPlanningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Planning'),
        content: const Text('Fonctionnalité Planning à venir...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showOptimDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MapScreen(),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KCL APP',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Application de gestion pour les utilisateurs KCL.'),
            SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Développeur: johann trachez',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.red[700],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'DPD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bonjour, $_username',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.access_time, color: Colors.red),
            title: const Text('Horaires'),
            onTap: () {
              Navigator.of(context).pop();
              _showHorairesDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.red),
            title: const Text('Planning'),
            onTap: () {
              Navigator.of(context).pop();
              _showPlanningDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_up, color: Colors.red),
            title: const Text('Optim'),
            onTap: () {
              Navigator.of(context).pop();
              _showOptimDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.red),
            title: const Text('À propos'),
            onTap: () {
              Navigator.of(context).pop();
              _showAboutDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion'),
            onTap: () {
              Navigator.of(context).pop();
              _logout();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 DpdScreen build - Drawer should be visible');
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red[700]!,
              Colors.red[500]!,
              Colors.red[300]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar avec logo DPD
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'DPD',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _supabaseService.getUsersStream(),
                          builder: (context, snapshot) {
                            int userPoints = 0;
                            if (snapshot.hasData && _userId != null) {
                              try {
                                final user = snapshot.data?.firstWhere(
                                  (u) => u['id'] == _userId,
                                );
                                if (user != null) {
                                  userPoints = (user['points'] as int?) ?? 0;
                                }
                              } catch (e) {
                                userPoints = 0;
                              }
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.stars, color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$userPoints',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: _logout,
                          tooltip: 'Déconnexion',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Contenu principal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tuile Messagerie
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.message, color: Colors.red[700], size: 24),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Messagerie',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: _supabaseService.getAdminMessagesStream('dpd', _userId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Text('Erreur: ${snapshot.error}'),
                                        ),
                                      );
                                    }

                                    final messages = snapshot.data ?? [];

                                    if (messages.isEmpty) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.inbox_outlined,
                                                size: 60,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Aucune information',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: messages.length,
                                      itemBuilder: (context, index) {
                                        final message = messages[index];
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          color: Colors.red[50],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.all(12),
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.red[700],
                                              child: const Icon(
                                                Icons.admin_panel_settings,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            title: Text(
                                              message['title'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            subtitle: message['content'] != null &&
                                                    message['content'].toString().isNotEmpty
                                                ? Padding(
                                                    padding: const EdgeInsets.only(top: 8),
                                                    child: Text(
                                                      message['content'],
                                                      style: const TextStyle(fontSize: 14),
                                                    ),
                                                  )
                                                : null,
                                            trailing: message['created_at'] != null
                                                ? Text(
                                                    _formatDate(message['created_at']),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
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
    );
  }

  String _formatDate(dynamic dateStr) {
    try {
      if (dateStr == null) return '';
      final date = dateStr is String ? DateTime.parse(dateStr) : dateStr as DateTime;
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
