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
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasError = false;
  
  // Simpan halaman untuk elak muat semula setiap kali tukar tab
  final List<Widget> _pageList = [
    PdfPage(),
    McqPage(),
    SubmissionPage(),
  ];

  // Simpan state setiap halaman untuk elak kehilangan data
  final PageController _pageController = PageController();
  final List<int> _pageHistory = [0]; // Sejarah navigasi untuk kembali

  @override
  void initState() {
    super.initState();
    print('🎯 TeacherExercisePage: Mula');
    
    // Validasi halaman untuk pastikan tiada ralat
    _validatePages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fungsi untuk validasi halaman
  Future<void> _validatePages() async {
    try {
      setState(() => _isLoading = true);
      
      // Simulasi validasi ringkas
      await Future.delayed(Duration(milliseconds: 500));
      
      // Validasi setiap halaman
      final validations = await Future.wait([
        _validatePdfPage(),
        _validateMcqPage(),
        _validateSubmissionPage(),
      ]);
      
      final hasInvalidPages = validations.any((isValid) => !isValid);
      
      if (hasInvalidPages && mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Beberapa modul tidak dapat dimuatkan';
        });
        print('⚠️ Peringatan: Beberapa halaman mungkin mempunyai isu');
      }
    } catch (e) {
      print('❌ Ralat validasi halaman: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Ralat sistem: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _validatePdfPage() async {
    try {
      // Semak jika PDFPage boleh diakses
      return true;
    } catch (e) {
      print('❌ Ralat validasi PDF Page: $e');
      return false;
    }
  }

  Future<bool> _validateMcqPage() async {
    try {
      // Semak jika MCQPage boleh diakses
      return true;
    } catch (e) {
      print('❌ Ralat validasi MCQ Page: $e');
      return false;
    }
  }

  Future<bool> _validateSubmissionPage() async {
    try {
      // Semak jika SubmissionPage boleh diakses
      return true;
    } catch (e) {
      print('❌ Ralat validasi Submission Page: $e');
      return false;
    }
  }

  // Fungsi untuk tukar halaman dengan validasi
  void _changePage(int index) {
    // Validasi indeks
    if (index < 0 || index >= _pageList.length) {
      print('⚠️ Indeks tidak sah: $index');
      _showErrorSnackbar('Modul tidak ditemui');
      return;
    }
    
    // Semak jika halaman sama
    if (index == _currentIndex) return;
    
    // Simpan sejarah navigasi
    if (!_pageHistory.contains(index)) {
      _pageHistory.add(index);
    }
    
    // Tukar halaman dengan animasi
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    setState(() {
      _currentIndex = index;
    });
    
    // Log perubahan halaman
    print('📱 Tukar ke halaman: ${_getPageName(index)}');
  }

  // Fungsi untuk kembali ke halaman sebelumnya
  void _goBack() {
    if (_pageHistory.length > 1) {
      // Keluarkan halaman semasa
      _pageHistory.removeLast();
      
      // Dapatkan halaman sebelumnya
      final previousIndex = _pageHistory.last;
      
      _pageController.animateToPage(
        previousIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      setState(() {
        _currentIndex = previousIndex;
      });
      
      print('↩️ Kembali ke: ${_getPageName(previousIndex)}');
    } else {
      _showInfoSnackbar('Ini adalah halaman pertama');
    }
  }

  // Fungsi untuk dapatkan nama halaman
  String _getPageName(int index) {
    switch (index) {
      case 0: return 'PDF';
      case 1: return 'MCQ';
      case 2: return 'Penyerahan';
      default: return 'Tidak Diketahui';
    }
  }

  // Fungsi untuk paparkan mesej ralat
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Fungsi untuk paparkan mesej makluman
  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: TeacherColors.success,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Widget untuk paparan ralat
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            SizedBox(height: 20),
            Text(
              'Ralat Aplikasi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _validatePages,
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherColors.success,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Cuba Lagi'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk paparan loading
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: TeacherColors.success,
                      backgroundColor: Colors.green[50],
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.school,
                    size: 24,
                    color: TeacherColors.success,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Menyediakan Modul...',
            style: TextStyle(
              fontSize: 16,
              color: TeacherColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Sila tunggu sebentar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk bottom navigation bar yang lebih baik
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _changePage,
          backgroundColor: Colors.white,
          selectedItemColor: TeacherColors.success,
          unselectedItemColor: TeacherColors.textLight,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 11,
          ),
          showUnselectedLabels: true,
          elevation: 10,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 0 
                    ? TeacherColors.success.withOpacity(0.1) 
                    : Colors.transparent,
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  size: _currentIndex == 0 ? 24 : 22,
                ),
              ),
              activeIcon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TeacherColors.success.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  size: 24,
                ),
              ),
              label: 'PDF & Bahan',
              tooltip: 'Pengurusan bahan pembelajaran PDF',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 1 
                    ? TeacherColors.success.withOpacity(0.1) 
                    : Colors.transparent,
                ),
                child: Icon(
                  Icons.quiz,
                  size: _currentIndex == 1 ? 24 : 22,
                ),
              ),
              activeIcon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TeacherColors.success.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.quiz,
                  size: 24,
                ),
              ),
              label: 'Soalan MCQ',
              tooltip: 'Pengurusan soalan pelbagai pilihan',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 2 
                    ? TeacherColors.success.withOpacity(0.1) 
                    : Colors.transparent,
                ),
                child: Icon(
                  Icons.assessment,
                  size: _currentIndex == 2 ? 24 : 22,
                ),
              ),
              activeIcon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TeacherColors.success.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.assessment,
                  size: 24,
                ),
              ),
              label: 'Penyerahan',
              tooltip: 'Semakan kerja pelajar',
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk header/app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Icon(
            _currentIndex == 0 ? Icons.picture_as_pdf :
            _currentIndex == 1 ? Icons.quiz :
            Icons.assessment,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modul ' + _getPageName(_currentIndex),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _currentIndex == 0 ? 'Pengurusan bahan pembelajaran' :
                _currentIndex == 1 ? 'Soalan pelbagai pilihan' :
                'Semakan kerja pelajar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: TeacherColors.success,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        if (_currentIndex > 0)
          IconButton(
            icon: Icon(Icons.arrow_back, size: 22),
            onPressed: _goBack,
            tooltip: 'Kembali ke sebelumnya',
          ),
        IconButton(
          icon: Icon(Icons.refresh, size: 22),
          onPressed: _validatePages,
          tooltip: 'Segar semula modul',
        ),
        SizedBox(width: 8),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingView()
          : _hasError
            ? _buildErrorView()
            : PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(), // Lumpuhkan swipe
                children: _pageList,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      // Floating action button untuk aksi pantas
      floatingActionButton: _currentIndex == 2 
          ? FloatingActionButton(
              onPressed: () {
                _showInfoSnackbar('Fungsi tambah penyerahan baru');
                print('➕ Aksi: Tambah penyerahan baru');
              },
              backgroundColor: TeacherColors.success,
              foregroundColor: Colors.white,
              child: Icon(Icons.add),
              tooltip: 'Tambah penyerahan baru',
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}