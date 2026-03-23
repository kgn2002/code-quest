import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  final String baseUrl = "http://10.0.2.2:8000";

  // --- 1. CODE EXECUTION ---
  Future<Map<String, dynamic>> checkPythonCode(String code, String expected) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/evaluate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code, 'expected_output': expected}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'is_correct': false, 'error': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'is_correct': false, 'error': 'Connection failed: $e'};
    }
  }

  // --- 2. AI LEARNING METRICS ---
  Future<Map<String, dynamic>> sendLearningMetrics({
    required String profileId,
    required String locationId,
    required int    errors,
    required double latency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-learning'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'profile_id':  profileId,
          'location_id': locationId,
          'errors':      errors,
          'latency':     latency,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('AI Sync: ${data['recommendation']} (score: ${data['fuzzy_score']})');
        return data;
      }
      debugPrint('AI Sync Failed: ${response.statusCode}');
      return {'recommendation': 'basic'};
    } catch (e) {
      debugPrint('AI network error: $e');
      return {'recommendation': 'basic'};
    }
  }

  // --- 3. BLOCKCHAIN CERTIFICATE GENERATION ---
  Future<Map<String, dynamic>> generateCertificate({
    required String       profileId,
    required String       username,
    required int          totalXp,
    required List<String> completedQuests,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate-certificate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'profile_id':       profileId,
          'username':         username,
          'total_xp':         totalXp,
          'completed_quests': completedQuests,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('🏆 Certificate minted — Block #${data['block_index']}');
        return data;
      }
      return {'success': false, 'error': 'Server error: ${response.statusCode}'};
    } catch (e) {
      debugPrint('Certificate error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- 4. MASTER CHALLENGE UNLOCK VERIFICATION ---
  // Asks the backend to check Supabase directly — prevents players from
  // bypassing the gate by manually editing their completed_quests in the DB.
  Future<Map<String, dynamic>> verifyMasterChallengeUnlock(
      String profileId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verify-unlock/$profileId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint(
            '🔐 Verify unlock: ${data['unlocked']} | missing: ${data['missing']}');
        return data;
      }
      // On server error, deny unlock for safety
      debugPrint('Verify unlock failed: ${response.statusCode}');
      return {'unlocked': false, 'missing': [], 'server_completed': []};
    } catch (e) {
      debugPrint('Verify unlock network error: $e');
      return {'unlocked': false, 'missing': [], 'server_completed': []};
    }
  }
}