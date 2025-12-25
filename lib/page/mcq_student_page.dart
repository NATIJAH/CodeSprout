import 'package:flutter/material.dart';
import '../service/supabase_service.dart';
import '../theme/color.dart';
import 'student.dart';

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
    ).then((_) => _loadData()); // Segar semula apabila kembali
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
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
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
        backgroundColor: AppColor.topBar,
        foregroundColor: AppColor.textDark,
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

  // ✅ FUNCTION UNTUK KEMBALI KE HALAMAN LATIHAN
  void _goBackToMcqPage() {
    print('🚀 Kembali ke halaman utama...');
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => StudentPage(initialTabIndex: 1),
      ),
      (route) => false,
    );
  }

  Future<void> _loadQuestions() async {
    try {
      print('📥 Memuat soalan untuk Set MCQ: ${widget.mcqSet['id']}');
      
      final response = await SupabaseService.client
          .from('mcq_question')
          .select('*')
          .eq('mcq_set_id', widget.mcqSet['id'])
          .order('created_at', ascending: true);

      print('✅ Soalan dimuat: ${response.length}');
      
      setState(() {
        _questions = List<Map<String, dynamic>>.from(response);
        
        // Muat jawapan sebelumnya jika mengambil semula
        if (widget.previousAttempt != null) {
          print('🔄 Memuat percubaan sebelumnya');
          final answers = widget.previousAttempt!['answers'] ?? {};
          for (int i = 0; i < _questions.length; i++) {
            final questionId = _questions[i]['id'].toString();
            if (answers.containsKey(questionId)) {
              _selectedAnswers[i] = answers[questionId];
            }
          }
          print('📝 Jawapan sebelumnya dimuat: $_selectedAnswers');
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Ralat memuat soalan: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ralat memuat soalan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectAnswer(String answer) {
    print('🎯 Dipilih Soalan${_currentIndex + 1}: $answer');
    setState(() {
      _selectedAnswers[_currentIndex] = answer;
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
      print('🚀 Menyerahkan sebagai pelajar tetamu...');
      
      // Hasilkan ID pelajar tetamu
      String guestStudentId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      String guestName = 'Pelajar';
      
      print('👤 ID Tetamu: $guestStudentId');
      
      // Kira markah
      int correctAnswers = 0;
      Map<String, dynamic> answers = {};
      
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final selected = _selectedAnswers[i] ?? '';
        final correct = question['correct_answer'];
        
        answers[question['id'].toString()] = selected;
        
        if (selected == correct) {
          correctAnswers++;
        }
      }

      double percentage = _questions.length > 0 
          ? (correctAnswers / _questions.length * 100) 
          : 0;
      
      print('🎯 MARKAH: $correctAnswers/${_questions.length} (${percentage.toStringAsFixed(1)}%)');
      
      // Simpan ke pangkalan data dengan ID tetamu
      final now = DateTime.now().toIso8601String();
      final attemptData = {
        'student_id': guestStudentId,  // ID TETAMU
        'mcq_set_id': widget.mcqSet['id'],
        'score': correctAnswers,
        'answers': answers,
        'total_questions': _questions.length,
        'correct_answers': correctAnswers,
        'is_completed': true,
        'completed_at': now,
        'started_at': now,
        'submitted_at': now,
        'student_name': guestName,  // NAMA TETAMU
      };
      
      print('💾 Menyimpan dengan ID tetamu...');
      
      try {
        // Cuba simpan ke pangkalan data
        await SupabaseService.client
            .from('student_mcq_attempts')
            .insert(attemptData);
        print('✅ Disimpan ke pangkalan data sebagai tetamu');
      } catch (dbError) {
        print('⚠️ Simpanan pangkalan data gagal (tetapi teruskan): $dbError');
        // Teruskan untuk menunjukkan keputusan walaupun simpan gagal
      }
      
      // Tunjukkan keputusan
      setState(() {
        _showResults = true;
        _result = {
          'score': correctAnswers,
          'total': _questions.length,
          'percentage': percentage,
        };
      });
      
      print('🎊 Keputusan ditunjukkan!');
      
    } catch (e) {
      print('💥 Ralat dalam penyerahan: $e');
      
      // Masih tunjukkan keputusan walaupun berlaku ralat
      setState(() {
        _showResults = true;
        _result = {
          'score': 0,
          'total': _questions.length,
          'percentage': 0,
        };
      });
    }
  }

  Widget _buildQuestionCard() {
    if (_questions.isEmpty) return SizedBox();
    
    final question = _questions[_currentIndex];
    final selectedAnswer = _selectedAnswers[_currentIndex] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombor soalan
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
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColor.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${((_currentIndex + 1) / _questions.length * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColor.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Teks soalan
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

        // Pilihan
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
          
          return GestureDetector(
            onTap: () => _selectAnswer(option),
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColor.primaryGreen.withOpacity(0.1)
                    : AppColor.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColor.primaryGreen
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? AppColor.primaryGreen
                      : Colors.grey[300],
                  radius: 16,
                  child: Text(
                    option.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColor.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(optionText),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: AppColor.success)
                    : null,
              ),
            ),
          );
        }).toList(),
      ],
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
        backgroundColor: AppColor.topBar,
        foregroundColor: AppColor.textDark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _goBackToMcqPage,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Score Circle
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
                          colors: [AppColor.success, Color(0xFF9BC588)],
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

                // Results Details
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
                        _buildResultRow(
                          'Status:',
                          percentage >= 80
                              ? 'Cemerlang!'
                              : percentage >= 60
                                  ? 'Baik!'
                                  : percentage >= 40
                                      ? 'Memuaskan'
                                      : 'Perlu usaha lagi',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // ✅ BUTANG UTAMA
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // BUTANG 1: KEMBALI KE HALAMAN LATIHAN
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _goBackToMcqPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.success,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'KEMBALI KE HALAMAN LATIHAN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // BUTANG 2: ULANG UJIAN
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
                              side: BorderSide(color: AppColor.success, width: 2),
                            ),
                          ),
                          child: Text(
                            'ULANG UJIAN INI',
                            style: TextStyle(
                              color: AppColor.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),

                      // BUTANG 3: KE DASHBOARD
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentPage(),
                            ),
                            (route) => false,
                          );
                        },
                        child: Text(
                          '',
                          style: TextStyle(
                            color: AppColor.textLight,
                            fontSize: 14,
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
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    print('=== PEMBINAAN LATIHAN MCQ ===');
    print('Pemuatan: $_isLoading');
    print('Tunjukkan Keputusan: $_showResults');
    print('Soalan: ${_questions.length}');
    print('Indeks Semasa: $_currentIndex');
    print('Jawapan Terpilih: $_selectedAnswers');
    print('=======================');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.mcqSet['title']),
          backgroundColor: AppColor.topBar,
          foregroundColor: AppColor.textDark,
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
          backgroundColor: AppColor.topBar,
          foregroundColor: AppColor.textDark,
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
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(widget.mcqSet['title']),
        backgroundColor: AppColor.topBar,
        foregroundColor: AppColor.textDark,
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
            // BUTANG SEBELUM
            ElevatedButton(
              onPressed: _previousQuestion,
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
            
            // BUTANG SETERUSNYA/HANTAR
            ElevatedButton(
              onPressed: () async {
                print('🎯 Butang bawah ditekan');
                print('📊 Indeks semasa: $_currentIndex, Jumlah: ${_questions.length}');
                
                // Semak jika soalan semasa dijawab
                final currentAnswered = _selectedAnswers.containsKey(_currentIndex) && 
                                      _selectedAnswers[_currentIndex] != null && 
                                      _selectedAnswers[_currentIndex]!.isNotEmpty;
                
                if (!currentAnswered) {
                  print('⚠️ Soalan semasa belum dijawab');
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
                  // SOALAN TERAKHIR - HANTAR
                  print('📝 Soalan terakhir dicapai, menyemak semua jawapan...');
                  
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
                    print('⚠️ Tidak semua soalan dijawab: $unanswered');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sila jawab semua soalan: ${unanswered.join(", ")}'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                  
                  print('✅ Semua soalan dijawab. Menghantar...');
                  
                  // Tunjukkan pemuatan
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: CircularProgressIndicator(color: AppColor.primaryGreen),
                    ),
                  );
                  
                  try {
                    await _submitTest();
                    Navigator.pop(context); // Tutup pemuatan
                    print('🎉 Penyerahan selesai!');
                  } catch (e) {
                    Navigator.pop(context); // Tutup pemuatan
                    print('❌ Penyerahan gagal: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ralat: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  // BUKAN SOALAN TERAKHIR - PERGI KE SETERUSNYA
                  print('➡️ Pergi ke soalan seterusnya');
                  _nextQuestion();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentIndex == _questions.length - 1
                    ? AppColor.success
                    : AppColor.primaryGreen,
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