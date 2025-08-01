import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/confession_provider.dart';
import '../utils/service_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final confessionProvider = Provider.of<ConfessionProvider>(context, listen: false);
    
    // ServiceHandler inicializálása
    await ServiceHandler().initialize(context);
    
    // Ellenőrizzük a bejelentkezési állapotot
    await authProvider.checkLoginStatus();
    
    // Ellenőrizzük a gyóntatás állapotát
    await confessionProvider.checkConfessionStatus();
    
    if (mounted) {
      if (confessionProvider.isActive) {
        Navigator.pushReplacementNamed(context, '/confession');
      }
      else if (!authProvider.isLoggedIn) {
        // Ha nincs bejelentkezve, átirányítás a bejelentkezés oldalra
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // Ha be van jelentkezve és nincs aktív gyóntatás, átirányítás a főoldalra
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Miserend.hu',
              style: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24.0),
            const CircularProgressIndicator(),
            const SizedBox(height: 24.0),
            const Text('Betöltés...'),
          ],
        ),
      ),
    );
  }
}
