// student/lib/page/mcq_student_page.dart - COMPLETE FILE
import 'package:flutter/material.dart';
import '../service/supabase_service.dart';
import '../theme/color.dart';
import 'student.dart';

// ✅ MAIN MCQ LIST PAGE (THIS IS WHAT student.dart NEEDS)
class McqStudentPage extends StatefulWidget {
  @override
  _McqStudentPageState createState() => _McqStudentPageState();
}

class _McqStudentPageState extends State<McqStudentPage> {
  List<Map<String, dynamic>> _mcqSetList = [];
  Map<String, dynamic> _attemptsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Muat set MCQ
      final response = await SupabaseService.client
          .from('mcq_set')
          .select('*, mcq_question(count)')
          .order('created_at', ascending: false);

      // Muat percubaan pelajar
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final attemptsResponse = await SupabaseService.client
            .from('student_mcq_attempts')
            .select('*')
            .eq('student_id', user.id);

        // Tukar ke peta untuk carian mudah
        for (var attempt in attemptsResponse) {
          _attemptsMap[attempt['mcq_set_id']] = attempt;
        }
      }

      setState(() {
        _mcqSetList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Ralat memuat set MCQ: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startPractice(Map<String, dynamic> mcqSet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => McqPracticePage(
          mcqSet: mcqSet,
          previousAttempt: _attemptsMap[mcqSet['id']],
        ),
      ),
    ).then((_) => _loadData());
  }

  Widget _buildSetCard(Map<String, dynamic> mcqSet) {
    final questionCount = mcqSet['mcq_question'][0]['count'] ?? 0;
    final previousAttempt = _attemptsMap[mcqSet['id']];
    final hasAttempt = previousAttempt != null;
    final score = hasAttempt ? (previousAttempt['score'] ?? 0) : 0;
    final total = hasAttempt ? (previousAttempt['total_questions'] ?? questionCount) : questionCount;
    final percentage = total > 0 ? (score / total * 100) : 0;

    return Card(
      elevation: 2,
      color: AppColor.card,
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
                      ? AppColor.success.withOpacity(0.1)
                      : AppColor.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasAttempt ? Icons.assignment_turned_in : Icons.quiz,
                  color: hasAttempt ? AppColor.success : AppColor.primaryGreen,
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
                            mcqSet['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColor.textDark,
                            ),
                          ),
                        ),
                        if (hasAttempt)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColor.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$score/$total',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColor.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (mcqSet['description'] != null) ...[
                      SizedBox(height: 4),
                      Text(
                        mcqSet['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColor.textLight,
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
                                  color: AppColor.textLight,
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
                                    color: AppColor.textLight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColor.primaryGreen,
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
    if (percentage >= 80) return AppColor.success;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text('Ujian Latihan'),
        backgroundColor: AppColor.success,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColor.primaryGreen))
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
                  color: AppColor.primaryGreen,
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

