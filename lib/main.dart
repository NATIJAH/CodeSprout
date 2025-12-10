import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/teacher_dashboard.dart';

const String TEACHER_INVITE_CODE = "SPROUT2025";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fyvfocfbxrdaoyecbfzm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5dmZvY2ZieHJkYW95ZWNiZnptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4MzAxMzEsImV4cCI6MjA3OTQwNjEzMX0.R-Gtwp0Xmg9KUWGn6zV0G7xxYVX0QiWvTCfq3-MwpU4',
  );

  runApp(const SproutApp());
}

class SproutApp extends StatefulWidget {
  const SproutApp({super.key});

  @override
  State<SproutApp> createState() => _SproutAppState();
}

class _SproutAppState extends State<SproutApp> {
  final _supabase = Supabase.instance.client;
  late Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = _supabase.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sprout App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9ED2A1),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4FDF5),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<AuthState>(
        stream: _authStateStream,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final authState = snapshot.data;
          final session = authState?.session;
          final user = session?.user;

          // User is logged in
          if (user != null) {
            // We need to check if user is teacher or student
            // Since we can't do async here, we'll redirect to a loading screen
            return const AuthLoadingScreen();
          }

          // User is not logged in
          return const LoginScreen();
        },
      ),
    );
  }
}

class AuthLoadingScreen extends StatefulWidget {
  const AuthLoadingScreen({super.key});

  @override
  State<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends State<AuthLoadingScreen> {
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    final userId = _supabase.auth.currentUser?.id;
    
    if (userId == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      // Check teacher first
      final teacher = await _supabase
          .from('profile_teacher')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (teacher != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherDashboard()),
        );
        return;
      }

      // Check student
      final student = await _supabase
          .from('profile_student')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (student != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboard()),
        );
        return;
      }

      // No profile found
      await _supabase.auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      print('Error checking user type: $e');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Checking user profile...'),
          ],
        ),
      ),
    );
  }
}