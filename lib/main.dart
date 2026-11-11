import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';





import 'models.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

const gardenGreen = Color(0xFF4CAF82);
const gardenDark = Color(0xFF0B1220);
const gardenForest = Color(0xFF1B3D2F);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GardenApp());
}

class GardenApp extends StatefulWidget {
  const GardenApp({super.key});

  @override
  State<GardenApp> createState() => _GardenAppState();
}

class _GardenAppState extends State<GardenApp> {
  Session? _session;
  bool _loading = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final p = await SharedPreferences.getInstance();
    final role = p.getString('role');
    _isDarkMode = p.getBool('isDarkMode') ?? false;

    if (role == 'gardener') {
      _session = const Session(Role.gardener);
    } else if (role == 'client' && p.getInt('clientId') != null) {
      _session = Session(Role.client, clientId: p.getInt('clientId'));
    }
    setState(() => _loading = false);
  }

  Future<void> _toggleDarkMode() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = !_isDarkMode);
    await p.setBool('isDarkMode', _isDarkMode);
  }

  Future<void> _login(Session s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('role', s.isGardener ? 'gardener' : 'client');
    if (s.clientId != null) await p.setInt('clientId', s.clientId!);
    setState(() => _session = s);
  }

  Future<void> _logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('role');
    await p.remove('clientId');
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GardenApp',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gardenGreen,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: gardenDark,
          foregroundColor: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gardenGreen,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _session == null
          ? LoginScreen(onLogin: _login)
          : HomeScreen(
        session: _session!,
        onLogout: _logout,
        isDarkMode: _isDarkMode,
        onToggleDarkMode: _toggleDarkMode,
      ),
    );
  }
}