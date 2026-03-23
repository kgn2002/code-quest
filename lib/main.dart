import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'game_view.dart';
import 'scerts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    anonKey: Secrets.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code-Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/game': (context) => const GameView(),
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    // Listen for future auth changes (login / logout)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        // Only navigate to login when the user explicitly signs out
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
        );
      } else if (event == AuthChangeEvent.signedIn) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/game',
              (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check existing session IMMEDIATELY — no waiting for stream event.
    // This means hot restart / app reopen goes straight to game if
    // a valid session token is already stored on the device.
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      return const GameView();
    } else {
      return const LoginScreen();
    }
  }
}