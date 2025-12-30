import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account_edit.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  final supabase = Supabase.instance.client;
  
  Map<String, dynamic>? accountData;
  bool loading = true;
  String? errorMsg;

  final Color accentColor = Color.fromARGB(255, 0, 0, 248);
  final Color cardColor = Colors.white;
  final Color headerColor = const Color(0xFFE8F4F8);
  final Color dangerColor = const Color(0xFFDC3545);

  @override
  void initState() {
    super.initState();
    fetchAccountData();
  }

  Future<void> fetchAccountData() async {
    setState(() => loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          loading = false;
          errorMsg = "Tiada pengguna log masuk";
        });
        return;
      }

      // Fetch from account_settings table
      final data = await supabase
          .from("account_settings")
          .select()
          .eq("user_id", user.id)
          .maybeSingle();

      setState(() {
        accountData = data ?? {
          'user_id': user.id,
          'username': user.email?.split('@')[0] ?? 'user',
          'auth_email': user.email,
          'account_type': 'Student',
          'status': 'Aktif',
          'email_notifications': true,
          'sms_notifications': false,
          'language': 'English',
          'privacy_level': 'Public',
        };
        loading = false;
        errorMsg = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Error loading account: $e";
      });
    }
  }

  Future<void> showDeleteAccountDialog() async {
    final confirmController = TextEditingController();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: dangerColor, size: 30),
            const SizedBox(width: 12),
            const Text(
              "Padam akaun",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tindakan ini TIDAK DAPAT DIBALIKKAN dan akan:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _dangerPoint("Padamkan semua data profil anda"),
            _dangerPoint("Alih keluar semua entri dan siaran blog"),
            _dangerPoint("Padamkan rancangan pembelajaran dan gred"),
            _dangerPoint("Tutup akaun anda secara kekal"),
            const SizedBox(height: 20),
            const Text(
              'Type "DELETE" to confirm:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: "PADAM",
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: dangerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: dangerColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batalkan"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (confirmController.text.trim() == "PADAM") {
                Navigator.pop(context);
                await deleteAccount();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type "DELETE" to confirm'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Padam Akaun"),
          ),
        ],
      ),
    );
  }

  Widget _dangerPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.close, color: dangerColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> deleteAccount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete all related data (cascade should handle this, but being explicit)
      await supabase.from('blog_entries').delete().eq('student_id', user.id);
      await supabase.from('forum_posts').delete().eq('student_id', user.id);
      await supabase.from('forum_discussions').delete().eq('student_id', user.id);
      await supabase.from('learning_plans').delete().eq('student_id', user.id);
      await supabase.from('browser_sessions').delete().eq('student_id', user.id);
      await supabase.from('grades').delete().eq('student_id', user.id);
      await supabase.from('profile_student').delete().eq('id', user.id);
      await supabase.from('account_settings').delete().eq('user_id', user.id);

      // Delete auth user (requires admin privileges or specific setup)
      // Note: This might need to be done via an Edge Function or Admin API
      await supabase.auth.signOut();

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Navigate to login/welcome screen
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akaun berjaya dipadamkan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> changePassword() async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tukar kata laluan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Kata laluan baru",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Sahkan kata laluan",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kata laluan tidak sepadan'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kata laluan mestilah sekurang-kurangnya 6 aksara'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await supabase.auth.updateUser(
                  UserAttributes(password: newPasswordController.text),
                );

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kata laluan berjaya ditukar'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Tukar kata laluan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMsg != null) {
      return Scaffold(body: Center(child: Text(errorMsg!)));
    }

    if (accountData == null) {
      return const Scaffold(
        body: Center(child: Text("No account data found")),
      );
    }

    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Tetapan Akaun",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              color: headerColor,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: accentColor,
                    child: Text(
                      accountData!['username']?.toString()[0].toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    accountData!['username'] ?? 'Username',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      accountData!['status'] ?? 'Aktif',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Account Information Section
            _buildSection(
              "Maklumat Akaun",
              [
                _infoTile("Nama Pengguna", accountData!['username'] ?? '-', Icons.person_outline),
                _infoTile("Email", user?.email ?? '-', Icons.email_outlined),
                _infoTile("Jenis Akaun", accountData!['account_type'] ?? 'Student', Icons.school_outlined),
                _infoTile("ID pengguna", user?.id ?? '-', Icons.fingerprint, isSmall: true),
                _infoTile("Dicipta", _formatDate(user?.createdAt), Icons.calendar_today_outlined),
              ],
              trailing: TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UpdateAccountSettingsPage(),
                    ),
                  );
                  fetchAccountData();
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text("Edit"),
              ),
            ),

            // Security Section
            _buildSection(
              "Keselamatan & Privasi",
              [
                _infoTile("Tahap privasi", accountData!['privacy_level'] ?? 'Public', Icons.privacy_tip_outlined),
                _actionTile("Tukar kata laluan", Icons.lock_outline, changePassword),
              ],
            ),

            // Preferences Section
            _buildSection(
              "Keutamaan",
              [
                _switchTile(
                  "Pemberitahuan Email",
                  accountData!['email_notifications'] ?? true,
                  Icons.email_outlined,
                  (value) async {
                    await supabase.from('account_settings').upsert({
                      'user_id': user?.id,
                      'email_notifications': value,
                    });
                    fetchAccountData();
                  },
                ),
                _switchTile(
                  "Pemberitahuan SMS",
                  accountData!['sms_notifications'] ?? false,
                  Icons.sms_outlined,
                  (value) async {
                    await supabase.from('account_settings').upsert({
                      'user_id': user?.id,
                      'sms_notifications': value,
                    });
                    fetchAccountData();
                  },
                ),
                _infoTile("Bahasa", accountData!['language'] ?? 'English', Icons.language_outlined),
              ],
            ),

            // Danger Zone
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dangerColor, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: dangerColor),
                        const SizedBox(width: 12),
                        const Text(
                          "Zon Bahaya",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Sebaik sahaja anda memadamkan akaun anda, anda tidak boleh kembali. Sila pastikan.",
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: showDeleteAccountDialog,
                        icon: const Icon(Icons.delete_forever),
                        label: const Text("Padam Akaun"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dangerColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon, {bool isSmall = false}) {
    return ListTile(
      leading: Icon(icon, color: accentColor),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: isSmall ? 11 : 14,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _switchTile(String label, bool value, IconData icon, Function(bool) onChanged) {
    return SwitchListTile(
      secondary: Icon(icon, color: accentColor),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      value: value,
      activeColor: accentColor,
      onChanged: onChanged,
    );
  }

  Widget _actionTile(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: accentColor),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '-';
    }
  }
}
