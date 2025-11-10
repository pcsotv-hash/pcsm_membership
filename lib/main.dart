import 'package:flutter/material.dart';
import 'screens/membership_form.dart';
import 'screens/success_screen.dart';
import 'screens/admin_login.dart';
import 'screens/admin_dashboard.dart';

void main() { runApp(const PcsmApp()); }

class PcsmApp extends StatefulWidget {
  const PcsmApp({super.key});

  static PcsmAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<PcsmAppState>();
  }

  @override
  State<PcsmApp> createState() => PcsmAppState();
}

class PcsmAppState extends State<PcsmApp> {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    setState(() { _themeMode = mode; });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCSM Membership',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A6831),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A6831),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,
      initialRoute: '/',
      routes: {
        '/': (c)=> const MembershipForm(),
        '/success': (c)=> const SuccessScreen(),
        '/admin-login': (c)=> const AdminLoginScreen(),
        '/admin-dashboard': (c)=> const AdminDashboardScreen(),
      },
    );
  }
}
