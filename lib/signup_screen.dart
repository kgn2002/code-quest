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
  final _fullNameController   = TextEditingController(); // ← NEW
  final _usernameController   = TextEditingController();
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _authService          = AuthService();
  final _apiService           = ApiService();

  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    // Validate all fields including full name
    if (_fullNameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All fields are required!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.signUpUser(
      fullName: _fullNameController.text.trim(),   // ← NEW
      username: _usernameController.text.trim(),
      email:    _emailController.text.trim().toLowerCase(),
      password: _passwordController.text,
    );

    if (error == null) {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        await _apiService.sendLearningMetrics(
          profileId: user.id,
          locationId: 'Registration',
          errors: 0,
          latency: 0.0,
        );

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const GameView()),
              (Route<dynamic> route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Welcome to Code-Quest!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text(
          "Student Registration",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B4F8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              "Create your account",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4F8A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Fill in all details to begin your quest!",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 28),

            // ── Full Name ──────────────────────────────────────────────
            _buildField(
              controller: _fullNameController,
              label: "Full Name",
              hint: "Enter Your name",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            // ── Username ───────────────────────────────────────────────
            _buildField(
              controller: _usernameController,
              label: "Username",
              hint: "Your in-game hero name",
              icon: Icons.sports_esports_outlined,
            ),
            const SizedBox(height: 16),

            // ── Email ──────────────────────────────────────────────────
            _buildField(
              controller: _emailController,
              label: "Email",
              hint: "your@email.com",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // ── Password ───────────────────────────────────────────────
            _buildField(
              controller: _passwordController,
              label: "Password",
              hint: "Minimum 6 characters",
              icon: Icons.lock_outline,
              obscure: true,
            ),
            const SizedBox(height: 32),

            // ── Join Quest Button ──────────────────────────────────────
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _signUp,
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  "Join Quest",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4F8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Login link ─────────────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(color: Color(0xFF2E75B6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF2E75B6), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              const BorderSide(color: Color(0xFF2E75B6), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}