import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ConfessionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  int? _activeConfessionId;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool get isActive => _activeConfessionId != null;
  int get active => _activeConfessionId ?? 0;
  // Alkalmazás indításakor ellenőrizzük, hogy van-e elmentett felhasználó
  Future<void> checkConfessionStatus() async {
    _isLoading = true;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _activeConfessionId = prefs.getInt('active_confession');
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> activateConfession(int churchId, bool isActive) async {
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.activateConfession(churchId, isActive);
    if (response['error'] == 0) {
      _activeConfessionId = isActive ? churchId : null;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (isActive) {
        await prefs.setInt('active_confession', churchId);
      } else {
        await prefs.remove('active_confession');
      }
      notifyListeners();
      return true;
    } else {
      throw Exception(response['message'] ?? 'Sikertelen gyónás aktiválás');
    }
  }
}
