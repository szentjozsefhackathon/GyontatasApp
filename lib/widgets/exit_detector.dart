import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Az alkalmazásból való kilépés kezelését végző osztály
class ExitDetector extends StatefulWidget {
  final Widget child;

  const ExitDetector({super.key, required this.child});

  @override
  State<ExitDetector> createState() => _ExitDetectorState();
}

class _ExitDetectorState extends State<ExitDetector> with WidgetsBindingObserver {
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      _checkIfCanExit();
    }
  }

  // Ellenőrzi, hogy lehet-e kilépni az alkalmazásból
  Future<bool> _checkIfCanExit() async {
    final prefs = await SharedPreferences.getInstance();
    final hasActiveConfession = prefs.getInt('active_confession') != null;

    if (hasActiveConfession) {
      _showConfessionActiveWarning();
      return false;
    }
    return true;
  }

  // Figyelmeztetés megjelenítése
  void _showConfessionActiveWarning() {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A gyóntatás aktív, befejezés előtt nem lehet kilépni az alkalmazásból'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Kettős vissza gomb kezelése Android eszközökön
  Future<bool> _handleBackButton() async {
    final canExit = await _checkIfCanExit();
    
    if (!canExit) {
      return false;
    }
    
    final now = DateTime.now();
    
    if (_lastBackPressTime == null || 
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nyomja meg újra a kilépéshez'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackButton,
      child: widget.child,
    );
  }
}
