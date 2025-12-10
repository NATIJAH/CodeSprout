/*import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://fyvfocfbxrdaoyecbfzm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5dmZvY2ZieHJkYW95ZWNiZnptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4MzAxMzEsImV4cCI6MjA3OTQwNjEzMX0.R-Gtwp0Xmg9KUWGn6zV0G7xxYVX0QiWvTCfq3-MwpU4',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeSprout',
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(), // Changed to AuthWrapper
    );
  }
}

// This widget handles authentication state
class AuthWrapper extends StatefulWidget {
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SupabaseClient supabase = Supabase.instance.client;
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _user = data.session?.user;
      });
    });
  }

  Future<void> _checkAuth() async {
    final session = supabase.auth.currentSession;
    setState(() {
      _user = session?.user;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If user is logged in, go to dashboard. Otherwise, show login screen
    if (_user != null) {
      // Here you can check user role and navigate accordingly
      // For now, we'll assume all logged in users are students
      return StudentDashboard();
    } else {
      return LoginScreen();
    }
  }
}*/

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/teacher_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://fyvfocfbxrdaoyecbfzm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5dmZvY2ZieHJkYW95ZWNiZnptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4MzAxMzEsImV4cCI6MjA3OTQwNjEzMX0.R-Gtwp0Xmg9KUWGn6zV0G7xxYVX0QiWvTCfq3-MwpU4',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeSprout',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff7a9e8f)),
        primaryColor: const Color(0xff7a9e8f),
        scaffoldBackgroundColor: const Color(0xfff0f3f1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff7a9e8f),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: false,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xff2d3d38)),
          bodyMedium: TextStyle(color: Color(0xff2d3d38)),
          titleLarge: TextStyle(color: Color(0xff2d3d38)),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xff7a9e8f),
          textColor: Color(0xff2d3d38),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        cardColor: Color(0xfffafbfa),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff7a9e8f),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xff7a9e8f)),
      ),
      home: AuthWrapper(), // Use AuthWrapper instead of direct LoginScreen
    );
  }
}

// This widget checks authentication status and redirects accordingly
class AuthWrapper extends StatefulWidget {
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Check if user is already logged in
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final user = session.user;
      // Check if user is a teacher
      try {
        final teacherData = await Supabase.instance.client
            .from('profile_teacher')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();

        if (teacherData != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const TeacherDashboard()),
            );
          });
          return;
        }
      } catch (e) {
        debugPrint('Error checking teacher role: $e');
      }

      // Default to student dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StudentDashboard()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}