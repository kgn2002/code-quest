import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'game_view.dart';
import 'main.dart';

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
    // Check if essential fields are empty before proceeding
    if (_emailController.text.isEmpty || _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email and Username are required!"))
      );
      return;
    }

    setState(() => _isLoading = true);


    final error = await _authService.signUpUser(
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text,
      username: _usernameController.text.trim(),
    );

    if (error == null) {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        // Send initial metrics to your FastAPI Application Tier
        await _apiService.sendMetrics(user.id, 0, 0.0);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account Created! Entering Code-Quest..."))
        );

        // Move to the RPG world (Sprint 2)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  GameView()),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $error")));
    }

    setState(() => _isLoading = false);
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
                decoration: const InputDecoration(labelText: "Username")
            ),
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email")
            ),
            TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                onPressed: _signUp,
                child: const Text("Join Quest")
            ),
          ],
        ),
      ),
    );
  }
}