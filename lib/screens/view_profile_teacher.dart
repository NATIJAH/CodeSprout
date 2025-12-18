import 'package:flutter/material.dart';

class ViewProfileTeacher extends StatelessWidget {
  final Map<String, dynamic> profile;

  const ViewProfileTeacher({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final img = profile["avatar_url"] ?? '';
    final fullName = profile["full_name"] ?? "Unknown";
    final phone = profile["phone"] ?? "-";
    final subject = profile["subject"] ?? "-";

    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: img != '' ? NetworkImage(img) : null,
              child: img == '' ? Text(fullName[0], style: const TextStyle(fontSize: 50)) : null,
            ),
            const SizedBox(height: 20),
            Text("Name: $fullName", style: const TextStyle(fontSize: 18)),
            Text("Phone: $phone", style: const TextStyle(fontSize: 16)),
            Text("Subject: $subject", style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
