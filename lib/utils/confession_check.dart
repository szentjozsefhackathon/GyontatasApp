import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/confession_provider.dart';

class ConfessionCheck {
  // Ellenőrzi, hogy van-e aktív gyóntatás, ha igen átirányít a gyóntatás képernyőre
  static void checkActiveConfession(BuildContext context) {
    final confessionProvider = Provider.of<ConfessionProvider>(context, listen: false);
    
    // Ha van aktív gyóntatás, átirányítás a gyóntatás oldalra
    if (confessionProvider.isActive) {
      Navigator.of(context).pushNamedAndRemoveUntil('/confession', (route) => false);
    }
  }
}