// ✅ PRACTICE PAGE (INDIVIDUAL TEST) - KEEP THE EXISTING CODE
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
  List<Map<String, dynamic>> _questions = [];
  Map<int, String> _selectedAnswers = {};
  Map<int, bool> _answerStatus = {};
  Map<int, bool> _answered = {};
  Map<int, bool> _showExplanation = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showResults = false;
  Map<String, dynamic>? _result;
  int _score = 0;
  int _totalQuestions = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final response = await SupabaseService.client
          .from('mcq_question')
          .select('*')
          .eq('mcq_set_id', widget.mcqSet['id'])
          .order('created_at', ascending: true);

      setState(() {
        _questions = List<Map<String, dynamic>>.from(response);
        _totalQuestions = _questions.length;
        _selectedAnswers = {};
        _answerStatus = {};
        _answered = {};
        _showExplanation = {};
        
        if (widget.previousAttempt != null) {
          final answers = widget.previousAttempt!['answers'] ?? {};
          for (int i = 0; i < _questions.length; i++) {
            final questionId = _questions[i]['id'].toString();
            if (answers.containsKey(questionId)) {
              _selectedAnswers[i] = answers[questionId];
              _checkAnswer(i, answers[questionId]);
            }
          }
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('Ralat memuat soalan: $e');
      setState(() => _isLoading = false);
    }
  }

  void _checkAnswer(int questionIndex, String selectedAnswer) {
    if (_answered[questionIndex] == true) return;
    
    final question = _questions[questionIndex];
    final correctAnswer = question['correct_answer'];
    final isCorrect = selectedAnswer == correctAnswer;
    
    setState(() {
      _selectedAnswers[questionIndex] = selectedAnswer;
      _answerStatus[questionIndex] = isCorrect;
      _answered[questionIndex] = true;
      _showExplanation[questionIndex] = false;
      
      if (isCorrect) {
        _score++;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect ? '✅ Jawapan betul!' : '❌ Jawapan salah',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isCorrect ? AppColor.success : Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleExplanation(int questionIndex) {
    setState(() {
      _showExplanation[questionIndex] = !(_showExplanation[questionIndex] ?? false);
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

  void _goToQuestion(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _submitTest() async {
    try {
      String guestStudentId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      String guestName = 'Pelajar';
      
      Map<String, dynamic> answers = {};
      
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final selected = _selectedAnswers[i] ?? '';
        answers[question['id'].toString()] = selected;
      }

      double percentage = _totalQuestions > 0 
          ? (_score / _totalQuestions * 100) 
          : 0;
      
      final now = DateTime.now().toIso8601String();
      final attemptData = {
        'student_id': guestStudentId,
        'mcq_set_id': widget.mcqSet['id'],
        'score': _score,
        'answers': answers,
        'total_questions': _totalQuestions,
        'correct_answers': _score,
        'is_completed': true,
        'completed_at': now,
        'started_at': now,
        'submitted_at': now,
        'student_name': guestName,
      };
      
      try {
        await SupabaseService.client
            .from('student_mcq_attempts')
            .insert(attemptData);
      } catch (dbError) {
        print('Simpanan pangkalan data gagal: $dbError');
      }
      
      setState(() {
        _showResults = true;
        _result = {
          'score': _score,
          'total': _totalQuestions,
          'percentage': percentage,
        };
      });
      
    } catch (e) {
      print('Ralat dalam penyerahan: $e');
      setState(() {
        _showResults = true;
        _result = {
          'score': 0,
          'total': _totalQuestions,
          'percentage': 0,
        };
      });
    }
  }

  void _restartTest() {
    setState(() {
      _showResults = false;
      _selectedAnswers = {};
      _answerStatus = {};
      _answered = {};
      _showExplanation = {};
      _currentIndex = 0;
      _score = 0;
    });
  }

  Widget _buildQuestionCard() {
    if (_questions.isEmpty) return SizedBox();
    
    final question = _questions[_currentIndex];
    final selectedAnswer = _selectedAnswers[_currentIndex] ?? '';
    final isAnswered = _answered[_currentIndex] ?? false;
    final isCorrect = _answerStatus[_currentIndex] ?? false;
    final correctAnswer = question['correct_answer'];
    final explanation = question['explanation'];
    final showExplanation = _showExplanation[_currentIndex] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Soalan ${_currentIndex + 1} daripada ${_questions.length}',
              style: TextStyle(
                fontSize: 14,
                color: AppColor.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Text(
              'Markah: $_score/$_totalQuestions',
              style: TextStyle(
                fontSize: 14,
                color: AppColor.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _questions.length,
          backgroundColor: Colors.grey[200],
          color: AppColor.primaryGreen,
          minHeight: 6,
        ),
        SizedBox(height: 16),

        Card(
          elevation: 0,
          color: AppColor.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              question['question_text'] ?? '[Tiada teks soalan]',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColor.textDark,
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
            color: AppColor.textDark,
          ),
        ),
        SizedBox(height: 12),

        ...['a', 'b', 'c', 'd'].map((option) {
          final optionText = question['option_$option'] ?? '[Tiada pilihan]';
          final isSelected = selectedAnswer == option;
          final isCorrectOption = correctAnswer == option;
          
          Color backgroundColor = AppColor.card;
          Color borderColor = Colors.grey[300]!;
          Color textColor = AppColor.textDark;
          IconData? trailingIcon;
          Color? iconColor;

          if (isAnswered) {
            if (isCorrectOption) {
              backgroundColor = AppColor.success.withOpacity(0.1);
              borderColor = AppColor.success;
              textColor = AppColor.success;
              trailingIcon = Icons.check_circle;
              iconColor = AppColor.success;
            } else if (isSelected && !isCorrectOption) {
              backgroundColor = Colors.red.withOpacity(0.1);
              borderColor = Colors.red;
              textColor = Colors.red;
              trailingIcon = Icons.cancel;
              iconColor = Colors.red;
            }
          } else if (isSelected) {
            backgroundColor = AppColor.primaryGreen.withOpacity(0.1);
            borderColor = AppColor.primaryGreen;
          }

          return GestureDetector(
            onTap: () {
              if (!isAnswered) {
                _checkAnswer(_currentIndex, option);
              }
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: isSelected || isCorrectOption ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCorrectOption && isAnswered
                      ? AppColor.success
                      : isSelected && !isCorrectOption && isAnswered
                        ? Colors.red
                        : isSelected
                          ? AppColor.primaryGreen
                          : Colors.grey[300],
                  radius: 16,
                  child: Text(
                    option.toUpperCase(),
                    style: TextStyle(
                      color: (isCorrectOption && isAnswered) || 
                            (isSelected && !isCorrectOption && isAnswered)
                        ? Colors.white
                        : isSelected
                          ? Colors.white
                          : AppColor.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  optionText,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: trailingIcon != null
                    ? Icon(trailingIcon, color: iconColor)
                    : null,
              ),
            ),
          );
        }).toList(),

        if (isAnswered) ...[
          SizedBox(height: 20),
          Card(
            elevation: 0,
            color: isCorrect 
                ? AppColor.success.withOpacity(0.05)
                : Colors.red.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isCorrect ? AppColor.success : Colors.red,
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? AppColor.success : Colors.red,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isCorrect ? 'Jawapan Betul!' : 'Jawapan Salah',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? AppColor.success : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  
                  Text(
                    'Jawapan yang betul: ${correctAnswer.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textDark,
                    ),
                  ),
                  
                  if (explanation != null && explanation.isNotEmpty) ...[
                    SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _toggleExplanation(_currentIndex),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              showExplanation ? Icons.expand_less : Icons.expand_more,
                              color: AppColor.primaryGreen,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Lihat Catatan Guru',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColor.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    if (showExplanation) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          explanation,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColor.textDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],

        SizedBox(height: 20),
        _buildNavigationButtons(isAnswered: isAnswered),
      ],
    );
  }

  Widget _buildNavigationButtons({required bool isAnswered}) {
    bool isLastQuestion = _currentIndex == _questions.length - 1;
    bool allAnswered = _answered.length == _questions.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _currentIndex > 0 ? _previousQuestion : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _currentIndex > 0
                ? AppColor.primaryGreen
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
          onPressed: () {
            if (!isAnswered) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sila pilih jawapan untuk soalan ini'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            
            if (isLastQuestion) {
              if (allAnswered) {
                _submitTest();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sila jawab semua soalan sebelum hantar'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            } else {
              _nextQuestion();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isLastQuestion && allAnswered
                ? AppColor.success
                : AppColor.primaryGreen,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            isLastQuestion ? 'HANTAR UJIAN' : 'Seterusnya',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.mcqSet['title']),
          backgroundColor: AppColor.success,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColor.primaryGreen),
              SizedBox(height: 16),
              Text('Memuatkan soalan...'),
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
          title: Text(widget.mcqSet['title']),
          backgroundColor: AppColor.success,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Tiada soalan dalam ujian ini'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(widget.mcqSet['title']),
        backgroundColor: AppColor.success,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _restartTest,
            tooltip: 'Mula Semula',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _buildQuestionCard(),
      ),
    );
  }

 Widget _buildResults() {
  if (_result == null) return Center(child: Text('Tiada keputusan'));
  
  final percentage = _result!['percentage'];
  final score = _result!['score'];
  final total = _result!['total'];

  return Scaffold(
    backgroundColor: AppColor.background,
    appBar: AppBar(
      title: Text('Keputusan Ujian'),
      backgroundColor: AppColor.success,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => StudentPage(initialTabIndex: 1),
            ),
            (route) => false,
          );
        },
      ),
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Score Summary
            _buildScoreSummary(percentage, score, total),
            SizedBox(height: 30),

            // User-friendly message based on score
            _buildPerformanceMessage(percentage),
            SizedBox(height: 20),

            // Detailed Results - Show all questions
            _buildDetailedResults(),
            SizedBox(height: 20),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    ),
  );
}

Widget _buildScoreSummary(double percentage, int score, int total) {
  return Column(
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
                color: AppColor.success.withOpacity(0.2),
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
                colors: _getScoreGradient(percentage),
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
      SizedBox(height: 20),
      
      Card(
        elevation: 2,
        color: AppColor.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _buildResultRow('Ujian:', widget.mcqSet['title']),
              Divider(),
              _buildResultRow('Markah Anda:', '$score daripada $total'),
              Divider(),
              _buildResultRow('Peratusan:', '${percentage.toStringAsFixed(1)}%'),
              Divider(),
              _buildResultRow('Status:', _getStatusText(percentage)),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildPerformanceMessage(double percentage) {
  String message = '';
  String emoji = '';
  Color color = AppColor.success;
  
  if (percentage >= 90) {
    message = 'Cemerlang! Anda sangat menguasai topik ini! 🎯';
    emoji = '🏆';
    color = Colors.deepPurple;
  } else if (percentage >= 80) {
    message = 'Sangat baik! Pemahaman anda mantap! 👍';
    emoji = '⭐';
    color = AppColor.success;
  } else if (percentage >= 70) {
    message = 'Baik! Teruskan usaha anda! 💪';
    emoji = '✨';
    color = Colors.blue;
  } else if (percentage >= 60) {
    message = 'Memuaskan! Ada ruang untuk penambahbaikan 📚';
    emoji = '📖';
    color = Colors.orange;
  } else if (percentage >= 50) {
    message = 'Perlu usaha lagi! Jangan putus asa! 🌱';
    emoji = '🌱';
    color = Colors.orange[700]!;
  } else {
    message = 'Jangan patah semangat! Cuba lagi dan pelajari dari kesilapan 💫';
    emoji = '💫';
    color = Colors.red;
  }
  
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3), width: 1),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(emoji, style: TextStyle(fontSize: 24)),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDetailedResults() {
  return Card(
    elevation: 2,
    color: AppColor.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: AppColor.primaryGreen, size: 24),
              SizedBox(width: 8),
              Text(
                'Semakan Jawapan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textDark,
                ),
              ),
              Spacer(),
              Text(
                '${_score}/${_questions.length} betul',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // List all questions with answers
          ..._questions.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> question = entry.value;
            String selectedAnswer = _selectedAnswers[index] ?? '';
            String correctAnswer = question['correct_answer'];
            bool isCorrect = _answerStatus[index] ?? false;
            String? explanation = question['explanation'];
            
            return Column(
              children: [
                if (index > 0) Divider(),
                SizedBox(height: 12),
                _buildQuestionResultItem(
                  index: index,
                  question: question,
                  selectedAnswer: selectedAnswer,
                  correctAnswer: correctAnswer,
                  isCorrect: isCorrect,
                  explanation: explanation,
                ),
              ],
            );
          }).toList(),
        ],
      ),
    ),
  );
}

Widget _buildQuestionResultItem({
  required int index,
  required Map<String, dynamic> question,
  required String selectedAnswer,
  required String correctAnswer,
  required bool isCorrect,
  required String? explanation,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Question number and status
      Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrect 
                  ? AppColor.success.withOpacity(0.1) 
                  : Colors.red.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? AppColor.success : Colors.red,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              question['question_text'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColor.textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? AppColor.success : Colors.red,
            size: 20,
          ),
        ],
      ),
      SizedBox(height: 8),
      
      // Your answer
      Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Jawapan anda: ${selectedAnswer.isNotEmpty ? selectedAnswer.toUpperCase() : 'TIADA'}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
      
      // Correct answer
      Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.success,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Jawapan betul: ${correctAnswer.toUpperCase()}',
              style: TextStyle(
                fontSize: 13,
                color: AppColor.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      
      // Teacher's notes (if available)
      if (explanation != null && explanation.isNotEmpty) ...[
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColor.primaryGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColor.primaryGreen.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColor.primaryGreen,
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan Guru:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primaryGreen,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColor.textDark,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

Widget _buildActionButtons() {
  return Column(
    children: [
      Container(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => StudentPage(initialTabIndex: 1),
              ),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.success,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: 20),
              SizedBox(width: 8),
              Text(
                'KEMBALI KE SENARAI UJIAN',
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
      SizedBox(height: 16),
      
      Container(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _restartTest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColor.success, width: 2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh, color: AppColor.success, size: 20),
              SizedBox(width: 8),
              Text(
                'ULANG UJIAN INI',
                style: TextStyle(
                  color: AppColor.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: 12),
      
      Container(
        width: double.infinity,
        child: TextButton(
          onPressed: () {
            // Share results option
            _shareResults();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share, color: AppColor.textLight, size: 18),
              SizedBox(width: 8),
              Text(
                'KONGSI KEPUTUSAN',
                style: TextStyle(
                  color: AppColor.textLight,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

void _shareResults() {
  final percentage = _result!['percentage'];
  final score = _result!['score'];
  final total = _result!['total'];
  
  String shareMessage = '''
🎯 Keputusan Ujian ${widget.mcqSet['title']}

Markah: $score/$total
Peratusan: ${percentage.toStringAsFixed(1)}%
Status: ${_getStatusText(percentage)}

Bagus! Teruskan usaha! 💪
''';
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Keputusan disediakan untuk dikongsi!'),
      backgroundColor: AppColor.success,
    ),
  );
  
  // In a real app, you would use share_plus package:
  // await Share.share(shareMessage);
}

List<Color> _getScoreGradient(double percentage) {
  if (percentage >= 90) {
    return [Color(0xFF8A2BE2), Color(0xFF9370DB)]; // Purple gradient
  } else if (percentage >= 80) {
    return [AppColor.success, Color(0xFF9BC588)]; // Green gradient
  } else if (percentage >= 60) {
    return [Color(0xFFFFA500), Color(0xFFFFD700)]; // Orange gradient
  } else {
    return [Color(0xFFFF6347), Color(0xFFFFA07A)]; // Red gradient
  }
}

String _getStatusText(double percentage) {
  if (percentage >= 90) return 'Cemerlang! 🏆';
  if (percentage >= 80) return 'Sangat Baik! ⭐';
  if (percentage >= 70) return 'Baik! 👍';
  if (percentage >= 60) return 'Memuaskan 📚';
  if (percentage >= 50) return 'Perlu Usaha Lagi 🌱';
  return 'Perlu Latihan Tambahan 💪';
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
            color: AppColor.textLight,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColor.textDark,
          ),
        ),
      ],
    ),
  );
}}