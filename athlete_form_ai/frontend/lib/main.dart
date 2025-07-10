import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'personalization_page.dart';
import 'history_page.dart';
import 'subscription_page.dart';
import 'success_page.dart';
import 'cancel_page.dart';
import 'connection_error_page.dart';
import 'config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Supabase.initialize(
      url: ApiConfig.supabaseUrl,
      anonKey: ApiConfig.supabaseAnonKey,
    );
    runApp(const TrackFieldApp());
  } catch (e) {
    runApp(ConnectionErrorApp(error: e.toString()));
  }
}

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

class TrackFieldApp extends StatefulWidget {
  const TrackFieldApp({Key? key}) : super(key: key);
  @override
  State<TrackFieldApp> createState() => _TrackFieldAppState();
}

class _TrackFieldAppState extends State<TrackFieldApp> {
  final ThemeNotifier _themeNotifier = ThemeNotifier();
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'TrackField',
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            brightness: Brightness.light,
            cardColor: Colors.white,
            scaffoldBackgroundColor: const Color(0xFFF6F3FA),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.deepPurple,
            brightness: Brightness.dark,
            cardColor: const Color(0xFF23223A),
            scaffoldBackgroundColor: const Color(0xFF181726),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          themeMode: _themeNotifier.themeMode,
          home: LoginPage(themeNotifier: _themeNotifier),
          routes: {
            '/subscription': (context) => SubscriptionPage(
              email: Supabase.instance.client.auth.currentUser?.email ?? '',
            ),
            '/success': (context) => const SuccessPage(),
            '/cancel': (context) => const CancelPage(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class ConnectionErrorApp extends StatelessWidget {
  final String error;

  const ConnectionErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dash AI - Connection Error',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F3FA),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF181726),
      ),
      home: ConnectionErrorPage(
        error: error,
        onRetry: () {
          // Restart the app to retry connection
          main();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const MainNavigation({Key? key, required this.themeNotifier}) : super(key: key);
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  static const List<String> _titles = ['Home', 'Profile', 'History'];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;
    final pages = [
      HomePage(themeNotifier: widget.themeNotifier),
      PersonalizationPage(),
      HistoryPage(themeNotifier: widget.themeNotifier),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: Icon(widget.themeNotifier.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => setState(() => widget.themeNotifier.toggleTheme()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(themeNotifier: widget.themeNotifier),
                  ),
                  (route) => false,
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history),
                  label: Text('History'),
                ),
              ],
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: pages[_selectedIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (idx) => setState(() => _selectedIndex = idx),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
              ],
            ),
    );
  }
}
