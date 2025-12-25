import 'package:flutter/material.dart';
import '../theme/color.dart';
import 'pdf_student_page.dart';
import 'mcq_student_page.dart';
import 'exercise_submission_page.dart'; // HANYA INI SAHAJA

class StudentPage extends StatefulWidget {
  final int initialTabIndex;
  
  const StudentPage({Key? key, this.initialTabIndex = 0}) : super(key: key);
  
  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  // ✅ PASTI LIST INI BETUL - TIGA ITEM SAHAJA
  final List<Widget> _pageList = [
    PdfStudentPage(),
    McqStudentPage(),
    ExerciseSubmissionPage(), // NO PROGRESSPAGE HERE
  ];

  @override
  Widget build(BuildContext context) {
    print('🔄 DEBUG: Building StudentPage, tab: $_currentIndex');
    print('📱 DEBUG: Page at index 2 is: ${_pageList[2].runtimeType}');
    
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text('CodeSprout🌱 Pelajar'),
        backgroundColor: AppColor.success,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _pageList[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          print('🎯 Tab tapped: $index');
          setState(() => _currentIndex = index);
        },
        selectedItemColor: AppColor.success,
        unselectedItemColor: AppColor.textLight,
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
            icon: Icon(Icons.upload_file), // UPLOAD ICON
            label: 'Hantar Tugas', // UPLOAD LABEL
          ),
        ],
      ),
    );
  }
}