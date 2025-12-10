import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherAccountEditPage extends StatefulWidget {
  final Map<String, dynamic> account;
  const TeacherAccountEditPage({super.key, required this.account});

  @override
  State<TeacherAccountEditPage> createState() => _TeacherAccountEditPageState();
}

class _TeacherAccountEditPageState extends State<TeacherAccountEditPage> {
  final supabase = Supabase.instance.client;

  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.account['email']);
    passwordController = TextEditingController(text: widget.account['password']);
  }

  Future<void> saveChanges() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Update SQL table
    await supabase.from('account_teacher').update({
      'email': emailController.text,
      'password': passwordController.text,
    }).eq('id', user.id);

    // Update Supabase auth email
    await supabase.auth.updateUser(
      UserAttributes(email: emailController.text, password: passwordController.text),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Teacher Account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: saveChanges,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
