//lib/screens/mcq_student_page.dart
import 'package:flutter/material.dart';
import '../service/supabase_service.dart';
import '../theme/color.dart';
import 'student_exercise.dart';
import 'student_dashboard.dart'; // ✅ IMPORT StudentDashboard
import 'package:supabase_flutter/supabase_flutter.dart';

class McqStudentPage extends StatefulWidget {
  @override
  _McqStudentPageState createState() => _McqStudentPageState();
}

class _McqStudentPageState extends State<McqStudentPage> {
  // ✅ FIXED: Changed to late final
  late final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _mcqSetList = [];
  Map<String, dynamic> _attemptsMap = {};
  bool _isLoading = true;
  String? _errorMessage;

  // ✅ DATA VALIDATION: Validators
  bool _validateMcqSetData(Map<String, dynamic> mcqSet) {
    if (mcqSet['id'] == null || mcqSet['id'].toString().isEmpty) {
      return false;
    }
    if (mcqSet['title'] == null || mcqSet['title'].toString().isEmpty) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> _sanitizeMcqSetData(Map<String, dynamic> rawData) {
    return {
      'id': rawData['id']?.toString() ?? '',
      'title': rawData['title']?.toString()?.trim() ?? 'Untitled Set',
      'description': rawData['description']?.toString()?.trim() ?? '',
      'created_at': rawData['created_at'] ?? DateTime.now().toIso8601String(),
      'mcq_question': rawData['mcq_question'] ?? [{'count': 0}],
    };
  }

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

      // Validate user authentication
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Sila log masuk untuk melihat ujian latihan';
          _isLoading = false;
        });
        return;
      }

      // ✅ DATA VALIDATION: Timeout untuk request
      final timeoutDuration = Duration(seconds: 30);
      
      // Muat set MCQ dengan validation
      final response = await _supabase
          .from('mcq_set')
          .select('*, mcq_question(count)')
          .order('created_at', ascending: false)
          .timeout(timeoutDuration, onTimeout: () {
            throw TimeoutException('Permintaan memakan masa terlalu lama. Sila periksa sambungan internet anda.');
          });

      if (response == null) {
        throw Exception('Tiada data diterima dari pelayan');
      }

      // ✅ DATA VALIDATION: Process and validate each MCQ set
      List<Map<String, dynamic>> validMcqSets = [];
      for (var item in response) {
        try {
          final sanitizedData = _sanitizeMcqSetData(item);
          if (_validateMcqSetData(sanitizedData)) {
            // Validate question count
            final questionData = sanitizedData['mcq_question'];
            if (questionData is List && questionData.isNotEmpty) {
              final count = questionData[0]['count'] ?? 0;
              if (count is int && count >= 0) {
                validMcqSets.add(sanitizedData);
              } else {
                print('⚠️ Invalid question count for set ${sanitizedData['id']}');
              }
            }
          }
        } catch (e) {
          print('⚠️ Error processing MCQ set: $e');
        }
      }

      // ✅ DATA VALIDATION: Validate attempts data
      final attemptsResponse = await _supabase
          .from('student_mcq_attempts')
          .select('*')
          .eq('student_id', user.id)
          .timeout(timeoutDuration, onTimeout: () {
            throw TimeoutException('Permintaan percubaan memakan masa terlalu lama.');
          });

      Map<String, dynamic> attemptsMap = {};
      if (attemptsResponse != null) {
        for (var attempt in attemptsResponse) {
          try {
            // Validate attempt data structure
            if (attempt['mcq_set_id'] != null && 
                attempt['score'] != null &&
                attempt['total_questions'] != null) {
              
              final setId = attempt['mcq_set_id'].toString();
              final score = attempt['score'] is int ? attempt['score'] : int.tryParse(attempt['score'].toString()) ?? 0;
              final total = attempt['total_questions'] is int ? attempt['total_questions'] : int.tryParse(attempt['total_questions'].toString()) ?? 0;
              
              // Validate score range
              if (score >= 0 && total >= 0 && score <= total) {
                attemptsMap[setId] = {
                  ...attempt,
                  'score': score,
                  'total_questions': total,
                };
              }
            }
          } catch (e) {
            print('⚠️ Error processing attempt data: $e');
          }
        }
      }

      setState(() {
        _mcqSetList = validMcqSets;
        _attemptsMap = attemptsMap;
        _isLoading = false;
      });
    } on TimeoutException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
      _showErrorSnackbar(e.message);
    } catch (e) {
      print('❌ Ralat memuat set MCQ: $e');
      setState(() {
        _errorMessage = 'Gagal memuat ujian latihan: ${e.toString()}';
        _isLoading = false;
      });
      _showErrorSnackbar('Gagal memuat ujian latihan');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: StudentColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startPractice(Map<String, dynamic> mcqSet) {
    // ✅ DATA VALIDATION: Validate before starting practice
    if (!_validateMcqSetData(mcqSet)) {
      _showErrorSnackbar('Set ujian tidak sah. Sila cuba lagi.');
      return;
    }

    final questionData = mcqSet['mcq_question'];
    final questionCount = questionData is List && questionData.isNotEmpty 
        ? (questionData[0]['count'] ?? 0)
        : 0;
    
    if (questionCount <= 0) {
      _showErrorSnackbar('Set ujian ini tiada soalan. Sila pilih set lain.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => McqPracticePage(
          mcqSet: mcqSet,
          previousAttempt: _attemptsMap[mcqSet['id']],
        ),
      ),
    ).then((_) {
      _loadData(); // Segar semula apabila kembali
      _showSuccessSnackbar('Ujian selesai!');
    });
  }

  Widget _buildSetCard(Map<String, dynamic> mcqSet) {
    // ✅ DATA VALIDATION: Safe data extraction
    final questionData = mcqSet['mcq_question'];
    final questionCount = questionData is List && questionData.isNotEmpty 
        ? (questionData[0]['count'] ?? 0)
        : 0;
    
    // Ensure questionCount is valid
    final safeQuestionCount = questionCount is int && questionCount >= 0 ? questionCount : 0;
    
    final previousAttempt = _attemptsMap[mcqSet['id']];
    final hasAttempt = previousAttempt != null && 
                      previousAttempt['score'] != null &&
                      previousAttempt['total_questions'] != null;
    
    int score = 0;
    int total = safeQuestionCount;
    double percentage = 0.0;
    
    if (hasAttempt) {
      score = previousAttempt['score'] is int 
          ? previousAttempt['score'] 
          : int.tryParse(previousAttempt['score'].toString()) ?? 0;
      
      total = previousAttempt['total_questions'] is int
          ? previousAttempt['total_questions']
          : int.tryParse(previousAttempt['total_questions'].toString()) ?? safeQuestionCount;
      
      // Validate score range
      score = score.clamp(0, total);
      percentage = total > 0 ? (score / total * 100) : 0;
    }

    // ✅ DATA VALIDATION: Safe text extraction
    final title = mcqSet['title']?.toString() ?? 'Untitled Set';
    final description = mcqSet['description']?.toString();
    
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
                      ? const Color.fromARGB(255, 181, 214, 165).withOpacity(0.1)
                      : const Color.fromARGB(255, 178, 206, 165).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasAttempt ? Icons.assignment_turned_in : Icons.quiz,
                  color: hasAttempt ? const Color.fromARGB(255, 176, 199, 166) : StudentColors.primaryGreen,
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
                        if (hasAttempt && score >= 0 && total >= 0)
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
                                '$safeQuestionCount soalan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: StudentColors.textLight,
                                ),
                              ),
                              if (hasAttempt && total > 0) ...[
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
    if (percentage.isNaN || percentage.isInfinite) return Colors.grey;
    if (percentage >= 80) return StudentColors.success;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Ralat tidak diketahui',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: StudentColors.primaryGreen,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Cuba Semula'),
          ),
        ],
      ),
    );
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
            onPressed: _loadData,
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: StudentColors.primaryGreen),
                  SizedBox(height: 16),
                  Text(
                    'Memuatkan ujian latihan...',
                    style: TextStyle(color: StudentColors.textLight),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
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
  // ✅ FIXED: Changed to late final
  late final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _questions = [];
  Map<int, String> _selectedAnswers = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showResults = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  // ✅ DATA VALIDATION: Validators for questions
  bool _validateQuestionData(Map<String, dynamic> question) {
    if (question['id'] == null) {
      return false;
    }
    
    final questionText = question['question_text']?.toString();
    if (questionText == null || questionText.trim().isEmpty) {
      return false;
    }
    
    // Validate that at least one option exists
    final hasOptions = ['a', 'b', 'c', 'd'].any((option) {
      final optionText = question['option_$option']?.toString();
      return optionText != null && optionText.trim().isNotEmpty;
    });
    
    if (!hasOptions) {
      return false;
    }
    
    // Validate correct answer
    final correctAnswer = question['correct_answer']?.toString();
    if (correctAnswer == null || !['a', 'b', 'c', 'd'].contains(correctAnswer)) {
      return false;
    }
    
    return true;
  }

  Map<String, dynamic> _sanitizeQuestionData(Map<String, dynamic> rawData) {
    return {
      'id': rawData['id']?.toString() ?? '',
      'question_text': rawData['question_text']?.toString()?.trim() ?? 'Soalan tidak tersedia',
      'option_a': rawData['option_a']?.toString()?.trim() ?? '',
      'option_b': rawData['option_b']?.toString()?.trim() ?? '',
      'option_c': rawData['option_c']?.toString()?.trim() ?? '',
      'option_d': rawData['option_d']?.toString()?.trim() ?? '',
      'correct_answer': rawData['correct_answer']?.toString()?.toLowerCase() ?? 'a',
      'explanation': rawData['explanation']?.toString()?.trim() ?? 'Tiada nota dari guru',
      'created_at': rawData['created_at'] ?? DateTime.now().toIso8601String(),
    };
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  // ✅ FIXED: Method untuk kembali ke StudentDashboard (halaman utama)
  void _goBackToDashboard() {
    print('🏠 Kembali ke StudentDashboard...');
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDashboard(),
      ),
      (route) => false,
    );
  }

  void _goBackToMcqPage() {
    print('🚀 Kembali ke halaman latihan...');
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => StudentExercisePage(initialTabIndex: 1),
      ),
      (route) => false,
    );
  }

  // ✅ FIXED: Popup menu untuk pilihan kembali
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
            
            // Pilihan 1: Kembali ke StudentDashboard (Halaman Utama)
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
            
            // Pilihan 2: Kembali ke Halaman Latihan (dalam module)
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
            
            // Pilihan 3: Kembali ke Dashboard StudentExercisePage
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
      print('📥 Memuat soalan untuk Set MCQ: ${widget.mcqSet['id']}');
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // ✅ DATA VALIDATION: Validate MCQ set ID
      final setId = widget.mcqSet['id']?.toString();
      if (setId == null || setId.isEmpty) {
        throw Exception('ID set ujian tidak sah');
      }

      final timeoutDuration = Duration(seconds: 30);
      
      // Updated to include explanation field with timeout
      final response = await _supabase
          .from('mcq_question')
          .select('*')
          .eq('mcq_set_id', setId)
          .order('created_at', ascending: true)
          .timeout(timeoutDuration, onTimeout: () {
            throw TimeoutException('Permintaan soalan memakan masa terlalu lama.');
          });

      if (response == null) {
        throw Exception('Tiada data soalan diterima');
      }

      // ✅ DATA VALIDATION: Process and validate questions
      List<Map<String, dynamic>> validQuestions = [];
      List<String> invalidQuestionIds = [];
      
      for (var item in response) {
        try {
          final sanitizedData = _sanitizeQuestionData(item);
          if (_validateQuestionData(sanitizedData)) {
            validQuestions.add(sanitizedData);
          } else {
            invalidQuestionIds.add(item['id']?.toString() ?? 'unknown');
          }
        } catch (e) {
          print('⚠️ Error processing question: $e');
          invalidQuestionIds.add(item['id']?.toString() ?? 'unknown');
        }
      }

      print('✅ Soalan dimuat: ${validQuestions.length} (${invalidQuestionIds.length} invalid)');
      
      if (validQuestions.isEmpty) {
        throw Exception('Tiada soalan sah dalam set ini');
      }

      if (invalidQuestionIds.isNotEmpty) {
        print('⚠️ Invalid question IDs: $invalidQuestionIds');
      }

      Map<int, String> loadedAnswers = {};
      if (widget.previousAttempt != null) {
        print('🔄 Memuat percubaan sebelumnya');
        final answers = widget.previousAttempt!['answers'] ?? {};
        
        for (int i = 0; i < validQuestions.length; i++) {
          final questionId = validQuestions[i]['id'].toString();
          if (answers.containsKey(questionId)) {
            final answer = answers[questionId]?.toString()?.toLowerCase();
            if (answer != null && ['a', 'b', 'c', 'd'].contains(answer)) {
              loadedAnswers[i] = answer;
            }
          }
        }
        print('📝 Jawapan sebelumnya dimuat: ${loadedAnswers.length} soalan');
      }
      
      setState(() {
        _questions = validQuestions;
        _selectedAnswers = loadedAnswers;
        _isLoading = false;
      });
    } on TimeoutException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
      _showErrorSnackbar(e.message);
    } catch (e) {
      print('❌ Ralat memuat soalan: $e');
      setState(() {
        _errorMessage = 'Gagal memuat soalan: ${e.toString()}';
        _isLoading = false;
      });
      _showErrorSnackbar('Gagal memuat soalan: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: StudentColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _selectAnswer(String answer) {
    // ✅ DATA VALIDATION: Validate answer input
    if (!['a', 'b', 'c', 'd'].contains(answer.toLowerCase())) {
      _showErrorSnackbar('Jawapan tidak sah');
      return;
    }

    print('🎯 Dipilih Soalan${_currentIndex + 1}: $answer');
    setState(() {
      _selectedAnswers[_currentIndex] = answer.toLowerCase();
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        print('➡️ Beralih ke Soalan${_currentIndex + 1}');
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        print('⬅️ Beralih ke Soalan${_currentIndex + 1}');
      });
    }
  }

  Future<void> _submitTest() async {
    try {
      // ✅ DATA VALIDATION: Validate all answers before submission
      if (_questions.isEmpty) {
        throw Exception('Tiada soalan untuk diserahkan');
      }

      List<int> unansweredQuestions = [];
      for (int i = 0; i < _questions.length; i++) {
        final answer = _selectedAnswers[i];
        if (answer == null || answer.isEmpty || !['a', 'b', 'c', 'd'].contains(answer)) {
          unansweredQuestions.add(i + 1);
        }
      }

      if (unansweredQuestions.isNotEmpty) {
        String message = unansweredQuestions.length == 1
            ? 'Sila jawab soalan ${unansweredQuestions[0]}'
            : 'Sila jawab semua soalan: ${unansweredQuestions.join(", ")}';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      print('🚀 Menyerahkan sebagai pelajar tetamu...');
      
      String guestStudentId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      String guestName = 'Pelajar';
      
      print('👤 ID Tetamu: $guestStudentId');
      
      int correctAnswers = 0;
      Map<String, dynamic> answers = {};
      
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final selected = _selectedAnswers[i] ?? '';
        final correct = question['correct_answer']?.toString().toLowerCase() ?? 'a';
        
        // Validate both selected and correct answers
        if (!['a', 'b', 'c', 'd'].contains(selected)) {
          print('⚠️ Invalid selected answer for question $i: $selected');
          continue;
        }
        
        if (!['a', 'b', 'c', 'd'].contains(correct)) {
          print('⚠️ Invalid correct answer for question $i: $correct');
          continue;
        }
        
        answers[question['id'].toString()] = selected;
        
        if (selected == correct) {
          correctAnswers++;
        }
      }

      // ✅ DATA VALIDATION: Validate score calculation
      if (_questions.isEmpty) {
        throw Exception('Tiada soalan untuk dikira markah');
      }

      final totalQuestions = _questions.length;
      final percentage = totalQuestions > 0 
          ? (correctAnswers / totalQuestions * 100) 
          : 0;
      
      // Validate score range
      if (correctAnswers < 0 || correctAnswers > totalQuestions) {
        print('⚠️ Invalid score calculation: $correctAnswers/$totalQuestions');
        correctAnswers = correctAnswers.clamp(0, totalQuestions);
      }
      
      print('🎯 MARKAH: $correctAnswers/$totalQuestions (${percentage.toStringAsFixed(1)}%)');
      
      final now = DateTime.now().toIso8601String();
      final attemptData = {
        'student_id': guestStudentId,
        'mcq_set_id': widget.mcqSet['id'],
        'score': correctAnswers,
        'answers': answers,
        'total_questions': totalQuestions,
        'correct_answers': correctAnswers,
        'is_completed': true,
        'completed_at': now,
        'started_at': now,
        'submitted_at': now,
        'student_name': guestName,
      };
      
      print('💾 Menyimpan dengan ID tetamu...');
      
      try {
        await _supabase
            .from('student_mcq_attempts')
            .insert(attemptData);
        print('✅ Disimpan ke pangkalan data sebagai tetamu');
      } catch (dbError) {
        print('⚠️ Simpanan pangkalan data gagal (tetapi teruskan): $dbError');
        // Continue to show results even if database save fails
      }
      
      setState(() {
        _showResults = true;
        _result = {
          'score': correctAnswers,
          'total': totalQuestions,
          'percentage': percentage,
          'answers': answers,
        };
      });
      
      print('🎊 Keputusan ditunjukkan!');
      _showSuccessSnackbar('Ujian berjaya diserahkan!');
      
    } catch (e) {
      print('💥 Ralat dalam penyerahan: $e');
      _showErrorSnackbar('Ralat ketika menyerahkan: $e');
      
      setState(() {
        _showResults = true;
        _result = {
          'score': 0,
          'total': _questions.length,
          'percentage': 0,
          'answers': {},
        };
      });
    }
  }

  Widget _buildQuestionCard() {
    if (_questions.isEmpty) return SizedBox();
    
    final question = _questions[_currentIndex];
    final selectedAnswer = _selectedAnswers[_currentIndex] ?? '';
    
    // ✅ DATA VALIDATION: Safe extraction of question text
    final questionText = question['question_text'] ?? '[Tiada teks soalan]';

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
          final optionText = question['option_$option']?.toString()?.trim() ?? '[Tiada pilihan]';
          final isSelected = selectedAnswer == option;
          
          // Skip empty options
          if (optionText == '[Tiada pilihan]' || optionText.isEmpty) {
            return SizedBox();
          }
          
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
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {
                _showResults = false;
                _currentIndex = 0;
              }),
              child: Text('Kembali ke Ujian'),
            ),
          ],
        ),
      );
    }
    
    final percentage = _result!['percentage'] is double ? _result!['percentage'] : 0.0;
    final score = _result!['score'] is int ? _result!['score'] : int.tryParse(_result!['score'].toString()) ?? 0;
    final total = _result!['total'] is int ? _result!['total'] : int.tryParse(_result!['total'].toString()) ?? 0;
    
    // Validate results
    final safePercentage = percentage.isNaN || percentage.isInfinite ? 0.0 : percentage;
    final safeScore = score.clamp(0, total);
    final safeTotal = total < 0 ? 0 : total;

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
                            '${safePercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$safeScore/$safeTotal betul',
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
                        _buildResultRow('Ujian:', widget.mcqSet['title']?.toString() ?? 'Untitled'),
                        Divider(),
                        _buildResultRow('Markah Anda:', '$safeScore daripada $safeTotal'),
                        Divider(),
                        _buildResultRow('Peratusan:', '${safePercentage.toStringAsFixed(1)}%'),
                        Divider(),
                        _buildResultRow(
                          'Status:',
                          safePercentage >= 80
                              ? 'Cemerlang!'
                              : safePercentage >= 60
                                  ? 'Baik!'
                                  : safePercentage >= 40
                                      ? 'Memuaskan'
                                      : 'Perlu usaha lagi',
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
                      
                      // Button untuk pilihan kembali (gunakan popup menu)
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
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
                      ),
                      SizedBox(height: 12),
                      
                      // Button untuk ulang ujian
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            print('🔄 Butang Ulang Ujian ditekan');
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Ralat tidak diketahui',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadQuestions,
            style: ElevatedButton.styleFrom(
              backgroundColor: StudentColors.primaryGreen,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Cuba Semula'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.mcqSet['title']?.toString() ?? 'Ujian'),
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
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.mcqSet['title']?.toString() ?? 'Ujian'),
          backgroundColor: StudentColors.topBar,
          foregroundColor: StudentColors.textDark,
        ),
        body: _buildErrorState(),
      );
    }

    if (_showResults) {
      return _buildResults();
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.mcqSet['title']?.toString() ?? 'Ujian'),
          backgroundColor: StudentColors.topBar,
          foregroundColor: StudentColors.textDark,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Tiada soalan dalam ujian ini'),
              SizedBox(height: 8),
              Text('Sila hubungi guru anda'),
              SizedBox(height: 24),
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
        title: Text(widget.mcqSet['title']?.toString() ?? 'Ujian'),
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
                final currentAnswered = _selectedAnswers.containsKey(_currentIndex) && 
                                      _selectedAnswers[_currentIndex] != null && 
                                      _selectedAnswers[_currentIndex]!.isNotEmpty;
                
                if (!currentAnswered) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sila pilih jawapan untuk soalan ini'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                
                if (_currentIndex == _questions.length - 1) {
                  bool allAnswered = true;
                  List<int> unanswered = [];
                  
                  for (int i = 0; i < _questions.length; i++) {
                    if (!_selectedAnswers.containsKey(i) || 
                        _selectedAnswers[i] == null || 
                        _selectedAnswers[i]!.isEmpty) {
                      allAnswered = false;
                      unanswered.add(i + 1);
                    }
                  }
                  
                  if (!allAnswered) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sila jawab semua soalan: ${unanswered.join(", ")}'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: CircularProgressIndicator(color: StudentColors.primaryGreen),
                    ),
                  );
                  
                  try {
                    await _submitTest();
                    Navigator.pop(context);
                  } catch (e) {
                    Navigator.pop(context);
                    _showErrorSnackbar('Ralat: $e');
                  }
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

