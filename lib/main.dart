import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/teacher_dashboard.dart';
import 'providers/materials_provider.dart';
import 'services/supabase_service.dart';

const String TEACHER_INVITE_CODE = "SPROUT2025";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIXED: Changed from SupabaseClient.initialize to Supabase.initialize
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
  bool _isLoading = true;
  Session? _currentSession;

  @override
  void initState() {
    super.initState();
    
    // Get initial session immediately
    _currentSession = _supabase.auth.currentSession;
    _isLoading = false;
    
    // Set up auth state stream for real-time updates
    _authStateStream = _supabase.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Loading...'),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MaterialsProvider()),
        // Add other providers here if you have them
      ],
      child: MaterialApp(
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
            // Use the stream for real-time auth changes
            if (snapshot.hasData) {
              final session = snapshot.data?.session;
              
              if (session != null) {
                return AuthLoadingScreen(session: session);
              } else {
                return const LoginScreen();
              }
            }
            
            // If stream hasn't emitted yet, use the current session
            if (_currentSession != null) {
              return AuthLoadingScreen(session: _currentSession!);
            }
            
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

class AuthLoadingScreen extends StatefulWidget {
  final Session session;
  
  const AuthLoadingScreen({super.key, required this.session});

  @override
  State<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends State<AuthLoadingScreen> {
  final _supabase = Supabase.instance.client;
  bool _isChecking = true;
  bool _isTeacher = false;
  bool _isStudent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    final userId = widget.session.user.id;
    
    try {
      // Check teacher first
      final teacherResponse = await _supabase
          .from('profile_teacher')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (teacherResponse != null) {
        setState(() {
          _isTeacher = true;
          _isChecking = false;
        });
        return;
      }

      // Check student
      final studentResponse = await _supabase
          .from('profile_student')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (studentResponse != null) {
        setState(() {
          _isStudent = true;
          _isChecking = false;
        });
        return;
      }

      // No profile found
      setState(() {
        _errorMessage = 'No profile found for this user';
        _isChecking = false;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking user type: $e';
        _isChecking = false;
      });
    }
  }

  Future<void> _logoutAndRedirect() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
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

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _logoutAndRedirect,
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isTeacher) {
      return const TeacherDashboard();
    } else if (_isStudent) {
      return const StudentDashboard();
    }

    // Fallback - should not reach here
    return const LoginScreen();
  }
}