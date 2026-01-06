import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditTeacherProfilePage extends StatefulWidget {
  const EditTeacherProfilePage({super.key});

  @override
  State<EditTeacherProfilePage> createState() => _EditTeacherProfilePageState();
}

class _EditTeacherProfilePageState extends State<EditTeacherProfilePage> {
  final supabase = Supabase.instance.client;

  final institutionController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final subjectController = TextEditingController();

  File? newImage;
  String? imageUrl;
  bool isLoading = true;
  bool isSaving = false;

  String selectedState = 'Johor';
  String selectedTimezone = 'Asia/Kuala_Lumpur';

  final Color accentColor = const Color(0xFF0066CC);
  final Color backgroundColor = const Color(0xFFF5F5F5);

  // Malaysian states with their corresponding timezones
  final Map<String, String> stateTimezones = {
    'Johor': 'Asia/Kuala_Lumpur',
    'Kedah': 'Asia/Kuala_Lumpur',
    'Kelantan': 'Asia/Kuala_Lumpur',
    'Melaka': 'Asia/Kuala_Lumpur',
    'Negeri Sembilan': 'Asia/Kuala_Lumpur',
    'Pahang': 'Asia/Kuala_Lumpur',
    'Penang': 'Asia/Kuala_Lumpur',
    'Perak': 'Asia/Kuala_Lumpur',
    'Perlis': 'Asia/Kuala_Lumpur',
    'Sabah': 'Asia/Kuching',
    'Sarawak': 'Asia/Kuching',
    'Selangor': 'Asia/Kuala_Lumpur',
    'Terengganu': 'Asia/Kuala_Lumpur',
    'Kuala Lumpur': 'Asia/Kuala_Lumpur',
    'Labuan': 'Asia/Kuching',
    'Putrajaya': 'Asia/Kuala_Lumpur',
  };

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() => isLoading = true);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('profile_teacher')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        institutionController.text = data['institution'] ?? '';
        fullNameController.text = data['full_name'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? '';
        subjectController.text = data['subject'] ?? '';
        selectedState = data['state'] ?? 'Johor';
        selectedTimezone = data['timezone'] ?? stateTimezones[selectedState] ?? 'Asia/Kuala_Lumpur';
        imageUrl = data['avatar_url'];
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() => newImage = File(picked.path));
    }
  }

  Future<String> uploadProfileImage(File file) async {
    final userId = supabase.auth.currentUser!.id;
    final bytes = await file.readAsBytes();
    final String path = "teacher-profiles/$userId-${DateTime.now().millisecondsSinceEpoch}.jpg";

    await supabase.storage.from('profile-images').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: "image/jpeg", upsert: true),
    );

    return supabase.storage.from('profile-images').getPublicUrl(path);
  }

  Future<void> saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => isSaving = true);

    try {
      String? finalImage = imageUrl;

      if (newImage != null) {
        finalImage = await uploadProfileImage(newImage!);
      }

      await supabase.from('profile_teacher').upsert({
        'id': user.id,
        'institution': institutionController.text.trim(),
        'full_name': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'subject': subjectController.text.trim(),
        'state': selectedState,
        'timezone': selectedTimezone,
        'avatar_url': finalImage,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );

      // Tell the caller the profile was updated so it can refresh
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: saveProfile,
              child: Text("Save", style: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 16)),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // profile photo
          Center(
            child: Column(children: [
              GestureDetector(
                onTap: pickImage,
                child: Stack(children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: newImage != null
                          ? FileImage(newImage!)
                          : (imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) as ImageProvider : null),
                      child: newImage == null && (imageUrl == null || imageUrl!.isEmpty) ? Icon(Icons.person, size: 60, color: Colors.grey[600]) : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text("Change Photo"),
                style: TextButton.styleFrom(foregroundColor: accentColor),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Institution block
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Institution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              buildInput("Institution / Teacher Type", institutionController, Icons.location_city),
            ]),
          ),

          const SizedBox(height: 20),

          // personal info box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Personal Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              buildInput("Full Name", fullNameController, Icons.person_outline),
              buildInput("Email Address", emailController, Icons.email_outlined),
              buildInput("Phone Number", phoneController, Icons.phone_outlined),
              buildInput("Subject", subjectController, Icons.menu_book_outlined),

              // State dropdown
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("State", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!, width: 1.5)),
                    child: DropdownButtonFormField<String>(
                      value: selectedState,
                      decoration: InputDecoration(prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey[600]), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: InputBorder.none),
                      dropdownColor: Colors.white,
                      items: stateTimezones.keys.map((String state) {
                        return DropdownMenuItem<String>(value: state, child: Text(state));
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedState = newValue;
                            selectedTimezone = stateTimezones[newValue]!;
                          });
                        }
                      },
                    ),
                  ),
                ]),
              ),

              // Timezone (read-only)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Timezone", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!, width: 1.5)),
                    child: DropdownButtonFormField<String>(
                      value: selectedTimezone,
                      onChanged: null, // read-only
                      decoration: InputDecoration(prefixIcon: Icon(Icons.access_time_outlined, color: Colors.grey[600]), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: InputBorder.none),
                      items: const [
                        DropdownMenuItem(value: 'Asia/Kuala_Lumpur', child: Text('Asia/Kuala_Lumpur (GMT+8)')),
                        DropdownMenuItem(value: 'Asia/Kuching', child: Text('Asia/Kuching (GMT+8)')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Text("Timezone is automatically set based on your state", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                  ),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 28),

          // Save & Cancel buttons
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isSaving ? null : saveProfile,
              style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
              child: isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(foregroundColor: accentColor, side: BorderSide(color: accentColor, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Cancel", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 28),
        ]),
      ),
    );
  }

  Widget buildInput(String label, TextEditingController controller, IconData icon, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: backgroundColor,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            hintText: "Enter $label",
            hintStyle: TextStyle(color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5), borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor, width: 2), borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    institutionController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    subjectController.dispose();
    super.dispose();
  }
}
