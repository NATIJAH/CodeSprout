import 'package:flutter/material.dart';

class OpenStudentChat extends StatelessWidget {
  const OpenStudentChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Chat'),
        backgroundColor: const Color(0xff4f7f67),
      ),
      body: const Center(
        child: Text(
          'Chat feature coming soon...',
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      ),
    );
  }
}
