// teacher/lib/main.dart
import 'package:flutter/material.dart';
import 'service/supabase_service.dart';
import 'page/teacher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeSprout🌱',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Color(0xFFDFE5DB),
      ),
      home: TeacherPage(),
    );
  }
}