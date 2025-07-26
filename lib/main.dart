import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/church_provider.dart';
import 'providers/confession_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/confession_active_screen.dart';
import 'services/enhanced_background_service.dart';
import 'widgets/exit_detector.dart';

void main() async {
  // Biztosítjuk, hogy a Flutter keretrendszer inicializálva legyen
  WidgetsFlutterBinding.ensureInitialized();
  
  // Állítsuk be a rendszer UI-t
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // A fejlesztett háttérszolgáltatás inicializálása
  await EnhancedBackgroundService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  @override
  void initState() {
    super.initState();
    // Alkalmazás kilépésének kezelése
    _setupExitHandling();
  }
  
  void _setupExitHandling() {
    // Android vissza gomb kezelése
    SystemChannels.platform.setMethodCallHandler((call) async {
      if (call.method == 'SystemNavigator.pop') {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final int? activeChurchId = prefs.getInt('active_confession');
        
        if (activeChurchId != null) {
          // Ha van aktív gyóntatás, megakadályozzuk a kilépést
          navigatorKey.currentState?.context.mounted ?? false
              ? ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
                  const SnackBar(
                    content: Text('A gyóntatás aktív, befejezés előtt nem lehet kilépni az alkalmazásból'),
                    duration: Duration(seconds: 3),
                  ),
                )
              : print('Nem lehet kilépni, mert aktív gyóntatás van');
              
          return Future.value(null);
        }
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChurchProvider()),
        ChangeNotifierProvider(create: (_) => ConfessionProvider()),
      ],
      child: ExitDetector(key: GlobalKey(),
        child: MaterialApp(
          title: 'Miserend.hu Templomok',
          navigatorKey: navigatorKey,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/confession': (context) => const ConfessionActiveScreen(),
          },
        ),
      ),
    );
  }
}

// A régi MyHomePage osztályt eltávolítottuk, mert most már külön képernyő osztályokat használunk
