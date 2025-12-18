import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'teacher_account_edit.dart';

class TeacherAccountPage extends StatefulWidget {
  const TeacherAccountPage({super.key});

  @override
  State<TeacherAccountPage> createState() => _TeacherAccountPageState();
}

class _TeacherAccountPageState extends State<TeacherAccountPage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? account;

  @override
  void initState() {
    super.initState();
    fetchAccount();
  }

  Future<void> fetchAccount() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    final data = await supabase
        .from('account_teacher')
        .select()
        .eq('id', user.id)
        .single();

    setState(() {
      account = data;
    });
  }

  Future<void> deleteAccount() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    // Delete SQL record
    await supabase.from('account_teacher').delete().eq('id', user.id);

    // Delete auth user
    await supabase.auth.admin.deleteUser(user.id);

    // Sign out
    await supabase.auth.signOut();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (account == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email: ${account!['email']}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text("Registered: ${account!['register_at']}"),
            const SizedBox(height: 10),
            Text("Active: ${account!['is_active']}"),
            const SizedBox(height: 10),
            Text("Login Count: ${account!['login_count']}"),
            const SizedBox(height: 30),

            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherAccountEditPage(account: account!),
                      ),
                    );
                  },
                  child: const Text("Edit Account"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: deleteAccount,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Delete Account"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
