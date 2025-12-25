// student/lib/main.dart

import 'package:flutter/material.dart';
import 'service/supabase_service.dart';
import 'page/student.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Mula Aplikasi Pelajar...');
  
  try {
    await SupabaseService.initialize();
    print('✅ Supabase dimulakan untuk Pelajar');
  } catch (e) {
    print('❌ Permulaan Supabase gagal: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CodeSprout🌱 Pelajar',
      theme: ThemeData(
        primarySwatch: Colors.green, // ✅ TUKAR KE HIJAU
        scaffoldBackgroundColor: Color(0xFFDFE5DB),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF7EA66B), // ✅ HIJAU UTAMA
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF7EA66B), // ✅ HIJAU UTAMA
          unselectedItemColor: Colors.grey[600],
        ),
      ),
      home: StudentPage(),
    );
  }
}