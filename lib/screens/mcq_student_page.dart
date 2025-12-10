import 'package:flutter/material.dart';
import '../service/supabase_service.dart';
import '../theme/color.dart';

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
      // Load MCQ sets
      final response = await SupabaseService.client
          .from('mcq_set')
          .select('*, mcq_question(count)')
          .order('created_at', ascending: false);

      // Load student attempts
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final attemptsResponse = await SupabaseService.client
            .from('student_mcq_attempts')
            .select('*')
            .eq('student_id', user.id);

        // Convert to map for easy lookup
        for (var attempt in attemptsResponse) {
          _attemptsMap[attempt['mcq_set_id']] = attempt;
        }
      }

      setState(() {
        _mcqSetList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading MCQ sets: $e');
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
    ).then((_) => _loadData()); // Refresh when returning
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
                      ? StudentColors.success.withOpacity(0.1)
                      : StudentColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasAttempt ? Icons.assignment_turned_in : Icons.quiz,
                  color: hasAttempt ? StudentColors.success : StudentColors.primaryBlue,
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
                              color: StudentColors.textDark,
                            ),
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
                    if (mcqSet['description'] != null) ...[
                      SizedBox(height: 4),
                      Text(
                        mcqSet['description'],
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
                                '$questionCount questions',
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
                            color: StudentColors.primaryBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            hasAttempt ? 'Retake' : 'Start',
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
    if (percentage >= 60) return StudentColors.warning;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: AppBar(
        title: Text('Practice Tests'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _mcqSetList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No practice tests yet',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your teacher will add practice tests here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
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
  List<Map<String, dynamic>> _questions = [];
  Map<int, String> _selectedAnswers = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showResults = false;
  Map<String, dynamic>? _result;

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
        
        // Load previous answers if retaking
        if (widget.previousAttempt != null) {
          final answers = widget.previousAttempt!['answers'] ?? {};
          for (int i = 0; i < _questions.length; i++) {
            final questionId = _questions[i]['id'];
            if (answers.containsKey(questionId)) {
              _selectedAnswers[i] = answers[questionId];
            }
          }
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading questions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _selectAnswer(String answer) {
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

  Future<void> _submitTest() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      // Calculate score
      int correctAnswers = 0;
      Map<String, dynamic> answers = {};
      
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final selected = _selectedAnswers[i] ?? '';
        answers[question['id']] = selected;
        
        if (selected == question['correct_answer']) {
          correctAnswers++;
        }
      }

      final now = DateTime.now().toIso8601String();
      final attemptData = {
        'student_id': user.id,
        'mcq_set_id': widget.mcqSet['id'],
        'score': correctAnswers,
        'answers': answers,
        'total_questions': _questions.length,
        'correct_answers': correctAnswers,
        'is_completed': true,
        'completed_at': now,
        'started_at': now,
        'submitted_at': now,
        'student_name': user.email?.split('@').first ?? 'Student', // Optional
      };

      print('Submitting attempt: $attemptData');

      if (widget.previousAttempt != null && widget.previousAttempt!['id'] != null) {
        // Update existing attempt
        final response = await SupabaseService.client
            .from('student_mcq_attempts')
            .update(attemptData)
            .eq('id', widget.previousAttempt!['id']);
        
        print('Update response: $response');
      } else {
        // Create new attempt
        final response = await SupabaseService.client
            .from('student_mcq_attempts')
            .insert(attemptData);
        
        print('Insert response: $response');
      }

      setState(() {
        _showResults = true;
        _result = {
          'score': correctAnswers,
          'total': _questions.length,
          'percentage': (correctAnswers / _questions.length * 100),
        };
      });

      print('Test submitted successfully! Score: $correctAnswers/${_questions.length}');
    } catch (e) {
      print('Error submitting test: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildQuestionCard() {
    final question = _questions[_currentIndex];
    final selectedAnswer = _selectedAnswers[_currentIndex] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question number and progress
        Row(
          children: [
            Text(
              'Question ${_currentIndex + 1} of ${_questions.length}',
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
                color: StudentColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${((_currentIndex + 1) / _questions.length * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: StudentColors.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Question text
        Card(
          elevation: 0,
          color: StudentColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              question['question_text'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: StudentColors.textDark,
              ),
            ),
          ),
        ),
        SizedBox(height: 24),

        // Options
        Text(
          'Select your answer:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: StudentColors.textDark,
          ),
        ),
        SizedBox(height: 12),

        ...['a', 'b', 'c', 'd'].map((option) {
          final optionText = question['option_$option'];
          final isSelected = selectedAnswer == option;
          
          return GestureDetector(
            onTap: () => _selectAnswer(option),
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? StudentColors.primaryBlue.withOpacity(0.1)
                    : StudentColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? StudentColors.primaryBlue
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? StudentColors.primaryBlue
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
                title: Text(optionText),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: StudentColors.success)
                    : null,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResults() {
    final percentage = _result!['percentage'];
    final score = _result!['score'];
    final total = _result!['total'];

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: AppBar(
        title: Text('Test Results'),
        backgroundColor: StudentColors.topBar,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score circle
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: StudentColors.primaryBlue.withOpacity(0.2),
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
                        colors: [
                          StudentColors.primaryBlue,
                          StudentColors.secondaryBlue,
                        ],
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
                        '$score/$total correct',
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

            // Results details
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildResultRow('Test:', widget.mcqSet['title']),
                    Divider(),
                    _buildResultRow('Your Score:', '$score out of $total'),
                    Divider(),
                    _buildResultRow('Percentage:', '${percentage.toStringAsFixed(1)}%'),
                    Divider(),
                    _buildResultRow('Status:',
                        percentage >= 80 ? 'Excellent!' : 'Good effort!'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StudentColors.primaryBlue,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Back to Practice',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                if (percentage < 80)
                  ElevatedButton(
                    onPressed: () {
                      // Retake test
                      setState(() {
                        _showResults = false;
                        _selectedAnswers.clear();
                        _currentIndex = 0;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: BorderSide(color: StudentColors.primaryBlue),
                      ),
                    ),
                    child: Text(
                      'Retake Test',
                      style: TextStyle(color: StudentColors.primaryBlue),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ));
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.mcqSet['title'])),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showResults) {
      return _buildResults();
    }

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: AppBar(
        title: Text(widget.mcqSet['title']),
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
                    ? StudentColors.primaryBlue
                    : Colors.grey[300],
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Previous',
                style: TextStyle(
                  color: _currentIndex > 0 ? Colors.white : Colors.grey,
                ),
              ),
            ),
            
            ElevatedButton(
              onPressed: () {
                // Check if all questions are answered
                bool allAnswered = true;
                for (int i = 0; i < _questions.length; i++) {
                  if (_selectedAnswers[i] == null || _selectedAnswers[i]!.isEmpty) {
                    allAnswered = false;
                    break;
                  }
                }
                
                if (!allAnswered) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please answer all questions before submitting'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                if (_currentIndex == _questions.length - 1) {
                  _submitTest();
                } else {
                  _nextQuestion();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentIndex == _questions.length - 1
                    ? StudentColors.success
                    : StudentColors.primaryBlue,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                _currentIndex == _questions.length - 1
                    ? 'Submit Test'
                    : 'Next',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}