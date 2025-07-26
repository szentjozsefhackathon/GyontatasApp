import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/enhanced_background_service.dart';
import '../services/notification_service.dart';

/// Az alkalmazás életciklusát és a háttérszolgáltatást kezelő osztály
class ServiceHandler with WidgetsBindingObserver {
  static final ServiceHandler _instance = ServiceHandler._internal();
  final EnhancedBackgroundService _backgroundService = EnhancedBackgroundService();

  factory ServiceHandler() {
    return _instance;
  }

  ServiceHandler._internal();
  
  /// Az alkalmazás bezárásának megakadályozása
  static bool _preventAppExit = false;

  /// Az alkalmazás bezárásának állapota
  static bool get preventAppExit => _preventAppExit;

  /// Inicializálja a szolgáltatáskezelőt és regisztrálja az életciklus figyelőt
  Future<void> initialize(BuildContext context) async {
    WidgetsBinding.instance.addObserver(this);
    
    // Értesítések inicializálása
    await NotificationService().initialize();
    
    // Háttérszolgáltatás inicializálása
    await _backgroundService.initialize();
    
    // Aktív gyóntatás ellenőrzése
    await checkActiveConfession();
  }

  /// Leiratkozik az életciklus figyelésről
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Ellenőrzi, hogy van-e aktív gyóntatás
  Future<bool> checkActiveConfession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? activeChurchId = prefs.getInt('active_confession');
    _preventAppExit = activeChurchId != null;
    return _preventAppExit;
  }

  /// Gyónás aktiválása és értesítés küldése
  Future<bool> activateConfession(int churchId, bool isActive, {String churchName = ''}) async {
    final result = await _backgroundService.activateConfession(churchId, isActive);
    _preventAppExit = isActive;
    
    // Értesítések kezelése
    if (isActive) {
      await NotificationService().showConfessionActiveNotification(churchId, churchName);
    } else {
      await NotificationService().showConfessionCompletedNotification(churchName);
      await Future.delayed(const Duration(seconds: 3)); // Várunk, hogy a felhasználó lássa az értesítést
      await NotificationService().cancelConfessionNotifications();
    }
    
    return result;
  }

  /// Az alkalmazás életciklus eseményeinek kezelése
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('Alkalmazás életciklus változás: $state');
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Az alkalmazás a háttérbe került
      _handleBackgroundState();
    } else if (state == AppLifecycleState.resumed) {
      // Az alkalmazás újra előtérbe került
      _handleForegroundState();
    } else if (state == AppLifecycleState.detached) {
      // Az alkalmazást be akarják zárni
      _handleAppClose();
    }
  }

  /// Az alkalmazás háttérbe kerülésének kezelése
  Future<void> _handleBackgroundState() async {
    // Ellenőrizzük, hogy van-e aktív gyóntatás
    final isActive = await checkActiveConfession();
    
    if (isActive) {
      // Ha van aktív gyóntatás, bizonyosodjunk meg róla, hogy fut a háttérszolgáltatás
      print('Aktív gyóntatás, a háttérszolgáltatás futását biztosítjuk');
    }
  }

  /// Az alkalmazás előtérbe kerülésének kezelése
  Future<void> _handleForegroundState() async {
    // Ellenőrizzük az aktív gyóntatás állapotát
    await checkActiveConfession();
  }

  /// Az alkalmazás bezárásának kezelése
  Future<void> _handleAppClose() async {
    // Ha van aktív gyóntatás, megakadályozzuk az alkalmazás bezárását
    final isActive = await checkActiveConfession();
    
    if (isActive) {
      print('Az alkalmazás bezárása megakadályozva, mert van aktív gyóntatás');
    }
  }

  /// Az alkalmazás kilépésének megakadályozása
  static Future<bool> onWillPop(BuildContext context) async {
    final isActive = await ServiceHandler().checkActiveConfession();
    
    if (isActive) {
      // Értesítés megjelenítése a felhasználónak
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A gyóntatás aktív, befejezés előtt nem lehet kilépni az alkalmazásból'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
    return true;
  }
}
