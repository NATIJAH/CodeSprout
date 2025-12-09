import 'package:flutter/material.dart';
import 'student_task.dart';
import 'student_teaching_material.dart';
import 'student_pdf.dart';
import 'student_mcq.dart';
import 'open_student_chat.dart';
import 'student_profile.dart';
import 'student_notification.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  Widget _buildCard(BuildContext context, String title, Color color, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8), // kurangkan padding supaya sesuai size kotak
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14, // adjust font ikut kotak baru
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = [
      _buildCard(context, "📌 Task", Colors.blue[300]!, const StudentTask()),
      _buildCard(context, "📚 Teaching Material", Colors.blue[400]!, const StudentTeachingMaterial()),
      _buildCard(context, "📄 PDF", Colors.blue[300]!, const StudentPdf()),
      _buildCard(context, "❓ MCQ", Colors.blue[400]!, const StudentMcq()),
      _buildCard(context, "💬 Chat", Colors.blue[300]!, const OpenStudentChat()),
      _buildCard(context, "👤 Profile", Colors.blue[400]!, const StudentProfile()),
      _buildCard(context, "🔔 Notification", Colors.blue[300]!, const StudentNotification()),
    ];

    return Scaffold(
      backgroundColor: const Color(0xffdfeee7),
      appBar: AppBar(
        title: const Text("👩‍🎓 Student Dashboard"),
        backgroundColor: const Color(0xff4f7f67),
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
