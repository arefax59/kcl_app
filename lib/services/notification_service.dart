import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialiser le service de notifications
  Future<void> initialize() async {
    // Initialiser les notifications locales
    await _initializeLocalNotifications();
  }

  // Initialiser les notifications locales
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Callback quand une notification est tapée
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapée: ${response.payload}');
    // Vous pouvez ajouter une navigation ici si nécessaire
  }

  // Envoyer une notification locale
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kcl_channel',
      'KCL Notifications',
      channelDescription: 'Notifications de l\'application KCL',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      title.hashCode,
      title,
      body,
      details,
      payload: data?.toString(),
    );
  }

  // Envoyer une notification à tous les utilisateurs (appelé par l'admin)
  // Cette méthode sera implémentée avec Supabase
  Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? dataId,
  }) async {
    // TODO: Implémenter avec Supabase
    await showLocalNotification(title: title, body: body, data: data);
  }

  // Écouter les nouvelles notifications
  // Cette méthode sera implémentée avec Supabase
  void listenToNotifications() {
    // TODO: Implémenter avec Supabase Realtime
  }
  
  void dispose() {
    // Nettoyage si nécessaire
  }
}

