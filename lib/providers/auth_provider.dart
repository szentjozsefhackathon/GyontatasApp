import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get error => _error;
  
  // Alkalmazás indításakor ellenőrizzük, hogy van-e elmentett felhasználó
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentUser = await _apiService.getCurrentUser();
    } catch (e) {
      _error = 'Nem sikerült betölteni a bejelentkezési állapotot: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Bejelentkezés folyamata
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _apiService.login(username, password);
      
      if (result['success']) {
        _currentUser = await _apiService.getCurrentUser();
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Bejelentkezési hiba: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Kijelentkezés
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _apiService.logout();
      _currentUser = null;
    } catch (e) {
      _error = 'Kijelentkezési hiba: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
