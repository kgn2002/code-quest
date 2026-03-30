import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── LOGIN ────────────────────────────────────────────────────────────────
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  // ── SIGN UP ──────────────────────────────────────────────────────────────
  // Now accepts fullName and saves it to the profiles table.
  // The certificate will display this full name instead of username.
  Future<String?> signUpUser({
    required String fullName,   // ← NEW: student's real name for certificate
    required String username,   // in-game hero name shown in HUD
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create auth user — store both name fields in metadata
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username':  username,
          'full_name': fullName,    // ← stored in auth metadata too
        },
      );

      final user = response.user;
      if (user == null) return "Sign up failed. Please check your connection.";

      // 2. Insert into profiles table with full_name column
      await _supabase.from('profiles').upsert({
        'id':               user.id,
        'full_name':        fullName,   // ← NEW column
        'username':         username,
        'total_xp':         0,
        'completed_quests': [],
      });

      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return "This account already exists. Please try logging in.";
      }
      return "Database Error: ${e.message}";
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  // ── SIGN OUT ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}