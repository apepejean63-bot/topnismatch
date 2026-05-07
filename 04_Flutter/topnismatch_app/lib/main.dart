import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_profile_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sauuevdgujejyyxbofvg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNhdXVldmRndWplanl5eGJvZnZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU5NTI5ODIsImV4cCI6MjA2MTUyODk4Mn0.Ry3QBbFLbMaVonhDSLHcIOOi6HqKBMDgFWkKGpQvDtM',
  );

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
          '/premium': (context) => const PremiumScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
