import 'dart:convert';
import 'dart:io';
import 'package:gyontatas_app/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/church.dart';

class ApiService {
  static const String baseUrl = 'https://miserend.hu/api/v4';
  static const String loginEndpoint = '/login';
  static const String churchesEndpoint = '/church';
  static const String userEndpoint = '/user';
  static const String lorawanEndpoint = '/lorawan';
  
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
  
  // MAC cím lekérése az eszközről
  Future<String> _getDeviceMacAddress() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String macAddress = "";
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        macAddress = androidInfo.id; // Android esetén egyedi eszközazonosító
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        macAddress = iosInfo.identifierForVendor ?? ""; // iOS esetén vendor azonosító
      }
    } catch (e) {
      print('Nem sikerült a MAC cím lekérése: $e');
      macAddress = "unknown";
    }
    if (macAddress == "") {
      macAddress = "aaaaaaaaaaaaaaaa";
    }
    return macAddress;
  }
  
  // ISO formátumú időbélyeg generálása YYYY-MM-DDTHH:MM:SS.sss+00:00 formátumban
  String _getCurrentIsoTimestamp() {
    final now = DateTime.now().toUtc();
    // 3 tizedesjegyet tartalmazó formátum létrehozása
    final String formatted = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T"
                          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}."
                          "${(now.millisecond).toString().padLeft(3, '0')}+00:00";
    return formatted;
  }
  
  // Gyónás aktiválása egy templomban
  Future<Map<String, dynamic>> activateConfession(int churchId, bool isActive) async {
    const uuid = Uuid();
    final macAddress = await _getDeviceMacAddress();
    final timestamp = _getCurrentIsoTimestamp();
    print(macAddress);
    final response = await http.post(
      Uri.parse('$baseUrl$lorawanEndpoint'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'deduplicationId': uuid.v4(),
        'time': timestamp,
        'deviceInfo': {
          'tags': {
            'local_id': 0,
            'templom_id': churchId
          },
          'devEui': macAddress
        },
        'object': {
          'Mód': 2,
          'Status_Leak': isActive ? 1 : 0,
        }
      }),
    );
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      (await SharedPreferences.getInstance()).setInt('active_confession', isActive ? churchId : -1);
      return responseData;
    } else {
      throw Exception('Sikertelen gyónás aktiválás: ${response.statusCode}');
    }
  }
}
