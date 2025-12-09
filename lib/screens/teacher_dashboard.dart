import 'package:flutter/material.dart';
import 'teacher_task.dart';
import 'teacher_teaching_material.dart';
import 'teacher_pdf.dart';
import 'teacher_mcq.dart';
import 'open_teacher_chat.dart';
import 'teacher_profile.dart';
import 'teacher_notification.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  Widget _buildCard(BuildContext context, String title, String emoji, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blueGrey.shade100, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 36), // bigger emoji for 120x120
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15, // slightly bigger text
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = [
      _buildCard(context, "Task", "📝", const TeacherTask()),
      _buildCard(context, "Materials", "📚", const TeacherTeachingMaterial()),
      _buildCard(context, "PDF", "📄", const TeacherPdf()),
      _buildCard(context, "MCQ", "❓", const TeacherMcq()),
      _buildCard(context, "Chat", "💬", const OpenTeacherChat()),
      _buildCard(context, "Profile", "👤", const TeacherProfile()),
      _buildCard(context, "Notification", "🔔", const TeacherNotification()),
    ];

    return Scaffold(
      backgroundColor: const Color(0xfff2f6ff),
      appBar: AppBar(
        title: const Text(
          "Teacher Dashboard",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff5b7cff),
        elevation: 4,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row atas: 4 kotak
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: cards.sublist(0, 4).map((c) => Padding(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: c,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              // Row bawah: 3 kotak
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: cards.sublist(4).map((c) => Padding(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: c,
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
