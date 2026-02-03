import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/navigation/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Sign in anonymously so users can log entries
  final client = Supabase.instance.client;
  if (client.auth.currentUser == null) {
    try {
      final response = await client.auth.signInAnonymously();
      if (response.user == null) {
        debugPrint('Warning: Anonymous sign-in returned null user');
      } else {
        debugPrint('Successfully signed in anonymously: ${response.user!.id}');
      }
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      debugPrint(
        'Please enable Anonymous authentication '
        'in your Supabase dashboard: Authentication > Providers > Anonymous',
      );
    }
  } else {
    debugPrint('User already authenticated: ${client.auth.currentUser!.id}');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitFlow AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}
