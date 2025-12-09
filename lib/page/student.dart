import 'package:flutter/material.dart';
import '../theme/color.dart';
import 'pdf_student_page.dart';
import 'mcq_student_page.dart';
import 'progress_page.dart';

class StudentPage extends StatefulWidget {
  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  int _currentIndex = 0;

  final List<Widget> _pageList = [
    PdfStudentPage(),  // Shows FOLDERS first (like teacher)
    McqStudentPage(),
    ProgressPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text('CodeSprout🌱 Student'),
        backgroundColor: AppColor.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _pageList[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColor.primaryBlue,
        unselectedItemColor: AppColor.textLight,
        backgroundColor: Colors.white,
        items: [
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