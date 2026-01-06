import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final fullName = TextEditingController();

  String role = "student";
  bool loading = false;
  bool obscurePassword = true;

  // Password strength
  bool get isPasswordStrong {
    final pass = password.text;
    return pass.length >= 8 &&
        pass.contains(RegExp(r'[A-Z]')) &&
        pass.contains(RegExp(r'[a-z]')) &&
        pass.contains(RegExp(r'[0-9]'));
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    fullName.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (loading) return;

    setState(() => loading = true);

    try {
      final emailText = email.text.trim();
      final passText = password.text.trim();
      final fullNameText = fullName.text.trim();

      // Validation
      if (fullNameText.isEmpty) {
        throw "Please enter your full name";
      }

      if (emailText.isEmpty) {
        throw "Please enter your email";
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailText)) {
        throw "Please enter a valid email address";
      }

      if (passText.isEmpty) {
        throw "Please enter a password";
      }

      if (!isPasswordStrong) {
        throw "Password must be at least 8 characters with uppercase, lowercase, and number";
      }

      print('🔐 Starting registration for: $emailText as $role');

      // Step 1: Create auth account
      final response = await Supabase.instance.client.auth.signUp(
        email: emailText,
        password: passText,
      );

      if (response.user == null) {
        throw "Registration failed. Please try a different email.";
      }

      final userId = response.user!.id;
      print('✅ Auth account created: $userId');

      // Step 2: Wait a moment for auth to fully propagate
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3: Create profile in appropriate table
      try {
        final profileData = {
          'id': userId,
          'email': emailText,
          'full_name': fullNameText,
        };

        if (role == "student") {
          await Supabase.instance.client
              .from('profile_student')
              .insert(profileData);
          print('✅ Student profile created');
        } else {
          await Supabase.instance.client
              .from('profile_teacher')
              .insert(profileData);
          print('✅ Teacher profile created');
        }
      } catch (e) {
        print('❌ Profile creation error: $e');
        
        // Provide detailed error for debugging
        if (e is PostgrestException) {
          throw "Database error (${e.code}): ${e.message}\n\n"
              "Common fixes:\n"
              "1. Check if profile_$role table exists\n"
              "2. Verify RLS policies allow INSERT\n"
              "3. Check table columns: id, email, full_name";
        }
        
        throw "Profile creation failed: ${e.toString()}";
      }

      if (!mounted) return;

      // Success!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎉 Account created! You can now log in."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Sign out and go back to login
      await Supabase.instance.client.auth.signOut();
      Navigator.pop(context);

    } catch (e) {
      print('❌ Registration error: $e');

      String errorMessage = e.toString();

      if (e is AuthException) {
        if (e.message.contains('already registered')) {
          errorMessage = "This email is already registered. Try logging in.";
        } else if (e.message.contains('rate limit')) {
          errorMessage = "Too many attempts. Please wait and try again.";
        } else {
          errorMessage = "Registration error: ${e.message}";
        }
      } else if (e is PostgrestException) {
        errorMessage = "Database error: ${e.message}\nCode: ${e.code}";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF8ED),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A6F52)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "🌱 Create Account",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A6F52),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Join CodeSprout",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A6F52),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Create your account to start learning",
              style: TextStyle(fontSize: 15, color: Color(0xFF6B8E77)),
            ),
            const SizedBox(height: 32),

            // Full Name
            _buildLabel("Full Name *"),
            _buildTextField(
              controller: fullName,
              hint: "Enter your full name",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            // Email
            _buildLabel("Email *"),
            _buildTextField(
              controller: email,
              hint: "your.email@example.com",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Password
            _buildLabel("Password *"),
            _buildTextField(
              controller: password,
              hint: "At least 8 characters, uppercase, lowercase, number",
              icon: Icons.lock_outline,
              isPassword: true,
              obscureText: obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF6B8E77),
                ),
                onPressed: () => setState(() => obscurePassword = !obscurePassword),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Password strength indicator
            if (password.text.isNotEmpty)
              Text(
                isPasswordStrong ? "✅ Strong password" : "⚠️ Password needs: 8+ chars, uppercase, lowercase, number",
                style: TextStyle(
                  fontSize: 12,
                  color: isPasswordStrong ? Colors.green : Colors.orange[800],
                ),
              ),
            const SizedBox(height: 16),

            // Role Selection
            _buildLabel("I am a *"),
            Row(
              children: [
                Expanded(
                  child: _buildRoleCard("student", "🌱 Student"),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRoleCard("teacher", "🌳 Teacher"),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Register Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: loading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BD7A2),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Create Account 🌱",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Login link
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Already have an account? Log in",
                  style: TextStyle(
                    color: Color(0xFF4A6F52),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A6F52),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8EA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: const Color(0xFF6B8E77)),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String value, String label) {
    final isSelected = role == value;
    return GestureDetector(
      onTap: () => setState(() => role = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8BD7A2) : const Color(0xFFE9F8EA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A6F52) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF4A6F52),
            ),
          ),
        ),
      ),
    );
  }
}