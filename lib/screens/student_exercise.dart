import 'package:flutter/material.dart';
import '../theme/color.dart';
import 'pdf_student_page.dart';
import 'mcq_student_page.dart';
import 'exercise_submission_page.dart';

class StudentExercisePage extends StatefulWidget {
  final int initialTabIndex;

  const StudentExercisePage({
    Key? key,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<StudentExercisePage> createState() => _StudentExercisePageState();
}

class _StudentExercisePageState extends State<StudentExercisePage> {
  late int _currentIndex;

  // ✅ TIGA PAGE SAHAJA
  final List<Widget> _pageList = [
    PdfStudentPage(),
    McqStudentPage(),
    ExerciseSubmissionPage(),
  ];

  @override
  void initState() {
    super.initState();

    // ✅ SAFETY: elak index out of range
    if (widget.initialTabIndex >= 0 &&
        widget.initialTabIndex < _pageList.length) {
      _currentIndex = widget.initialTabIndex;
    } else {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudentColors.background,
      body: _pageList[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color.fromARGB(255, 199, 221, 188),
        unselectedItemColor: const Color.fromARGB(255, 126, 124, 124),
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Bahan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Latihan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Hantar Tugas',
          ),
        ],
      ),
    );
  }
}
