import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateAccountSettingsPage extends StatefulWidget {
  const UpdateAccountSettingsPage({super.key});

  @override
  State<UpdateAccountSettingsPage> createState() => _UpdateAccountSettingsPageState();
}

class _UpdateAccountSettingsPageState extends State<UpdateAccountSettingsPage> {
  final supabase = Supabase.instance.client;

  final usernameController = TextEditingController();
  final bioController = TextEditingController();

  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await supabase
          .from('account_settings')
          .select()
          .eq('user_id', userId!)
          .maybeSingle();

      print("Flutter userId: $userId");
      print("Row received: $response");

      if (response != null) {
        usernameController.text = response['username'] ?? '';
        bioController.text = response['bio'] ?? '';
      }
    } catch (e) {
      print("Error loading data: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> saveData() async {
    if (userId == null) return;

    try {
      await supabase.from('account_settings').upsert({
        'user_id': userId,
        'username': usernameController.text.trim(),
        'bio': bioController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Error saving data: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f5f8), // soft pastel background
      appBar: AppBar(
        backgroundColor: Colors.pink.shade200,
        elevation: 0,
        title: const Text(
          "Edit Account Settings",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label("Username"),
                  _inputField(usernameController, "Enter username"),

                  const SizedBox(height: 20),

                  _label("Bio"),
                  _inputField(bioController, "Write something about yourself", maxLines: 3),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
