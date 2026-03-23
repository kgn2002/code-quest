import 'package:codequest/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'game_view.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _authService = AuthService();
  final _apiService = ApiService();

  bool _isLoading = false;

  void _signUp() async {
    // Validation: Ensure all fields are filled
    if (_emailController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields are required!"))
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Perform Auth via Supabase
    final error = await _authService.signUpUser(
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text,
      username: _usernameController.text.trim(),
    );

    if (error == null) {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        // --- FIXED CALL FOR SPRINT 4 & 5 ---
        // We use named parameters and add 'locationId' for your Metrics Study
        await _apiService.sendLearningMetrics(
          profileId: user.id,
          locationId: 'Registration', // Default location for first-time setup
          errors: 0,
          latency: 0.0,
        );

        if (!mounted) return;

        // 3. NAVIGATION: Clear stack to prevent back-button login glitch
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const GameView()),
              (Route<dynamic> route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Welcome to Code-Quest!"),
                backgroundColor: Colors.green
            )
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                )
            ),
            const SizedBox(height: 15),
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                )
            ),
            const SizedBox(height: 15),
            TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
                onPressed: _signUp,
                child: const Text("Join Quest", style: TextStyle(fontSize: 18)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context)=>const LoginScreen())),
              child: const Text("Already have an account? Login"),
            )
          ],
        ),
      ),
    );
  }
}