import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

// Screens
import 'screens/chat_home_screen.dart';
import 'screens/open_student_chat.dart';
import 'screens/open_teacher_chat.dart';
import 'screens/login_screen.dart';

// Providers
import 'providers/materials_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://fyvfocfbxrdaoyecbfzm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5dmZvY2ZieHJkYW95ZWNiZnptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4MzAxMzEsImV4cCI6MjA3OTQwNjEzMX0.R-Gtwp0Xmg9KUWGn6zV0G7xxYVX0QiWvTCfq3-MwpU4',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MaterialsProvider()),
      ],
      child: MaterialApp(
        title: 'CodeSprout',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xff4f7f67),
          scaffoldBackgroundColor: const Color(0xffdfeee7),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xff4f7f67),
            foregroundColor: Colors.white,
            elevation: 0,
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
        home: const AuthWrapper(),
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
      ),
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
    supabase.auth.onAuthStateChange.listen((AuthState data) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    try {
      final session = supabase.auth.currentSession;
      final user = supabase.auth.currentUser;

      if (session != null && user != null) {
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
          _userType = studentProfile != null
              ? 'student'
              : teacherProfile != null
                  ? 'teacher'
                  : null;
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null || _userType == null) {
      return const LoginScreen();
    }

    return _userType == 'student'
        ? StudentDashboard(userId: _user!.id, onSignOut: _signOut)
        : TeacherDashboard(userId: _user!.id, onSignOut: _signOut);
  }
}

// Inline StudentDashboard
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

// Inline TeacherDashboard
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
