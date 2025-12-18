import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_storage_helper.dart';
import 'edit_profile_student.dart';

class ViewProfilePage extends StatefulWidget {
  const ViewProfilePage({super.key});

  @override
  State<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
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
          .from("profile_student")
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
    final result = await storageHelper.pickAndUploadImage(bucketName: 'profile-images');
    if (result != null && result['url'] != null) {
      await supabase
          .from("profile_student")
          .update({"image_url": result['url']})
          .eq("id", supabase.auth.currentUser!.id);

      fetchProfile();
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
      return const Scaffold(
          body: Center(child: Text("No student profile found")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Profile",
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
                          backgroundImage: profile!['image_url'] != null
                              ? NetworkImage(profile!['image_url'])
                              : null,
                          child: profile!['image_url'] == null
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
                    profile!['full_name']?.toString().toUpperCase() ?? "STUDENT NAME",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile!['matric_no'] ?? "",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Role/Status card
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
                    profile!['institution']?.toString().toUpperCase() ?? "PELAJAR UNIVERSITI TEKNOLOGI MALAYSIA",
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
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditStudentProfilePage(),
                            ),
                          );
                          fetchProfile();
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
                        _detailRow("Email address", profile!['email'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Phone Number", profile!['phone'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Age", profile!['age']?.toString() ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Class", profile!['class'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Timezone", "Asia/Kuala_Lumpur"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Miscellaneous Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Miscellaneous",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
                        _linkRow("Blog entries", () {}),
                        const Divider(height: 24),
                        _linkRow("Forum posts", () {}),
                        const Divider(height: 24),
                        _linkRow("Forum discussions", () {}),
                        const Divider(height: 24),
                        _linkRow("Learning plans", () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Reports Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Reports",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
                        _linkRow("Browser sessions", () {}),
                        const Divider(height: 24),
                        _linkRow("Grades overview", () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
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

  Widget _linkRow(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}