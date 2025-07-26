import 'package:flutter/material.dart';
import 'package:gyontatas_app/providers/confession_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/church_provider.dart';
import '../models/church.dart';
import '../utils/auth_check.dart';
import '../utils/confession_check.dart';
import '../utils/service_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Templomok lekérése a komponens betöltésekor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ellenőrzi, hogy a felhasználó be van-e jelentkezve
      AuthCheck.checkAuthentication(context);
      
      // Ellenőrzi, hogy van-e aktív gyóntatás
      final confessionProvider = Provider.of<ConfessionProvider>(context, listen: false);
      confessionProvider.checkConfessionStatus().then((_) {
        // Ha van aktív gyóntatás, átirányítás a gyóntatás képernyőre
        ConfessionCheck.checkActiveConfession(context);
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<ChurchProvider>(context, listen: false)
          .fetchResponsibilities(authProvider.currentUser?.responsibilities ?? []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final churchProvider = Provider.of<ChurchProvider>(context);
    final confessionProvider = Provider.of<ConfessionProvider>(context, listen: false);
    
    return WillPopScope(
      onWillPop: () async => await ServiceHandler.onWillPop(context),
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Miserend.hu - Templomok'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await authProvider.checkLoginStatus();
              // Ellenőrzi, hogy a felhasználó be van-e jelentkezve a frissítés után
              AuthCheck.checkAuthentication(context);
              churchProvider.fetchResponsibilities(authProvider.currentUser?.responsibilities ?? []);
            },
          ),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Üdvözöljük, ${authProvider.currentUser?.username ?? "Felhasználó"}!',
              style: const TextStyle(fontSize: 20.0),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Gondnokolt templomok',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8.0),
          if (churchProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (churchProvider.error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                churchProvider.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )
          else if (churchProvider.churches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Nincs gondnokolt templom',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => churchProvider.fetchResponsibilities(authProvider.currentUser?.responsibilities ?? []),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: churchProvider.churches.length,
                  itemBuilder: (context, index) {
                    final Church church = churchProvider.churches[index];
                    return ChurchListItem(church: church);
                  },
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}

class ChurchListItem extends StatelessWidget {
  final Church church;
  
  ChurchListItem({super.key, required this.church});
  
  // Gyónás aktiválása dialógus megjelenítése
  Future<void> _showConfessionDialog(BuildContext context) async {
    String displayName = church.knownName.isNotEmpty ? church.knownName : church.name;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Gyóntatás a(z) $displayName templomban'),
          content: const Text('Szeretné aktiválni a gyónást ebben a templomban?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Nem'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Igen'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                _activateConfession(context, true);
              },
            ),
          ],
        );
      },
    );
  }
  
  // Gyónás aktiválása API hívás
  Future<void> _activateConfession(BuildContext context, bool isActive) async {
    String displayName = church.knownName.isNotEmpty ? church.knownName : church.name;
    
    try {
      // ConfessionProvider használata gyónás aktiválásához
      final confessionProvider = Provider.of<ConfessionProvider>(context, listen: false);
      
      // Templom név mentése SharedPreferences-be
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_church_name', displayName);
      
      // Gyóntatás aktiválása templom nevével
      bool result = await confessionProvider.activateConfession(
        church.id, 
        isActive,
        churchName: displayName
      );
      
      if (result && context.mounted) {
        // Ha sikeres az aktiválás, átirányítás a gyóntatás képernyőre
        Navigator.of(context).pushReplacementNamed('/confession');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hiba történt: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Icon(Icons.church, color: Colors.deepPurple),
        ),
        title: Text(
          church.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (church.knownName.isNotEmpty)
              Text(church.knownName),
            Text(church.settlement),
          ],
        ),
        onTap: () {
          _showConfessionDialog(context);
        },
        onLongPress: () {
          // Templom részleteinek megnyitása hosszú nyomásra
          Provider.of<ChurchProvider>(context, listen: false)
              .fetchChurchDetails(church.id);
          // Értesítés megjelenítése a felhasználónak
          String displayName = church.knownName.isNotEmpty ? church.knownName : church.name;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$displayName részletei betöltése...')),
          );
        },
      ),
    );
  }
}
