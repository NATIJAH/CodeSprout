// lib/screens/student_exercise.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/color.dart';
import '../screens/pdf_student_page.dart';
import '../screens/mcq_student_page.dart';
import '../screens/exercise_submission_page.dart';

class StudentExercise extends StatefulWidget {
  final int initialTabIndex;
  
  const StudentExercise({Key? key, this.initialTabIndex = 0}) : super(key: key);
  
  @override
  _StudentExerciseState createState() => _StudentExerciseState();
}

class _StudentExerciseState extends State<StudentExercise> {
  int _currentIndex = 0;
  
  // Store page instances to avoid recreating them
  late final List<Widget> _pageList;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    
    // Initialize pages once
    _pageList = [
      PdfStudentPage(),
      McqStudentPage(),
      ExerciseSubmissionPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🔄 DEBUG: Building StudentExercise, tab: $_currentIndex');
      print('📱 DEBUG: Page at index $_currentIndex is: ${_pageList[_currentIndex].runtimeType}');
    }
    
    return Scaffold(
      backgroundColor: StudentColors.background,
      
      body: IndexedStack(
        index: _currentIndex,
        children: _pageList,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (kDebugMode) {
            print('🎯 Tab tapped: $index');
          }
          setState(() => _currentIndex = index);
        },
        selectedItemColor: StudentColors.success,
        unselectedItemColor: StudentColors.textLight,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
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