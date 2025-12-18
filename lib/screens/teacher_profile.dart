import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_storage_helper.dart';
import 'edit_profile_teacher.dart';

class ViewTeacherProfilePage extends StatefulWidget {
  const ViewTeacherProfilePage({super.key});

  @override
  State<ViewTeacherProfilePage> createState() => _ViewTeacherProfilePageState();
}

class _ViewTeacherProfilePageState extends State<ViewTeacherProfilePage> {
  final supabase = Supabase.instance.client;
  late SupabaseStorageHelper storageHelper;

  Map<String, dynamic>? profile;
  bool loading = true;
  String? errorMsg;

  // Color scheme
  final Color headerColor = const Color(0xFFE8F4F8);
  final Color cardColor = Colors.white;
  final Color accentColor = const Color(0xFF0066CC);

  @override
  void initState() {
    super.initState();
    storageHelper = SupabaseStorageHelper(supabase: supabase);
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    setState(() => loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          loading = false;
          errorMsg = "No user logged in";
        });
        return;
      }

      final data = await supabase
          .from("profile_teacher")
          .select()
          .eq("id", user.id)
          .maybeSingle();

      setState(() {
        profile = data;
        loading = false;
        errorMsg = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Error loading profile: $e";
      });
    }
  }

  Future<void> pickAndUploadImage() async {
    // Use your SupabaseStorageHelper to pick & upload; fallback to direct flow if needed
    final result = await storageHelper.pickAndUploadImage(bucketName: 'profile-images');
    if (result != null && result['url'] != null) {
      await supabase
          .from("profile_teacher")
          .update({"image_url": result['url']})
          .eq("id", supabase.auth.currentUser!.id);
      await fetchProfile();
    }
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

    if (profile == null) {
      return const Scaffold(body: Center(child: Text("No teacher profile found")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Teacher Profile",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section with profile picture and name
            Container(
              width: double.infinity,
              color: headerColor,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: profile!['image_url'] != null && profile!['image_url'] != ""
                              ? NetworkImage(profile!['image_url'])
                              : null,
                          child: profile!['image_url'] == null || profile!['image_url'] == ""
                              ? const Icon(Icons.person, size: 70, color: Colors.white)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    profile!['full_name']?.toString().toUpperCase() ?? "TEACHER NAME",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  // show institution under name (optional)
                  Text(
                    profile!['institution'] ?? "",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Role/Status card (subject)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Center(
                  child: Text(
                    (profile!['subject'] ?? "Teacher").toString().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // User Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "User details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          // navigate to edit and wait for result; if true, refresh
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditTeacherProfilePage(),
                            ),
                          );
                          if (updated == true) {
                            await fetchProfile();
                          }
                        },
                        child: Text(
                          "Edit profile",
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                      children: [
                        _detailRow("Full Name", profile!['full_name'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Email", profile!['email'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Phone Number", profile!['phone'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Institution", profile!['institution'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Subject", profile!['subject'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("State", profile!['state'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Timezone", profile!['timezone'] ?? "-"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
