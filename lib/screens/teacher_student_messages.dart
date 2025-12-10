import 'package:flutter/material.dart';

class TeacherStudentMessages extends StatelessWidget {
  const TeacherStudentMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Messages'),
        backgroundColor: const Color(0xff4f7f67),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Sample incoming message from student
          _buildMessageCard('Student2', 'Hi teacher, I have a question about the assignment.', '2:30 PM'),
          _buildMessageCard('Student1', 'When is the deadline for the project?', '1:15 PM'),
          _buildMessageCard('Student3', 'Can you extend the submission date?', '12:45 PM'),
        ],
      ),
    );
  }

  Widget _buildMessageCard(String studentName, String message, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xff7a9e8f),
          child: Text(
            studentName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          time,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: () {
          // TODO: Open chat with student
        },
      ),
    );
  }
}
