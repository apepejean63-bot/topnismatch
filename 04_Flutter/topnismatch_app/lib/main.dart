import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_profile_screen.dart';
import 'screens/premium_screen.dart'; // ← AGREGAR

void main() {
  runApp(const TopnisMatchApp());
}

class TopnisMatchApp extends StatelessWidget {
  const TopnisMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'TopnisMatch',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF4458)),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/create-profile': (context) => const CreateProfileScreen(),
          '/premium': (context) => const PremiumScreen(), // ← AGREGAR
        },
      ),
    );
  }
}
