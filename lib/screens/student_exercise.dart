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
  bool _isLoading = false;
  String? _errorMessage;

  // ✅ TIGA PAGE SAHAJA
  final List<Widget> _pageList = [
    PdfStudentPage(),
    McqStudentPage(),
    ExerciseSubmissionPage(),
  ];

  // Label untuk setiap tab
  final List<String> _tabLabels = [
    'Bahan',
    'Latihan',
    'Hantar Tugas',
  ];

  @override
  void initState() {
    super.initState();
    
    // Validasi initialTabIndex
    _validateAndSetInitialIndex();
  }

  void _validateAndSetInitialIndex() {
    try {
      if (widget.initialTabIndex >= 0 && 
          widget.initialTabIndex < _pageList.length) {
        _currentIndex = widget.initialTabIndex;
      } else {
        _currentIndex = 0;
        _showErrorMessage('Indeks tab tidak sah. Ditukar ke tab pertama.');
      }
    } catch (e) {
      _currentIndex = 0;
      _showErrorMessage('Ralat semasa memulakan tab: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleTabChange(int newIndex) async {
    // Validasi indeks
    if (newIndex < 0 || newIndex >= _pageList.length) {
      _showErrorMessage('Indeks tab tidak sah. Sila cuba lagi.');
      return;
    }

    // Tunjukkan loading jika proses panjang diperlukan
    if (newIndex != _currentIndex) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Simulasi delay untuk loading (boleh dialih keluar jika tidak diperlukan)
      await Future.delayed(const Duration(milliseconds: 300));

      try {
        setState(() {
          _currentIndex = newIndex;
          _isLoading = false;
        });
        
        // Tunjukkan mesej maklum balas
        _showSuccessMessage('Berjaya bertukar ke "${_tabLabels[newIndex]}"');
      } catch (e) {
        setState(() {
          _errorMessage = 'Gagal bertukar tab: ${e.toString()}';
          _isLoading = false;
        });
        _showErrorMessage(_errorMessage!);
      }
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Ralat tidak diketahui',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _currentIndex = 0;
              });
            },
            child: const Text('Kembali ke Halaman Utama'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudentColors.background,
      body: Stack(
        children: [
          // Kandungan utama
          if (_errorMessage != null)
            _buildErrorWidget()
          else
            _pageList[_currentIndex],

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _handleTabChange,
          selectedItemColor: const Color.fromARGB(255, 199, 221, 188),
          unselectedItemColor: const Color.fromARGB(255, 126, 124, 124),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          backgroundColor: Colors.white,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.library_books),
              ),
              label: 'Bahan',
              tooltip: 'Bahan Pembelajaran',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.quiz),
              ),
              label: 'Latihan',
              tooltip: 'Latihan dan Kuiz',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.upload_file),
              ),
              label: 'Hantar Tugas',
              tooltip: 'Hantar Tugasan',
            ),
          ],
        ),
      ),
    );
  }

  // Validasi sebelum keluar (jika diperlukan)
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      // Jika bukan di tab pertama, kembali ke tab pertama
      await _handleTabChange(0);
      return false; // Halang keluar
    }
    return true; // Benarkan keluar
  }
}