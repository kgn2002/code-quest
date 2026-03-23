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

// lib/auth_service.dart
  Future<String?> signUpUser({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // 1. Attempt to Sign Up
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      final user = response.user;
      if (user == null) return "Sign up failed. Please check your connection.";

      // 2. Insert into Profiles table only if successful
      // Use upsert() instead of insert() to prevent the "duplicate key" error
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'username': username,
        'total_xp': 0,
        'completed_quests': [],
      });

      return null; // Success
    } on AuthException catch (e) {
      return e.message;
    } on PostgrestException catch (e) {
      // This catches the specific error shown in your screenshot
      if (e.code == '23505') {
        return "This account already exists. Please try logging in.";
      }
      return "Database Error: ${e.message}";
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  // --- SIGN OUT METHOD (NEW) ---
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}