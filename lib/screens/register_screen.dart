import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:codesprout/main.dart' as app_main;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final invite = TextEditingController();

  String role = "student";
  bool loading = false;

  Future<void> register() async {
    setState(() => loading = true);

    final emailText = email.text.trim();
    final passText = password.text.trim();
    final inviteText = invite.text.trim();

    // Teacher invite code check
    if (role == "teacher" && inviteText != app_main.TEACHER_INVITE_CODE) {
      showError("Invalid teacher invite code");
      setState(() => loading = false);
      return;
    }

    try {
      // --- CREATE USER ---
      final authRes = await Supabase.instance.client.auth.signUp(
        email: emailText,
        password: passText,
      );

      final userId = authRes.user?.id;
      if (userId == null) {
        throw "Sign up failed. Email may already be used.";
      }

      // --- INSERT INTO STUDENT OR TEACHER PROFILE ---
      if (role == "student") {
        await Supabase.instance.client.from('profile_student').insert({
          'id': userId,
          'email': emailText,
        });
      } else {
        await Supabase.instance.client.from('profile_teacher').insert({
          'id': userId,
          'email': emailText,
        });
      }

      if (!mounted) return;
      Navigator.pop(context); // Back to login page

    } catch (e) {
      showError("Error: $e");
    }

    setState(() => loading = false);
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF8ED),
        elevation: 0,
        title: const Text(
          "🌱 Register",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A6F52),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _cuteBox(
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 14),

            _cuteBox(
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField(
              value: role,
              items: const [
                DropdownMenuItem(
                    value: "student", child: Text("Student 🌱")),
                DropdownMenuItem(
                    value: "teacher", child: Text("Teacher 🌱")),
              ],
              onChanged: (v) => setState(() => role = v!),
              decoration: InputDecoration(
                labelText: "Select Role",
                filled: true,
                fillColor: const Color(0xFFE9F8EA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            if (role == "teacher") ...[
              const SizedBox(height: 14),
              _cuteBox(
                TextField(
                  controller: invite,
                  decoration: const InputDecoration(
                    labelText: "Teacher Invite Code",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9ED2A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  loading ? "Creating..." : "Create Account 🌱",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cuteBox(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8EA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
