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
  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  // Email validation
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  // Password validation
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  Future<void> login() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (loading) return;

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
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        showError('Invalid email or password');
      } else if (e.message.contains('Email not confirmed')) {
        showError('Please verify your email before signing in');
      } else {
        showError(e.message);
      }
    } catch (e) {
      showError(e.toString());
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSending = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F8EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_reset,
                  color: Color(0xFF4F8E64),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Reset Kata Laluan",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Kami akan menghantar pautan reset kata laluan ke email anda.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[900],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Email",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F8E64),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: resetEmailController,
                  validator: validateEmail,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Masukkan email anda",
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF4F8E64),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF3FAF4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text("Batal", style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      if (formKey.currentState?.validate() ?? false) {
                        setDialogState(() => isSending = true);

                        try {
                          await Supabase.instance.client.auth.resetPasswordForEmail(
                            resetEmailController.text.trim(),
                            redirectTo: 'yourapp://reset-password', // Update with your app's deep link
                          );

                          if (!mounted) return;
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '✅ Email reset kata laluan telah dihantar! Sila semak email anda.',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Ralat: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setDialogState(() => isSending = false);
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F8E64),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Hantar", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
              child: Form(
                key: _formKey,
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

                    const SizedBox(height: 10),

                    const Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B8E77),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Email Field
                    _inputBox(
                      child: TextFormField(
                        controller: email,
                        validator: validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.mail_outline),
                          hintText: "Email",
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    _inputBox(
                      child: TextFormField(
                        controller: password,
                        validator: validatePassword,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: "Password",
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() => obscurePassword = !obscurePassword);
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Color(0xFF4F8E64),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

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
