import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://10.0.2.2:8000';

  Future<void> sendMetrics(String profileId, int errors, double time) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update-metric'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'profile_id': profileId, // Changed this to use the argument 'profileId'
        'errors': errors,
        'time_taken': time,
      }),
    );

    if (response.statusCode == 200) {
      print("Metrics sent to AI successfully!");
    } else {
      print("Failed to connect to FastAPI.");
    }
  }
}