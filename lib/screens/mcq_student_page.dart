// lib/screens/mcq_student_page.dart
import 'package:flutter/material.dart';
import '../service/supabase_service.dart';
import '../theme/color.dart';
import 'student_exercise.dart';
import 'student_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class McqStudentPage extends StatefulWidget {
  @override
  _McqStudentPageState createState() => _McqStudentPageState();
}

class _McqStudentPageState extends State<McqStudentPage> {
  late final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _mcqSetList = [];
  Map<String, dynamic> _attemptsMap = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Pastikan pengguna telah log masuk
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Sila log masuk untuk mengakses ujian latihan';
          _isLoading = false;
        });
        return;
      }

      // Muat set MCQ dengan pengesahan
      final response = await _supabase
          .from('mcq_set')
          .select('*, mcq_question(count)')
          .order('created_at', ascending: false);

      // Pengesahan: Pastikan data diterima
      if (response == null) {
        throw Exception('Tiada data diterima dari pelayan');
      }

      // Muat percubaan pelajar
      final attemptsResponse = await _supabase
          .from('student_mcq_attempts')
          .select('*')
          .eq('student_id', user.id);

      // Tukar ke peta untuk carian mudah
      final Map<String, dynamic> tempAttemptsMap = {};
      if (attemptsResponse != null) {
        for (var attempt in attemptsResponse) {
          if (attempt['mcq_set_id'] != null) {
            tempAttemptsMap[attempt['mcq_set_id'].toString()] = attempt;
          }
        }
      }

      setState(() {
        _mcqSetList = List<Map<String, dynamic>>.from(response ?? []);
        _attemptsMap = tempAttemptsMap;
        _isLoading = false;
      });

    } catch (e) {
      print('Ralat memuat set MCQ: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuatkan ujian. Sila cuba lagi.';
      });
    }
  }

  void _startPractice(Map<String, dynamic> mcqSet) {
    // Pengesahan: Pastikan mcqSet ada ID
    if (mcqSet['id'] == null) {
      _showErrorDialog('Data ujian tidak sah. Sila hubungi guru.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => McqPracticePage(
          mcqSet: mcqSet,
          previousAttempt: _attemptsMap[mcqSet['id'].toString()],
        ),
      ),
    ).then((_) => _loadData());
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ralat'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetCard(Map<String, dynamic> mcqSet) {
    // Pengesahan data mcqSet
    final title = mcqSet['title']?.toString() ?? 'Tiada Tajuk';
    final description = mcqSet['description']?.toString();
    
    // Dapatkan bilangan soalan dengan pengesahan
    int questionCount = 0;
    try {
      if (mcqSet['mcq_question'] != null && 
          mcqSet['mcq_question'] is List && 
          mcqSet['mcq_question'].isNotEmpty) {
        questionCount = mcqSet['mcq_question'][0]['count'] ?? 0;
      }
    } catch (e) {
      questionCount = 0;
    }

    final previousAttempt = _attemptsMap[mcqSet['id'].toString()];
    final hasAttempt = previousAttempt != null;
    
    // Kira markah dengan pengesahan
    int score = 0;
    int total = questionCount;
    double percentage = 0;
    
    if (hasAttempt) {
      score = (previousAttempt['score'] as int?) ?? 0;
      total = (previousAttempt['total_questions'] as int?) ?? questionCount;
      percentage = total > 0 ? (score / total * 100) : 0;
    }

    return Card(
      elevation: 2,
      color: StudentColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _startPractice(mcqSet),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasAttempt
                      ? Color.fromARGB(255, 181, 214, 165).withOpacity(0.1)
                      : Color.fromARGB(255, 178, 206, 165).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasAttempt ? Icons.assignment_turned_in : Icons.quiz,
                  color: hasAttempt ? Color.fromARGB(255, 176, 199, 166) : StudentColors.primaryGreen,
                  size: 32,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: StudentColors.textDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasAttempt)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: StudentColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$score/$total',
                              style: TextStyle(
                                fontSize: 12,
                                color: StudentColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: StudentColors.textLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$questionCount soalan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: StudentColors.textLight,
                                ),
                              ),
                              if (hasAttempt) ...[
                                SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey[200],
                                  color: _getProgressColor(percentage),
                                  minHeight: 6,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: StudentColors.textLight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: StudentColors.primaryGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            hasAttempt ? 'Cuba Semula' : 'Mula',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return StudentColors.success;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: AppBar(
        title: Text('Ujian Latihan'),
        backgroundColor: StudentColors.topBar,
        foregroundColor: StudentColors.textDark,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Segar semula',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: StudentColors.primaryGreen))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 80, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 18, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text('Cuba Lagi'),
                      ),
                    ],
                  ),
                )
              : _mcqSetList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Tiada ujian latihan',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Guru anda akan tambah ujian latihan di sini',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: Text('Segar Semula'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: StudentColors.primaryGreen,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _mcqSetList.length,
                        itemBuilder: (context, index) {
                          final mcqSet = _mcqSetList[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: _buildSetCard(mcqSet),
                          );
                        },
                      ),
                    ),
    );
  }
}

