import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.text,
        password: password.text,
      );

      final user = response.user;
      if (user == null) {
        throw Exception("Login failed");
      }

      // Check if user is a teacher
      try {
        final teacherData = await Supabase.instance.client
            .from('profile_teacher')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();

        if (teacherData != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TeacherDashboard()),
          );
          return;
        }
      } catch (e) {
        debugPrint('Error checking teacher role: $e');
      }

      // Default to student dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
      );

    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ralat pengesahan: ${e.message}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ralat: $e")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f3f1),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                // App Logo/Title
                const Icon(
                  Icons.school,
                  size: 80,
                  color: Color(0xff7a9e8f),
                ),
                const SizedBox(height: 20),
                
                const Text(
                  "🍃 Selamat Kembali!",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2d3d38),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Log masuk untuk meneruskan",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // EMAIL FIELD
                TextField(
                  controller: email,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.email, color: Color(0xff7a9e8f)),
                    hintText: "Emel",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),

                // PASSWORD FIELD
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.lock, color: Color(0xff7a9e8f)),
                    hintText: "Kata laluan",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff7a9e8f),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 3,
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Log Masuk",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Sign up option
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ciri pendaftaran akan hadir tidak lama lagi!')),
                    );
                  },
                  child: const Text(
                    "Tiada akaun? Daftar",
                    style: TextStyle(
                      color: Color(0xff7a9e8f),
                      fontSize: 16,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }
}