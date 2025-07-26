import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/confession_provider.dart';
import '../utils/auth_check.dart';
import '../utils/service_handler.dart';

class ConfessionActiveScreen extends StatefulWidget {
  const ConfessionActiveScreen({super.key});

  @override
  State<ConfessionActiveScreen> createState() => _ConfessionActiveScreenState();
}

class _ConfessionActiveScreenState extends State<ConfessionActiveScreen> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _isTimerActive = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Ellenőrizzük a bejelentkezési állapotot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ellenőrzi, hogy a felhasználó be van-e jelentkezve
      AuthCheck.checkAuthentication(context);
      
      // Service Handler inicializálása
      ServiceHandler().initialize(context);
      
      // Gyónás állapotának ellenőrzése és időzítő indítása
      final confessionProvider = Provider.of<ConfessionProvider>(context, listen: false);
      confessionProvider.checkConfessionStatus().then((_) {
        if (confessionProvider.isActive && !_isTimerActive) {
          _startRefreshTimer();
        }
      });
    });
  }
  
  // Időzítő indítása a 10 percenkénti frissítéshez
  void _startRefreshTimer() {
    if (_isTimerActive) return;
    
    _refreshTimer?.cancel();
    _isTimerActive = true;
    
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      // Ellenőrizzük, hogy a felhasználó be van-e jelentkezve
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.checkLoginStatus();
      
      if (!authProvider.isLoggedIn) {
        _stopTimer();
        return;
      }
      
      final confessionProvider = Provider.of<ConfessionProvider>(context, listen: false);
      await confessionProvider.checkConfessionStatus();
      
      if (confessionProvider.isActive) {
        try {
          print('Gyóntatás állapot frissítése: ${DateTime.now()}');
          await confessionProvider.activateConfession(confessionProvider.active, true);
        } catch (e) {
          print('Hiba történt a gyóntatás állapot frissítésekor: $e');
        }
      } else {
        _stopTimer();
      }
    });
    
    print('Gyóntatás időzítő elindítva - ${DateTime.now()}');
  }
  
  void _stopTimer() {
    if (_refreshTimer != null) {
      _refreshTimer!.cancel();
      _refreshTimer = null;
      _isTimerActive = false;
      print('Gyóntatás időzítő leállítva - ${DateTime.now()}');
    }
  }
  
  @override
  void dispose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Ellenőrizzük, hogy a felhasználó be van-e jelentkezve amikor visszatér az alkalmazásba
      AuthCheck.checkAuthentication(context);
      
      // Gyónás állapotának ellenőrzése és időzítő indítása, ha szükséges
      final confessionProvider = Provider.of<ConfessionProvider>(context, listen: false);
      confessionProvider.checkConfessionStatus().then((_) {
        if (confessionProvider.isActive && !_isTimerActive) {
          _startRefreshTimer();
        } else if (!confessionProvider.isActive && _isTimerActive) {
          _stopTimer();
        }
      });
    } else if (state == AppLifecycleState.inactive || 
              state == AppLifecycleState.paused) {
      // Ha az alkalmazás háttérbe kerül, de van aktív gyóntatás, 
      // akkor is folytatjuk az időzítőt
      final confessionProvider = Provider.of<ConfessionProvider>(context, listen: false);
      if (confessionProvider.isActive && !_isTimerActive) {
        _startRefreshTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final confessionProvider = Provider.of<ConfessionProvider>(context);

    return WillPopScope(
      // Megakadályozza a visszalépést, ha aktív gyóntatás van
      onWillPop: () async {
        // A ServiceHandler segítségével ellenőrizzük, hogy lehet-e kilépni
        return await ServiceHandler.onWillPop(context);
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Aktív Gyóntatás'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: !confessionProvider.isActive, // Csak akkor jelenjen meg a vissza gomb, ha nincs aktív gyóntatás
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await authProvider.checkLoginStatus();
              // Ellenőrzi, hogy a felhasználó be van-e jelentkezve a frissítés után
              AuthCheck.checkAuthentication(context);
              await confessionProvider.checkConfessionStatus();
            },
          ),
          if (!confessionProvider.isActive) // Csak akkor jelenjen meg a kijelentkezés gomb, ha nincs aktív gyóntatás
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
        ],
      ),
      body: confessionProvider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.church, 
                  size: 100,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),
                Text(
                  confessionProvider.isActive 
                    ? 'Gyóntatás aktív'
                    : 'Nincs aktív gyóntatás',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                if (confessionProvider.isActive)
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // A felugró ablak megjelenítése megerősítéshez
                        final bool? result = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text('Gyóntatás befejezése'),
                            content: const Text('Biztosan befejezi a gyóntatást?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Nem'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Igen'),
                              ),
                            ],
                          ),
                        );
                        
                        if (result == true) {
                          // Lekérjük a templom nevét a SharedPreferences-ből
                          final prefs = await SharedPreferences.getInstance();
                          final churchName = prefs.getString('active_church_name') ?? '';
                          
                          await confessionProvider.activateConfession(
                            confessionProvider.active, 
                            false,
                            churchName: churchName
                          );
                          
                          // Időzítő leállítása
                          _stopTimer();
                          
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/home');
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hiba történt: ${e.toString()}')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Gyóntatás befejezése'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                    child: const Text('Vissza a templomokhoz'),
                  )
              ],
            ),
          ),
      ),
    );
  }
}