class McqPracticePage extends StatefulWidget {
  final Map<String, dynamic> mcqSet;
  final Map<String, dynamic>? previousAttempt;

  const McqPracticePage({
    required this.mcqSet,
    this.previousAttempt,
  });

  @override
  _McqPracticePageState createState() => _McqPracticePageState();
}

class _McqPracticePageState extends State<McqPracticePage> {
  late final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _questions = [];
  Map<int, String> _selectedAnswers = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showResults = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _goBackToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDashboard(),
      ),
      (route) => false,
    );
  }

  void _goBackToMcqPage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => StudentExercisePage(initialTabIndex: 1),
      ),
      (route) => false,
    );
  }

  void _showBackOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Text(
              'Pilih destinasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.deepPurple),
              title: Text('Papan Pemuka'),
              subtitle: Text('Halaman utama dengan statistik'),
              onTap: () {
                Navigator.pop(context);
                _goBackToDashboard();
              },
            ),
            Divider(),
            
            ListTile(
              leading: Icon(Icons.quiz, color: StudentColors.primaryGreen),
              title: Text('Halaman Latihan'),
              subtitle: Text('Senarai semua ujian latihan'),
              onTap: () {
                Navigator.pop(context);
                _goBackToMcqPage();
              },
            ),
            Divider(),
            
            ListTile(
              leading: Icon(Icons.apps, color: Colors.blue),
              title: Text('Dashboard Modul'),
              subtitle: Text('Halaman dengan 3 tab (Bahan, Latihan, Hantar Tugas)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentExercisePage(initialTabIndex: 0),
                  ),
                  (route) => false,
                );
              },
            ),
            Divider(),
            
            ListTile(
              leading: Icon(Icons.cancel, color: Colors.grey),
              title: Text('Batal'),
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Pengesahan: Pastikan mcqSet ada ID
      if (widget.mcqSet['id'] == null) {
        throw Exception('ID ujian tidak sah');
      }

      final response = await _supabase
          .from('mcq_question')
          .select('*')
          .eq('mcq_set_id', widget.mcqSet['id'])
          .order('created_at', ascending: true);

      // Pengesahan: Pastikan data diterima
      if (response == null) {
        throw Exception('Tiada data soalan diterima');
      }

      List<Map<String, dynamic>> questions = [];
      if (response is List) {
        questions = List<Map<String, dynamic>>.from(response);
      }

      // Pengesahan: Pastikan soalan ada data yang diperlukan
      for (var question in questions) {
        if (question['question_text'] == null || question['question_text'].toString().isEmpty) {
          print('Amaran: Soalan tanpa teks ditemui');
        }
      }

      Map<int, String> loadedAnswers = {};
      if (widget.previousAttempt != null) {
        final answers = widget.previousAttempt!['answers'] ?? {};
        if (answers is Map) {
          for (int i = 0; i < questions.length; i++) {
            final questionId = questions[i]['id'].toString();
            if (answers.containsKey(questionId)) {
              final answer = answers[questionId];
              if (answer is String && answer.isNotEmpty) {
                loadedAnswers[i] = answer;
              }
            }
          }
        }
      }

      setState(() {
        _questions = questions;
        _selectedAnswers = loadedAnswers;
        _isLoading = false;
      });

    } catch (e) {
      print('Ralat memuat soalan: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuatkan soalan. Sila cuba lagi.';
      });
      
      // Tunjukkan mesej ralat kepada pengguna
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
  }

  void _selectAnswer(String answer) {
    // Pengesahan: Pastikan jawapan sah
    if (!['a', 'b', 'c', 'd'].contains(answer.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jawapan tidak sah'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedAnswers[_currentIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  bool _validateCurrentAnswer() {
    final selected = _selectedAnswers[_currentIndex];
    if (selected == null || selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sila pilih jawapan untuk soalan ini'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateAllAnswers() {
    List<int> unanswered = [];
    
    for (int i = 0; i < _questions.length; i++) {
      final selected = _selectedAnswers[i];
      if (selected == null || selected.isEmpty) {
        unanswered.add(i + 1);
      }
    }
    
    if (unanswered.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sila jawab semua soalan: ${unanswered.join(", ")}'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _submitTest() async {
    // Pengesahan: Pastikan ada soalan
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tiada soalan dalam ujian ini'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pengesahan: Pastikan semua soalan dijawab
    if (!_validateAllAnswers()) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: StudentColors.primaryGreen),
            SizedBox(height: 16),
            Text('Menghantar jawapan...'),
          ],
        ),
      ),
    );

    try {
      String guestStudentId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      String guestName = 'Pelajar Tetamu';
      
      int correctAnswers = 0;
      Map<String, dynamic> answers = {};
      
      // Kira markah dengan pengesahan
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final selected = _selectedAnswers[i] ?? '';
        final correct = question['correct_answer']?.toString() ?? '';
        
        answers[question['id'].toString()] = selected;
        
        if (selected == correct) {
          correctAnswers++;
        }
      }

      double percentage = _questions.length > 0 
          ? (correctAnswers / _questions.length * 100) 
          : 0;
      
      final now = DateTime.now().toIso8601String();
      final attemptData = {
        'student_id': guestStudentId,
        'mcq_set_id': widget.mcqSet['id'],
        'score': correctAnswers,
        'answers': answers,
        'total_questions': _questions.length,
        'correct_answers': correctAnswers,
        'is_completed': true,
        'completed_at': now,
        'started_at': now,
        'submitted_at': now,
        'student_name': guestName,
      };
      
      try {
        await _supabase
            .from('student_mcq_attempts')
            .insert(attemptData);
        print('Jawapan berjaya disimpan');
      } catch (dbError) {
        print('Ralat menyimpan ke pangkalan data: $dbError');
        // Teruskan walaupun gagal simpan
      }
      
      Navigator.pop(context); // Tutup dialog loading
      
      setState(() {
        _showResults = true;
        _result = {
          'score': correctAnswers,
          'total': _questions.length,
          'percentage': percentage,
        };
      });
      
    } catch (e) {
      Navigator.pop(context); // Tutup dialog loading
      print('Ralat dalam penyerahan: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghantar ujian: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      
      setState(() {
        _showResults = true;
        _result = {
          'score': 0,
          'total': _questions.length,
          'percentage': 0,
          'error': 'Gagal menghantar',
        };
      });
    }
  }

  Widget _buildQuestionCard() {
    if (_questions.isEmpty) {
      return Center(
        child: Text('Tiada soalan tersedia'),
      );
    }
    
    final question = _questions[_currentIndex];
    final selectedAnswer = _selectedAnswers[_currentIndex] ?? '';
    
    // Dapatkan teks soalan dengan pengesahan
    final questionText = question['question_text']?.toString() ?? '[Tiada teks soalan]';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Soalan ${_currentIndex + 1} daripada ${_questions.length}',
              style: TextStyle(
                fontSize: 14,
                color: StudentColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: StudentColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${((_currentIndex + 1) / _questions.length * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: StudentColors.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Card(
          elevation: 0,
          color: StudentColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              questionText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: StudentColors.textDark,
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Pilih jawapan anda:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: StudentColors.textDark,
          ),
        ),
        SizedBox(height: 12),
        ...['a', 'b', 'c', 'd'].map((option) {
          final optionText = question['option_$option']?.toString() ?? '[Tiada pilihan]';
          final isSelected = selectedAnswer == option;
          
          return GestureDetector(
            onTap: () => _selectAnswer(option),
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? StudentColors.primaryGreen.withOpacity(0.1)
                    : StudentColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? StudentColors.primaryGreen
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? StudentColors.primaryGreen
                      : Colors.grey[300],
                  radius: 16,
                  child: Text(
                    option.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : StudentColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  optionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: StudentColors.success)
                    : null,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildResults() {
    if (_result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Tiada keputusan tersedia'),
          ],
        ),
      );
    }
    
    final percentage = _result!['percentage'] ?? 0;
    final score = _result!['score'] ?? 0;
    final total = _result!['total'] ?? 0;

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: AppBar(
        title: Text('Keputusan Ujian'),
        backgroundColor: StudentColors.topBar,
        foregroundColor: StudentColors.textDark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _showBackOptions,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: StudentColors.success.withOpacity(0.2),
                          width: 10,
                        ),
                      ),
                    ),
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [StudentColors.success, Color(0xFF9BC588)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$score/$total betul',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                Card(
                  elevation: 2,
                  color: StudentColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildResultRow('Ujian:', widget.mcqSet['title']?.toString() ?? 'Tiada Tajuk'),
                        Divider(),
                        _buildResultRow('Markah Anda:', '$score daripada $total'),
                        Divider(),
                        _buildResultRow('Peratusan:', '${percentage.toStringAsFixed(1)}%'),
                        Divider(),
                        _buildResultRow(
                          'Status:',
                          percentage >= 80
                              ? 'Cemerlang! 🎉'
                              : percentage >= 60
                                  ? 'Baik! 👍'
                                  : percentage >= 40
                                      ? 'Memuaskan 😊'
                                      : 'Perlu usaha lagi 💪',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Button to view answers and explanations
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => McqReviewPage(
                                  mcqSet: widget.mcqSet,
                                  attempt: _result != null ? {
                                    'score': _result!['score'],
                                    'total_questions': _result!['total'],
                                  } : {},
                                  questions: _questions,
                                  selectedAnswers: _selectedAnswers,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'LIHAT JAWAPAN DAN NOTA GURU',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      ElevatedButton(
                        onPressed: _showBackOptions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StudentColors.success,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'KEMBALI',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showResults = false;
                            _selectedAnswers.clear();
                            _currentIndex = 0;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: StudentColors.success, width: 2),
                          ),
                        ),
                        child: Text(
                          'ULANG UJIAN INI',
                          style: TextStyle(
                            color: StudentColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: StudentColors.textLight,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: StudentColors.textDark,
            ),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.mcqSet['title']?.toString() ?? 'Ujian Latihan'),
          backgroundColor: StudentColors.topBar,
          foregroundColor: StudentColors.textDark,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: StudentColors.primaryGreen),
              SizedBox(height: 16),
              Text('Memuatkan soalan...'),
              if (_errorMessage != null) ...[
                SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadQuestions,
                  child: Text('Cuba Lagi'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_showResults) {
      return _buildResults();
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.mcqSet['title']?.toString() ?? 'Ujian Latihan'),
          backgroundColor: StudentColors.topBar,
          foregroundColor: StudentColors.textDark,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Tiada soalan dalam ujian ini',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Sila hubungi guru anda',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: AppBar(
        title: Text(widget.mcqSet['title']?.toString() ?? 'Ujian Latihan'),
        backgroundColor: StudentColors.topBar,
        foregroundColor: StudentColors.textDark,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _buildQuestionCard(),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: _previousQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentIndex > 0
                    ? StudentColors.primaryGreen
                    : Colors.grey[300],
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Sebelum',
                style: TextStyle(
                  color: _currentIndex > 0 ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Pengesahan: Pastikan soalan semasa dijawab
                if (!_validateCurrentAnswer()) {
                  return;
                }
                
                if (_currentIndex == _questions.length - 1) {
                  // Pengesahan: Pastikan semua soalan dijawab
                  if (!_validateAllAnswers()) {
                    return;
                  }
                  
                  // Tanya pengesahan sebelum hantar
                  bool confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Hantar Ujian'),
                      content: Text('Adakah anda pasti ingin menghantar ujian ini? Anda tidak boleh mengubah jawapan selepas penghantaran.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StudentColors.success,
                          ),
                          child: Text('Ya, Hantar'),
                        ),
                      ],
                    ),
                  ) ?? false;
                  
                  if (!confirm) return;
                  
                  await _submitTest();
                } else {
                  _nextQuestion();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentIndex == _questions.length - 1
                    ? StudentColors.success
                    : StudentColors.primaryGreen,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                _currentIndex == _questions.length - 1
                    ? 'HANTAR UJIAN'
                    : 'Seterusnya',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class McqReviewPage extends StatefulWidget {
  final Map<String, dynamic> mcqSet;
  final Map<String, dynamic> attempt;
  final List<Map<String, dynamic>> questions;
  final Map<int, String> selectedAnswers;

  const McqReviewPage({
    required this.mcqSet,
    required this.attempt,
    required this.questions,
    required this.selectedAnswers,
  });

  @override
  _McqReviewPageState createState() => _McqReviewPageState();
}

class _McqReviewPageState extends State<McqReviewPage> {
  void _goBackToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDashboard(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.attempt['score'] ?? 0;
    final total = widget.attempt['total_questions'] ?? widget.questions.length;
    final percentage = total > 0 ? (score / total * 100) : 0;

    // Pengesahan: Pastikan ada soalan
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Ulasan Ujian'),
          backgroundColor: StudentColors.topBar,
          foregroundColor: StudentColors.textDark,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('Tiada soalan untuk diulas'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: AppBar(
        title: Text('Ulasan Ujian'),
        backgroundColor: StudentColors.topBar,
        foregroundColor: StudentColors.textDark,
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: StudentColors.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  widget.mcqSet['title']?.toString() ?? 'Ujian Tanpa Tajuk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: StudentColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('$score/$total', 'Jawapan Betul'),
                    _buildStatCard('${percentage.toStringAsFixed(1)}%', 'Peratusan'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                return _buildQuestionReview(index);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _goBackToDashboard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'KEMBALI KE PAPAN PEMUKA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentExercisePage(initialTabIndex: 1),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StudentColors.primaryGreen,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'KEMBALI KE HALAMAN LATIHAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: StudentColors.primaryGreen,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: StudentColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionReview(int index) {
    final question = widget.questions[index];
    final questionNumber = index + 1;
    final selectedAnswer = widget.selectedAnswers[index] ?? '';
    final correctAnswer = question['correct_answer']?.toString() ?? '';
    final explanation = question['explanation']?.toString() ?? 'Tiada nota dari guru';
    final isCorrect = selectedAnswer == correctAnswer;

    // Dapatkan teks soalan dengan pengesahan
    final questionText = question['question_text']?.toString() ?? '[Tiada teks soalan]';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? StudentColors.success : Colors.red,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCorrect ? StudentColors.success.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isCorrect ? StudentColors.success : Colors.red,
                  radius: 14,
                  child: Text(
                    '$questionNumber',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Soalan $questionNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: StudentColors.textDark,
                    ),
                  ),
                ),
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? StudentColors.success : Colors.red,
                  size: 24,
                ),
              ],
            ),
          ),
          
          // Question Text
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              questionText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: StudentColors.textDark,
              ),
            ),
          ),
          
          Divider(height: 1),
          
          // Answers Section
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jawapan Anda:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: StudentColors.textLight,
                  ),
                ),
                SizedBox(height: 8),
                _buildAnswerDisplay(
                  selectedAnswer.isNotEmpty ? selectedAnswer : '-',
                  _getOptionText(question, selectedAnswer),
                  isCorrect ? StudentColors.success : Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  'Jawapan Betul:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: StudentColors.textLight,
                  ),
                ),
                SizedBox(height: 8),
                _buildAnswerDisplay(
                  correctAnswer.isNotEmpty ? correctAnswer : '-',
                  _getOptionText(question, correctAnswer),
                  StudentColors.success,
                ),
              ],
            ),
          ),
          
          Divider(height: 1),
          
          // Explanation Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Nota Guru:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  explanation,
                  style: TextStyle(
                    color: StudentColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOptionText(Map<String, dynamic> question, String option) {
    if (option.isEmpty || option == '-') return 'Tiada jawapan';
    
    // Dapatkan teks pilihan dengan pengesahan
    final optionText = question['option_$option']?.toString();
    
    if (optionText == null || optionText.isEmpty) {
      return 'Pilihan $option: [Tiada teks]';
    }
    
    return optionText;
  }

  Widget _buildAnswerDisplay(String option, String text, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 12,
            child: Text(
              option.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: StudentColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}