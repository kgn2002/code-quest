// lib/secrets.dart
class Secrets {
  static const String supabaseUrl = 'https://czqudediffgptxndhwzt.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN6cXVkZWRpZmZncHR4bmRod3p0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwODI3MzUsImV4cCI6MjA4MjY1ODczNX0.LDUcVVnjEx5zNsQVAF-hWTGIK98_SwaIRNHu2hW-ZEM';

  // Also keep your FastAPI URL here as we planned earlier
  static const String fastApiBaseUrl = 'http://10.0.2.2:8000';
}
/*
class Secrets {
  static const String supabaseUrl = 'https://czqudediffgptxndhwzt.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN6cXVkZWRpZmZncHR4bmRod3p0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwODI3MzUsImV4cCI6MjA4MjY1ODczNX0.LDUcVVnjEx5zNsQVAF-hWTGIK98_SwaIRNHu2hW-ZEM';

  static const String _pcIp = '172.25.1.77'; // Your PC's WiFi IP

  // flutter run --dart-define=EMULATOR=true  ← emulator
  // flutter run                               ← physical phone
  static const bool _isEmulator =
  bool.fromEnvironment('EMULATOR', defaultValue: false);

  static const String fastApiBaseUrl =
  _isEmulator ? 'http://10.0.2.2:8000' : 'http://$_pcIp:8000';
}*/