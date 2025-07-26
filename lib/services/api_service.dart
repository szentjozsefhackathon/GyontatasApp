import 'dart:convert';
import 'package:gyontatas_app/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/church.dart';

class ApiService {
  static const String baseUrl = 'https://miserend.hu/api/v4';
  static const String loginEndpoint = '/login';
  static const String churchesEndpoint = '/church';
  static const String userEndpoint = '/user';
  
  // Felhasználó bejelentkeztetése
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl$loginEndpoint'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );

    final Map<String, dynamic> responseData = jsonDecode(response.body);
    if (responseData['error'] == 0) {
      // Sikeres bejelentkezés
      await _saveToken(responseData['token']);
      return {
        'success': true,
        'token': responseData['token'],
      };
    } else {
      // Hibás bejelentkezés
      return {
        'success': false,
        'message': responseData['text'] ?? 'Sikertelen bejelentkezés'
      };
    }
  }
  
  // Token mentése SharedPreferences-be
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }
  
  // Felhasználó adatainak lekérése SharedPreferences-ből
  Future<User?> getCurrentUser() async {
    final response = await http.post(
      Uri.parse('$baseUrl$userEndpoint'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'token': (await SharedPreferences.getInstance()).getString('token') ?? '',
      }),);
    final resBody = jsonDecode(response.body);
    final userData = resBody['user'] ?? {};
    if (resBody['error'] == 0) {
      return User.fromJson({
        'username': userData['username'],
        'nickname': userData['nickname'] ?? '',
        'name': userData['name'] ?? '',
        'email': userData['email'] ?? '',
        'favorites': userData['favorites'].cast<int>() ?? [],
        'responsibilities': userData['responsibilities'].cast<int>() ?? [],
      });
    }
    else {
      return null;
    }
    }
  

  // Kijelentkezés - törli a tokent
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    AuthProvider().logout();
  }

  // Templom részletes adatainak lekérése ID alapján
  Future<Map<String, dynamic>> getChurchDetails(int churchId) async {
    final response = await http.post(
      Uri.parse('$baseUrl$churchesEndpoint'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int>{
        'id': churchId,
      })
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['error'] == 0) {
        return responseData;
      } else {
        throw Exception(responseData['text'] ?? 'Hiba a templom adatainak lekérése során');
      }
    } else {
      throw Exception('Sikertelen lekérés: ${response.statusCode}');
    }
  }
}
