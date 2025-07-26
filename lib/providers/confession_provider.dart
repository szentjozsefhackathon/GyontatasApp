import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/enhanced_background_service.dart';
import '../services/notification_service.dart';
import '../utils/service_handler.dart';

class ConfessionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final EnhancedBackgroundService _backgroundService = EnhancedBackgroundService();
  final ServiceHandler _serviceHandler = ServiceHandler();

  int? _activeConfessionId;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool get isActive => _activeConfessionId != null;
  int get active => _activeConfessionId ?? 0;
  
  // Alkalmazás indításakor ellenőrizzük, hogy van-e aktív gyóntatás
  Future<void> checkConfessionStatus() async {
    _isLoading = true;
    notifyListeners();
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _activeConfessionId = prefs.getInt('active_confession');
    _activeChurchName = prefs.getString('active_church_name') ?? '';
    
    // Ha van aktív gyóntatás, elindítjuk a fejlesztett háttérszolgáltatást
    if (_activeConfessionId != null) {
      await _backgroundService.startService(_activeConfessionId!);
      
      // Ha van templom név, akkor értesítést is küldünk
      if (_activeChurchName.isNotEmpty) {
        await NotificationService().showConfessionActiveNotification(
          _activeConfessionId!, 
          _activeChurchName
        );
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Aktív templom neve
  String _activeChurchName = '';
  String get activeChurchName => _activeChurchName;

  Future<bool> activateConfession(int churchId, bool isActive, {String churchName = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.activateConfession(churchId, isActive);
      if (response['error'] == 0) {
        _activeConfessionId = isActive ? churchId : null;
        
        // Templom nevének mentése
        if (isActive && churchName.isNotEmpty) {
          _activeChurchName = churchName;
        }
        
        // ServiceHandler használata a gyóntatás aktiválásához
        await _serviceHandler.activateConfession(
          churchId, 
          isActive, 
          churchName: churchName.isNotEmpty ? churchName : _activeChurchName
        );
        
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Sikertelen gyónás aktiválás');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
