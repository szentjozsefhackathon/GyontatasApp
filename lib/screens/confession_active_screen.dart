import 'dart:async';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/confession_provider.dart';
import '../utils/auth_check.dart';

class ConfessionActiveScreen extends StatefulWidget {
  const ConfessionActiveScreen({super.key});

  @override
  State<ConfessionActiveScreen> createState() => _ConfessionActiveScreenState();
}

class _ConfessionActiveScreenState extends State<ConfessionActiveScreen> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Ellenőrizzük a bejelentkezési állapotot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ellenőrzi, hogy a felhasználó be van-e jelentkezve
      AuthCheck.checkAuthentication(context);
      
      // Gyónás állapotának ellenőrzése
      final confessionProvider = Provider.of<ConfessionProvider>(context, listen: false);
      confessionProvider.checkConfessionStatus().then((_) {
        // Ha aktív gyóntatás van, elindítjuk az időzítőt
        if (confessionProvider.isActive) {
          _startRefreshTimer();
        }
      });
    });
  }
  
  // Időzítő indítása, ami 10 percenként frissíti a gyóntatás állapotát
  void _startRefreshTimer() {
    // Töröljük az esetleg már futó időzítőt
    _refreshTimer?.cancel();
    
    // Új időzítő indítása (10 perc = 600 másodperc)
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      final confessionProvider = Provider.of<ConfessionProvider>(context, listen: false);
      
      // Ha már nem aktív a gyóntatás, leállítjuk az időzítőt
      if (!confessionProvider.isActive) {
        _refreshTimer?.cancel();
        _refreshTimer = null;
        return;
      }
      
      // Frissítjük a gyóntatás állapotát az API-n keresztül
      try {
        await confessionProvider.activateConfession(confessionProvider.active, true);
        print('Gyóntatás állapot frissítve: ${DateTime.now()}');
      } catch (e) {
        print('Hiba történt a gyóntatás állapot frissítésekor: $e');
      }
    });
  }
  
  @override
  void dispose() {
    // Időzítő leállítása, amikor a widget megsemmisül
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Ellenőrizzük, hogy a felhasználó be van-e jelentkezve amikor visszatér az alkalmazásba
      AuthCheck.checkAuthentication(context);
      
      // Gyóntatás állapotának ellenőrzése
      final confessionProvider = Provider.of<ConfessionProvider>(context, listen: false);
      confessionProvider.checkConfessionStatus().then((_) {
        // Ha aktív gyóntatás van, de nincs futó időzítő, akkor elindítjuk
        if (confessionProvider.isActive && _refreshTimer == null) {
          _startRefreshTimer();
        } else if (!confessionProvider.isActive && _refreshTimer != null) {
          // Ha nincs aktív gyóntatás, de van időzítő, akkor leállítjuk
          _refreshTimer?.cancel();
          _refreshTimer = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final confessionProvider = Provider.of<ConfessionProvider>(context);

    return WillPopScope(
      // Megakadályozza a visszalépést, ha aktív gyóntatás van
      onWillPop: () async => !confessionProvider.isActive,
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
                          await confessionProvider.activateConfession(confessionProvider.active, false);
                          // Időzítő leállítása, amikor a gyóntatás befejeződik
                          _refreshTimer?.cancel();
                          _refreshTimer = null;
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