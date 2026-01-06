import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';

class ProfileDelete extends StatelessWidget {
  const ProfileDelete({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    // delete student profile if exists
    final student = await supabase.from('profile_student').select('id').eq('id', uid).maybeSingle();
    if (student != null) {
      await supabase.from('profile_student').delete().eq('id', uid);
    }

    // delete teacher profile if exists
    final teacher = await supabase.from('profile_teacher').select('id').eq('id', uid).maybeSingle();
    if (teacher != null) {
      await supabase.from('profile_teacher').delete().eq('id', uid);
    }

    // NOTE: deleting the Supabase Auth user requires a service role key and must be done on a server securely.
    // Attempting to call admin delete from the client will fail. Keep this safe:
    try {
      // This will throw in client environment: keep it wrapped to avoid crash.
      await supabase.auth.admin.deleteUser(uid);
    } catch (_) {
      // ignore: client cannot delete auth user
    }

    await supabase.auth.signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚠ Are you sure you want to permanently delete your profile?'),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _confirmDelete(context),
              child: const Text('Yes, delete'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ]),
        ),
      ),
    );
  }
}
