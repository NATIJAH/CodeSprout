// teacher/lib/page/teacher.dart
import 'package:flutter/material.dart';
import '../theme/color.dart';
import 'pdf_page.dart';  // DIRECT PDF PAGE (no folders)
import 'mcq_page.dart';
import 'submission_page.dart';

class TeacherExercise extends StatefulWidget {
  const TeacherExercise({super.key}); // Fixed: Added const constructor with key

  @override
  State<TeacherExercise> createState() => _TeacherExerciseState();
}

class _TeacherExerciseState extends State<TeacherExercise> {
  int _currentIndex = 0;
  final List<Widget> _pageList = [
    PdfPage(),  // DIRECT PDF PAGE
    McqPage(),
    SubmissionPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pageList[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.picture_as_pdf), label: 'PDF'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'MCQ'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Submissions'),
        ],
      ),
    );
  }
}