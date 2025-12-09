import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://fyvfocfbxrdaoyecbfzm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5dmZvY2ZieHJkYW95ZWNiZnptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4MzAxMzEsImV4cCI6MjA3OTQwNjEzMX0.R-Gtwp0Xmg9KUWGn6zV0G7xxYVX0QiWvTCfq3-MwpU4',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'CodeSprout',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
