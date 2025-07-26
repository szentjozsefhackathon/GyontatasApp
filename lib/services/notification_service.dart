import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Az értesítések kezelését végző segéd osztály
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  /// Értesítések inicializálása
  Future<void> initialize() async {
    // Android beállítások
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS beállítások
    final DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: true,
        );
    
    // Inicializáció
    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }
  
  /// iOS értesítés fogadása
  Future<void> onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // iOS specifikus feldolgozás
  }
  
  /// Értesítés interakció feldolgozása
  Future<void> onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    // Értesítésre kattintás feldolgozása
  }
  
  /// Gyóntatás aktív értesítés megjelenítése
  Future<void> showConfessionActiveNotification(int churchId, String churchName) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'confession_active_channel',
      'Aktív gyóntatás',
      channelDescription: 'Értesítések aktív gyóntatás közben',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
    );
    
    const DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      1, // Azonosító
      'Aktív gyóntatás',
      'Gyóntatás aktív a(z) $churchName templomban',
      notificationDetails,
      payload: 'confession_active_$churchId',
    );
  }
  
  /// Gyóntatás befejezése értesítés megjelenítése
  Future<void> showConfessionCompletedNotification(String churchName) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'confession_completed_channel',
      'Gyóntatás befejezve',
      channelDescription: 'Értesítések a gyóntatás befejezéséről',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      2, // Azonosító
      'Gyóntatás befejezve',
      'A gyóntatás befejeződött a(z) $churchName templomban',
      notificationDetails,
      payload: 'confession_completed',
    );
  }
  
  /// API frissítés értesítés megjelenítése (csak háttérben)
  Future<void> showApiRefreshNotification() async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'confession_refresh_channel',
      'API frissítés',
      channelDescription: 'Értesítések az API frissítésekről',
      importance: Importance.min,
      priority: Priority.low,
      playSound: false,
      showWhen: false,
    );
    
    const DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      3, // Azonosító
      'API frissítés',
      'A gyóntatás állapotának frissítése megtörtént',
      notificationDetails,
    );
  }
  
  /// Gyóntatással kapcsolatos értesítések törlése
  Future<void> cancelConfessionNotifications() async {
    await _flutterLocalNotificationsPlugin.cancel(1); // Aktív gyóntatás értesítés törlése
    await _flutterLocalNotificationsPlugin.cancel(3); // API frissítés értesítés törlése
  }
}
