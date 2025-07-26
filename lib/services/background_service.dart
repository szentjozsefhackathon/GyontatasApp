import 'dart:async';
import 'dart:isolate';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Háttér szolgáltatás a periodikus API hívások kezelésére
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  
  factory BackgroundService() {
    return _instance;
  }
  
  BackgroundService._internal();
  
  Timer? _timer;
  bool _isActive = false;
  final ApiService _apiService = ApiService();
  
  /// Szolgáltatás inicializálása
  void initialize() {
    print('BackgroundService: Inicializálás');
    _checkAndStartTimer();
  }
  
  /// Időzítő indítása ha szükséges
  Future<void> _checkAndStartTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final activeChurchId = prefs.getInt('active_confession');
    
    if (activeChurchId != null && !_isActive) {
      startPeriodicRefresh(activeChurchId);
    }
  }
  
  /// Periodikus frissítés indítása
  void startPeriodicRefresh(int churchId) {
    if (_isActive) return;
    
    print('BackgroundService: Időzítő indítása a(z) $churchId templom számára');
    
    _isActive = true;
    _timer?.cancel();
    
    // 10 percenként frissítjük
    _timer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      _refreshConfessionStatus(churchId);
    });
    
    // Azonnal is elküldjük az első jelzést
    _refreshConfessionStatus(churchId);
  }
  
  /// Gyóntatás állapot frissítése az API-n keresztül
  Future<void> _refreshConfessionStatus(int churchId) async {
    try {
      print('BackgroundService: Gyóntatás frissítése - ${DateTime.now()}');
      final response = await _apiService.activateConfession(churchId, true);
      print('BackgroundService: API válasz: $response');
    } catch (e) {
      print('BackgroundService: Hiba történt: $e');
    }
  }
  
  /// Időzítő leállítása
  void stopPeriodicRefresh() {
    if (!_isActive) return;
    
    print('BackgroundService: Időzítő leállítása');
    _timer?.cancel();
    _timer = null;
    _isActive = false;
  }
  
  /// Állapot ellenőrzése
  bool get isActive => _isActive;
}
