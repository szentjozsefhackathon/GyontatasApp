import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

/// Fejlett háttér szolgáltatás a gyóntatás API hívások futtatásához akkor is,
/// amikor az alkalmazás a háttérben fut vagy be van zárva
class EnhancedBackgroundService {
  static final EnhancedBackgroundService _instance = EnhancedBackgroundService._internal();
  final ApiService _apiService = ApiService();
  
  factory EnhancedBackgroundService() {
    return _instance;
  }
  
  EnhancedBackgroundService._internal();
  
  /// Flutter Background Service példány
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  
  /// Szolgáltatás inicializálása
  Future<void> initialize() async {
    // Értesítések inicializálása
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    // Értesítés csatorna beállítása Android-ra
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Értesítés beállítása iOS-re
    final DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );
    
    // Inicializálás
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );
    
    await flutterLocalNotificationsPlugin.initialize(initSettings);
    
    // Háttér szolgáltatás konfigurálása
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'confession_notification_channel',
        initialNotificationTitle: 'Gyóntatás aktív',
        initialNotificationContent: 'Az alkalmazás fut a háttérben',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: DarwinConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
    
    // Ellenőrizzük, hogy van-e aktív gyóntatás
    _checkAndStartService();
  }
  
  /// iOS háttérfutás kezelése
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }
  
  /// Szolgáltatás indulási pont
  @pragma('vm:entry-point')
  static Future<void> _onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    
    // Android esetén beállítjuk a foreground módot
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Gyóntatás aktív",
        content: "Az alkalmazás fut a háttérben",
      );
    }
    
    // Adatok stream-elése az alkalmazás és a háttérszolgáltatás között
    service.on('setConfessionState').listen((event) {
      if (event != null) {
        service.invoke('updateConfessionState', {
          'isActive': event['isActive'],
          'churchId': event['churchId'],
        });
        
        if (event['isActive'] == true) {
          // Ha aktiváljuk a gyóntatást, elindítjuk az időzítőt
          final int churchId = event['churchId'];
          _startPeriodicRefresh(service, churchId);
        } else {
          // Ha deaktiváljuk a gyóntatást, leállítjuk az időzítőt
          _stopPeriodicRefresh(service);
        }
      }
    });
    
    // Állapot lekérdezése
    service.on('getConfessionState').listen((event) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? activeChurchId = prefs.getInt('active_confession');
      
      service.invoke('updateConfessionState', {
        'isActive': activeChurchId != null,
        'churchId': activeChurchId,
      });
    });
    
    // Ellenőrizzük, hogy van-e aktív gyóntatás az induláskor
    _checkAndRestartRefresh(service);
  }
  
  /// Aktív gyóntatás ellenőrzése és szolgáltatás indítása, ha szükséges
  static Future<void> _checkAndRestartRefresh(ServiceInstance service) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? activeChurchId = prefs.getInt('active_confession');
    
    if (activeChurchId != null) {
      _startPeriodicRefresh(service, activeChurchId);
    }
  }
  
  /// Periodikus frissítés indítása
  static void _startPeriodicRefresh(ServiceInstance service, int churchId) {
    // Állapot frissítése
    service.invoke('updateConfessionState', {
      'isActive': true,
      'churchId': churchId,
    });
    
    // Leállítjuk az esetlegesen már futó időzítőt
    service.invoke('stopTimer', {});
    
    // 10 percenkénti időzítő indítása
    Timer.periodic(const Duration(minutes: 10), (timer) async {
      // Ellenőrizzük, hogy még mindig aktív-e a gyóntatás
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? activeChurchId = prefs.getInt('active_confession');
      
      if (activeChurchId == null) {
        timer.cancel();
        service.invoke('updateConfessionState', {
          'isActive': false,
          'churchId': null,
        });
        return;
      }
      
      // API hívás küldése
      try {
        final ApiService apiService = ApiService();
        final responseData = await apiService.activateConfession(activeChurchId, true);
        
        // Értesítés küldése a háttérben történő frissítésről
        final notificationService = NotificationService();
        await notificationService.showApiRefreshNotification();
        
        service.invoke('refreshResult', {
          'success': true,
          'response': responseData.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        // Elmentjük az utolsó sikeres frissítés időpontját
        await prefs.setString('last_refresh_time', DateTime.now().toIso8601String());
      } catch (e) {
        service.invoke('refreshResult', {
          'success': false,
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
    
    // Azonnal is küldjük el az első jelzést
    _sendRefreshNow(service, churchId);
  }
  
  /// Időzítő leállítása
  static void _stopPeriodicRefresh(ServiceInstance service) {
    service.invoke('stopTimer', {});
    service.invoke('updateConfessionState', {
      'isActive': false,
      'churchId': null,
    });
  }
  
  /// Azonnali API hívás küldése és értesítés megjelenítése
  static Future<void> _sendRefreshNow(ServiceInstance service, int churchId) async {
    try {
      final ApiService apiService = ApiService();
      final apiResponse = await apiService.activateConfession(churchId, true);
      
      // Értesítés küldése háttérben történő frissítésről
      final notificationService = NotificationService();
      await notificationService.showApiRefreshNotification();
      
      service.invoke('refreshResult', {
        'success': true,
        'response': apiResponse.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      service.invoke('refreshResult', {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
  
  /// Ellenőrzi és elindítja a háttérszolgáltatást, ha van aktív gyóntatás
  Future<void> _checkAndStartService() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? activeChurchId = prefs.getInt('active_confession');
    
    if (activeChurchId != null) {
      await startService(activeChurchId);
    }
  }
  
  /// Szolgáltatás indítása
  Future<bool> startService(int churchId) async {
    final isRunning = await _service.isRunning();
    
    if (!isRunning) {
      await _service.startService();
    }
    
    // Adatok küldése a háttérszolgáltatásnak
    _service.invoke('setConfessionState', {
      'isActive': true,
      'churchId': churchId,
    });
    
    return true;
  }
  
  /// Szolgáltatás leállítása
  Future<bool> stopService() async {
    final isRunning = await _service.isRunning();
    
    if (isRunning) {
      _service.invoke('setConfessionState', {
        'isActive': false,
      });
      
      // Teljes leállítás helyett csak a Timer-t állítjuk le,
      // hogy az alkalmazás később újra használhassa a háttérszolgáltatást
      // await _service.stopService();
    }
    
    return true;
  }
  
  /// Gyónás aktiválása és háttérszolgáltatás indítása
  Future<bool> activateConfession(int churchId, bool isActive) async {
    try {
      // API hívás
      await _apiService.activateConfession(churchId, isActive);
      
      // SharedPreferences frissítése
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      if (isActive) {
        await prefs.setInt('active_confession', churchId);
        await startService(churchId);
      } else {
        await prefs.remove('active_confession');
        await stopService();
      }
      
      return true;
    } catch (e) {
      print('Hiba a háttérszolgáltatás aktiválásakor: $e');
      return false;
    }
  }
  
  /// Szolgáltatás állapotának lekérdezése
  Future<bool> isServiceRunning() async {
    return await _service.isRunning();
  }
}
