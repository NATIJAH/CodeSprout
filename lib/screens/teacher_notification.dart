import 'package:flutter/material.dart';

class TeacherNotification extends StatelessWidget {
  const TeacherNotification({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🔔 Notification")),
      body: const Center(child: Text("Coming Soon!")),
    );
  }
}
