import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';

class DpdScreen extends StatefulWidget {
  const DpdScreen({super.key});

  @override
  State<DpdScreen> createState() => _DpdScreenState();
}

class _DpdScreenState extends State<DpdScreen> {
  final NotificationService _notificationService = NotificationService();
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  String _username = '';
  String? _userId;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadTodayWorkHours();
    Future.delayed(const Duration(milliseconds: 500), () {
      _notificationService.listenToNotifications();
    });
  }
  
  @override
  void dispose() {
    _notificationService.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Utilisateur';
      _userId = prefs.getString('userId');
    });
  }

  Future<void> _loadTodayWorkHours() async {
    if (_userId == null) return;
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final workHours = await _supabaseService.getWorkHours(_userId!, dateStr);
    
    if (workHours != null && mounted) {
      setState(() {
        final startTimeStr = workHours['start_time'] as String? ?? '';
        final endTimeStr = workHours['end_time'] as String? ?? '';
        final points = workHours['points'] as int? ?? 0;
        if (startTimeStr.isNotEmpty) {
          final parts = startTimeStr.split(':');
          _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          _startTimeController.text = _formatTimeOfDay(_startTime!);
        }
        if (endTimeStr.isNotEmpty) {
          final parts = endTimeStr.split(':');
          _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          _endTimeController.text = _formatTimeOfDay(_endTime!);
        }
        _pointsController.text = points.toString();
      });
    } else {
      setState(() {
        _pointsController.text = '0';
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          _startTimeController.text = _formatTimeOfDay(picked);
        } else {
          _endTime = picked;
          _endTimeController.text = _formatTimeOfDay(picked);
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _startTimeController.clear();
        _endTimeController.clear();
        _pointsController.text = '0';
        _startTime = null;
        _endTime = null;
      });
      _loadTodayWorkHours();
    }
  }

  Future<void> _saveWorkHours() async {
    if (_userId == null) return;
    if (_startTime == null || _endTime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner les heures de début et de fin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final points = int.tryParse(_pointsController.text) ?? 0;
    if (points < 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nombre de points doit être positif ou nul'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      await _supabaseService.saveWorkHours(
        _userId!,
        _formatTimeOfDay(_startTime!),
        _formatTimeOfDay(_endTime!),
        dateStr,
        points,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horaires et points enregistrés avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }

  Future<void> _showDeliveriesTable() async {
    if (_userId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Synthèse - ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabaseService.getDeliveriesStream(_userId!, DateTime.now().year, DateTime.now().month),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final deliveries = snapshot.data ?? [];

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.red[100]),
                          columns: const [
                            DataColumn(label: Text('Début', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Fin', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Points pris', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Points livré', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: [
                            ...deliveries.map((delivery) {
                              final startTime = delivery['start_time'] as String?;
                              final endTime = delivery['end_time'] as String?;
                              final pointsTaken = delivery['points_taken'] as int? ?? 0;
                              final pointsDelivered = delivery['points_delivered'] as int? ?? 0;
                              
                              String formatTime(String? timeStr) {
                                if (timeStr == null || timeStr.isEmpty) return '--:--';
                                try {
                                  // Format peut être "HH:MM:SS" ou "HH:MM"
                                  final parts = timeStr.split(':');
                                  if (parts.length >= 2) {
                                    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
                                  }
                                  return '--:--';
                                } catch (e) {
                                  return '--:--';
                                }
                              }
                              
                              return DataRow(
                                cells: [
                                  DataCell(
                                    GestureDetector(
                                      onTap: () => _editDeliveryTime(delivery['id'] as String, true, delivery),
                                      child: Text(
                                        formatTime(startTime),
                                        style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    GestureDetector(
                                      onTap: () => _editDeliveryTime(delivery['id'] as String, false, delivery),
                                      child: Text(
                                        formatTime(endTime),
                                        style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    GestureDetector(
                                      onTap: () => _editDeliveryPoints(delivery['id'] as String, true, delivery),
                                      child: Text(
                                        pointsTaken.toString(),
                                        style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    GestureDetector(
                                      onTap: () => _editDeliveryPoints(delivery['id'] as String, false, delivery),
                                      child: Text(
                                        pointsDelivered.toString(),
                                        style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _deleteDelivery(delivery['id'] as String),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                            // Ligne pour ajouter une nouvelle livraison
                            DataRow(
                              cells: [
                                const DataCell(Text('+', style: TextStyle(fontSize: 20, color: Colors.green))),
                                const DataCell(Text('')),
                                const DataCell(Text('')),
                                const DataCell(Text('')),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.add, color: Colors.green),
                                    onPressed: _addNewDelivery,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editDeliveryTime(String deliveryId, bool isStartTime, Map<String, dynamic> delivery) async {
    final currentTime = isStartTime 
        ? (delivery['start_time'] as String?)
        : (delivery['end_time'] as String?);
    
    TimeOfDay initialTime = TimeOfDay.now();
    if (currentTime != null && currentTime.isNotEmpty) {
      final parts = currentTime.split(':');
      initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
      try {
        await _supabaseService.updateDelivery(
          deliveryId,
          {isStartTime ? 'start_time' : 'end_time': timeStr},
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editDeliveryPoints(String deliveryId, bool isPointsTaken, Map<String, dynamic> delivery) async {
    final currentValue = isPointsTaken 
        ? (delivery['points_taken'] as int? ?? 0)
        : (delivery['points_delivered'] as int? ?? 0);

    final controller = TextEditingController(text: currentValue.toString());
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPointsTaken ? 'Points pris' : 'Points livré'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nombre de points',
            border: OutlineInputBorder(),
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
      final points = int.tryParse(result) ?? 0;
      try {
        await _supabaseService.updateDelivery(
          deliveryId,
          {isPointsTaken ? 'points_taken' : 'points_delivered': points},
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addNewDelivery() async {
    if (_userId == null) return;
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      await _supabaseService.insertDelivery({
        'user_id': _userId!,
        'date': dateStr,
        'start_time': null,
        'end_time': null,
        'points_taken': 0,
        'points_delivered': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteDelivery(String deliveryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer cette livraison ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteDelivery(deliveryId);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        // Tuile Horaires
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
                                    Icon(Icons.access_time, color: Colors.red[700], size: 24),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Horaires de travail',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Sélection de date
                                InkWell(
                                  onTap: _selectDate,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, color: Colors.red[700]),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                        const Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Heure de début
                                TextField(
                                  controller: _startTimeController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Heure de début',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.play_arrow),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.access_time),
                                      onPressed: () => _selectTime(true),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Heure de fin
                                TextField(
                                  controller: _endTimeController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Heure de fin',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.stop),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.access_time),
                                      onPressed: () => _selectTime(false),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Points
                                TextField(
                                  controller: _pointsController,
                                  decoration: InputDecoration(
                                    labelText: 'Nombre de points',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.stars),
                                    hintText: '0',
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _saveWorkHours,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[700],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Enregistrer',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: _showDeliveriesTable,
                                      icon: const Icon(Icons.table_chart),
                                      label: const Text('Livraisons'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[600],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Tuile Informations
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
                                    Icon(Icons.info_outline, color: Colors.red[700], size: 24),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Informations',
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