// =============================================================================
// MCQ REVIEW PAGE FOR VIEWING ANSWERS AND TEACHER NOTES
// =============================================================================

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
  // ✅ DATA VALIDATION: Validators for review page
  bool _validateReviewData() {
    if (widget.questions.isEmpty) {
      return false;
    }
    
    if (widget.mcqSet['id'] == null) {
      return false;
    }
    
    return true;
  }

  String _getSafeText(String? text, {String defaultValue = 'N/A'}) {
    if (text == null || text.trim().isEmpty) {
      return defaultValue;
    }
    return text.trim();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ DATA VALIDATION: Validate data before building UI
    if (!_validateReviewData()) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Ulasan Ujian'),
          backgroundColor: StudentColors.topBar,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Data ulasan tidak sah',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    final score = widget.attempt['score'] is int ? widget.attempt['score'] : 0;
    final total = widget.attempt['total_questions'] is int ? widget.attempt['total_questions'] : widget.questions.length;
    final safeTotal = total < 0 ? 0 : total;
    final safeScore = score.clamp(0, safeTotal);
    final percentage = safeTotal > 0 ? (safeScore / safeTotal * 100) : 0;

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
                  _getSafeText(widget.mcqSet['title']?.toString(), defaultValue: 'Ujian'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: StudentColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('$safeScore/$safeTotal', 'Jawapan Betul'),
                    _buildStatCard('${percentage.toStringAsFixed(1)}%', 'Peratusan'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.questions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Tiada soalan untuk diulas'),
                      ],
                    ),
                  )
                : ListView.builder(
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
                // Button untuk kembali ke StudentDashboard
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentDashboard(),
                      ),
                      (route) => false,
                    );
                  },
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
                // Button untuk kembali ke halaman latihan
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
    if (index < 0 || index >= widget.questions.length) {
      return SizedBox();
    }
    
    final question = widget.questions[index];
    final questionNumber = index + 1;
    final selectedAnswer = widget.selectedAnswers[index]?.toString().toLowerCase() ?? '';
    final correctAnswer = question['correct_answer']?.toString().toLowerCase() ?? 'a';
    final explanation = question['explanation']?.toString() ?? 'Tiada nota dari guru';
    final isCorrect = selectedAnswer == correctAnswer;

    // Validate answers
    final safeSelectedAnswer = ['a', 'b', 'c', 'd'].contains(selectedAnswer) ? selectedAnswer : '';
    final safeCorrectAnswer = ['a', 'b', 'c', 'd'].contains(correctAnswer) ? correctAnswer : 'a';

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
                ),
              ],
            ),
          ),
          
          // Question Text
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              _getSafeText(question['question_text']?.toString(), defaultValue: '[Tiada teks soalan]'),
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
                  safeSelectedAnswer.isNotEmpty ? safeSelectedAnswer : '-',
                  _getOptionText(question, safeSelectedAnswer),
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
                  safeCorrectAnswer,
                  _getOptionText(question, safeCorrectAnswer),
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
                  _getSafeText(explanation, defaultValue: 'Tiada nota dari guru'),
                  style: TextStyle(
                    color: StudentColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ));
  }

  String _getOptionText(Map<String, dynamic> question, String option) {
    if (option.isEmpty || option == '-') return 'Tiada jawapan';
    
    final optionText = question['option_${option.toLowerCase()}']?.toString();
    return _getSafeText(optionText, defaultValue: 'Tiada pilihan');
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
          if (option.isNotEmpty && option != '-')
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
          SizedBox(width: option.isNotEmpty && option != '-' ? 12 : 0),
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