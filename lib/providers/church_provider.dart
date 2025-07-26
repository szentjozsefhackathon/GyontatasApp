import 'package:flutter/material.dart';
import '../models/church.dart';
import '../services/api_service.dart';

class ChurchProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Church> _churches = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _selectedChurchDetails;

  List<Church> get churches => _churches;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get selectedChurchDetails => _selectedChurchDetails;

  // Gondnokolt templomok lekérése
  Future<void> fetchResponsibilities(List<int> responsibilities) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _churches = [];
      for (int id in responsibilities) {
        final church = await _apiService.getChurchDetails(id);
        _churches.add(Church.fromJson(church));
      }
    } catch (e) {
      _error = 'Nem sikerült betölteni a templomokat: ${e.toString()}';
      _churches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Templom részletes adatainak lekérése
  Future<void> fetchChurchDetails(int churchId) async {
    _isLoading = true;
    _error = null;
    _selectedChurchDetails = null;
    notifyListeners();

    try {
      _selectedChurchDetails = await _apiService.getChurchDetails(churchId);
    } catch (e) {
      _error = 'Nem sikerült betölteni a templom részleteit: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kiválasztott templom részletek törlése
  void clearSelectedChurch() {
    _selectedChurchDetails = null;
    notifyListeners();
  }
}
