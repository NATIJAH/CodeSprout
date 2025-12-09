import 'package:flutter/material.dart';
import 'service/supabase_service.dart';
import 'page/student.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeSprout🌱 Student',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFEFF5FC), // Hardcoded color for now
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF4A90E2), // Hardcoded primary blue
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: StudentPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}