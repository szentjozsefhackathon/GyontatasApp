import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthCheck {
  // Ellenőrzi, hogy a felhasználó be van-e jelentkezve, ha nem átirányít a login oldalra
  static void checkAuthentication(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Ha nincs bejelentkezett felhasználó, átirányítás a login oldalra
    if (!authProvider.isLoggedIn) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
