import 'package:flutter/material.dart';
import '../theme/color.dart';
import 'pdf_page.dart';
import 'mcq_page.dart';
import 'submission_page.dart';

class TeacherExercisePage extends StatefulWidget {
  const TeacherExercisePage({Key? key}) : super(key: key);

  @override
  State<TeacherExercisePage> createState() => _TeacherExercisePageState();
}

class _TeacherExercisePageState extends State<TeacherExercisePage> {
  int _currentIndex = 0;
 
  final List<Widget> _pageList = [
    PdfPage(),
    McqPage(),
    SubmissionPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      body: _pageList[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color.fromARGB(255, 187, 209, 176),
        unselectedItemColor: TeacherColors.textLight,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: 'PDF',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'MCQ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Penyerahan',
          ),
        ],
      ),
    );
  }
}