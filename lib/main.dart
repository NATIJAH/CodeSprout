import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Screens
import 'screens/chat_home_screen.dart';
import 'screens/open_student_chat.dart';
import 'screens/open_teacher_chat.dart';
import 'screens/student_dashboard.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://fyvfocfbxrdaoyecbfzm.supabase.co', // Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5dmZvY2ZieHJkYW95ZWNiZnptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4MzAxMzEsImV4cCI6MjA3OTQwNjEzMX0.R-Gtwp0Xmg9KUWGn6zV0G7xxYVX0QiWvTCfq3-MwpU4', // Replace with your Supabase anon key
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Communication App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF128C7E), // WhatsApp green
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF128C7E),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      // Update your routes in main.dart:
routes: {
  '/login': (context) => const LoginScreen(),
  '/student-dashboard': (context) => StudentDashboard(
        userId: Supabase.instance.client.auth.currentUser?.id ?? '',
        onSignOut: () {
          Supabase.instance.client.auth.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
  '/teacher-dashboard': (context) => TeacherDashboard(
        userId: Supabase.instance.client.auth.currentUser?.id ?? '',
        onSignOut: () {
          Supabase.instance.client.auth.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
  '/student-chat': (context) => const OpenStudentChat(),
  '/teacher-chat': (context) => const OpenTeacherChat(),
},
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final supabase = Supabase.instance.client;
  User? _user;
  String? _userType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    // Listen for auth state changes
    supabase.auth.onAuthStateChange.listen((AuthState data) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    try {
      final session = supabase.auth.currentSession;
      final user = supabase.auth.currentUser;
      
      if (session != null && user != null) {
        // Determine user type by checking which profile table has the user
        final studentProfile = await supabase
            .from('profile_student')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();

        final teacherProfile = await supabase
            .from('profile_teacher')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();

        setState(() {
          _user = user;
          _userType = studentProfile != null ? 'student' : 
                     teacherProfile != null ? 'teacher' : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _user = null;
          _userType = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking auth: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      setState(() {
        _user = null;
        _userType = null;
      });
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_user == null || _userType == null) {
      return const LoginScreen();
    }

    // Redirect based on user type
    return _userType == 'student'
        ? StudentDashboard(
            userId: _user!.id,
            onSignOut: _signOut,
          )
        : TeacherDashboard(
            userId: _user!.id,
            onSignOut: _signOut,
          );
  }
}

// Update StudentDashboard and TeacherDashboard to accept parameters
class StudentDashboard extends StatelessWidget {
  final String userId;
  final VoidCallback onSignOut;
  
  const StudentDashboard({
    super.key,
    required this.userId,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.pushNamed(context, '/student-chat');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onSignOut,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome Student!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/student-chat');
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat),
                  SizedBox(width: 8),
                  Text('Open Chat'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherDashboard extends StatelessWidget {
  final String userId;
  final VoidCallback onSignOut;
  
  const TeacherDashboard({
    super.key,
    required this.userId,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.pushNamed(context, '/teacher-chat');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onSignOut,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome Teacher!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/teacher-chat');
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat),
                  SizedBox(width: 8),
                  Text('Open Chat'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}