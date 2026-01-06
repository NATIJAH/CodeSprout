import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static late final SupabaseClient client;
  
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: 'https://fyvfocfbxrdaoyecbfzm.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5dmZvY2ZieHJkYW95ZWNiZnptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4MzAxMzEsImV4cCI6MjA3OTQwNjEzMX0.R-Gtwp0Xmg9KUWGn6zV0G7xxYVX0QiWvTCfq3-MwpU4',
      );
      client = Supabase.instance.client;
      
      print('✅ Supabase initialized successfully for Student!');
    } catch (e) {
      print('❌ Supabase initialization failed: $e');
    }
  }
}