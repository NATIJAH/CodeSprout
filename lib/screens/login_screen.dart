import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final userId = res.user?.id;

      if (userId == null) {
        showError("Login failed");
        setState(() => loading = false);
        return;
      }

      // --- CHECK TEACHER PROFILE ---
      final teacher = await Supabase.instance.client
          .from('profile_teacher')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (teacher != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherDashboard()),
        );
        return;
      }

      // --- CHECK STUDENT PROFILE ---
      final student = await Supabase.instance.client
          .from('profile_student')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (student != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboard()),
        );
        return;
      }

      showError("No profile found for this user.");
    } catch (e) {
      showError(e.toString());
    }

    setState(() => loading = false);
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE9F8EF), Color(0xFFDFF7E5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "🌱 CodeSprout",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3F6B4D),
                    ),
                  ),

                  const SizedBox(height: 30),

                  _inputBox(
                    child: TextField(
                      controller: email,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.mail_outline),
                        hintText: "Email",
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _inputBox(
                    child: TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline),
                        hintText: "Password",
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  _greenButton(
                    text: loading ? "Please wait..." : "Log In",
                    onPressed: loading ? null : login,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            color: Color(0xFF4F8E64),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _greenButton({required String text, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8BD7A2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
