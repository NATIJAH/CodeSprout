import 'package:flutter/material.dart';

class StudentNotification extends StatelessWidget {
  const StudentNotification({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🔔 Notification")),
      body: const Center(child: Text("Coming Soon!")),
    );
  }
}
