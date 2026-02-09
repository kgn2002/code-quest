import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Get a reference to the Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- LOGIN METHOD (NEW) ---
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Authenticate with Supabase Auth
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on AuthException catch (e) {
      // Returns error messages like "Invalid login credentials"
      return e.message;
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  // --- SIGN UP METHOD (EXISTING) ---
  Future<String?> signUpUser({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final User? user = res.user;

      if (user != null) {
        await _supabase.from('profiles').insert({
          'id': user.id,
          'username': username,
          'total_xp': 0,
        });
        return null;
      }
      return "User creation failed.";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  // --- SIGN OUT METHOD (NEW) ---
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}