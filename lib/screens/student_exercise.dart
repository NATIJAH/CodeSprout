import 'package:flutter/material.dart';
import '../theme/color.dart';
import 'pdf_student_page.dart';
import 'mcq_student_page.dart';
import 'progress_page.dart';

class StudentExercise extends StatefulWidget {
  @override
  _StudentExerciseState createState() => _StudentExerciseState();
}

class _StudentExerciseState extends State<StudentExercise> {
  int _currentIndex = 0;

  final List<Widget> _pageList = [
    PdfStudentPage(),  // Shows FOLDERS first (like teacher)
    McqStudentPage(),
    ProgressPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pageList[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: StudentColors.primaryBlue,
        unselectedItemColor: StudentColors.textLight,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Materials',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Practice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}