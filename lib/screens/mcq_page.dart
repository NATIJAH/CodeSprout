// teacher/lib/page/mcq_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/color.dart';

class McqPage extends StatefulWidget {
  @override
  _McqPageState createState() => _McqPageState();
}

class _McqPageState extends State<McqPage> {
  // ✅ FIXED: Changed from 'final' to 'late final'
  late final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _mcqSetList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMcqSets();
  }

  Future<void> _loadMcqSets() async {
    try {
      final response = await _supabase
          .from('mcq_set')
          .select('*, mcq_question(count)')
          .order('created_at', ascending: false);

      // ✅ DATA VALIDATION: Validate response structure
      if (response == null) {
        print('⚠️ Response null dari server');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ DATA VALIDATION: Filter valid MCQ sets
      List<Map<String, dynamic>> validMcqSets = [];
      for (var mcqSet in response) {
        // Validate required fields
        if (mcqSet['id'] == null || mcqSet['title'] == null) {
          print('⚠️ Skip set MCQ tidak valid: ID atau tajuk tiada');
          continue;
        }

        // Validate data types
        if (mcqSet['id'] is! String && mcqSet['id'] is! int) {
          print('⚠️ Skip set MCQ: ID bukan string atau integer');
          continue;
        }

        // Ensure title is not empty after trimming
        if (mcqSet['title'].toString().trim().isEmpty) {
          print('⚠️ Skip set MCQ: Tajuk kosong');
          continue;
        }

        validMcqSets.add(mcqSet);
      }

      setState(() {
        _mcqSetList = validMcqSets;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Ralat memuat set MCQ: $e');
      setState(() => _isLoading = false);
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat set MCQ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createMcqSet() async {
    await showDialog(
      context: context,
      builder: (context) => CreateMcqSetDialog(onSave: _loadMcqSets),
    );
  }

  Future<void> _editMcqSet(Map<String, dynamic> mcqSet) async {
    // ✅ DATA VALIDATION: Validate MCQ set before editing
    if (mcqSet['id'] == null || mcqSet['title'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Set MCQ tidak valid untuk diedit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => CreateMcqSetDialog(mcqSet: mcqSet, onSave: _loadMcqSets),
    );
  }

  Future<void> _deleteMcqSet(String id) async {
    try {
      // ✅ DATA VALIDATION: Validate ID before deletion
      if (id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ID set MCQ tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Padam Set MCQ'),
              content: Text(
                  'Adakah anda pasti mahu memadam set MCQ ini berserta semua soalan di dalamnya?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Padam', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;

      if (confirm) {
        // Delete questions first (foreign key constraint)
        await _supabase
            .from('mcq_question')
            .delete()
            .eq('mcq_set_id', id);

        // Then delete the MCQ set
        await _supabase.from('mcq_set').delete().eq('id', id);

        _loadMcqSets();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Set MCQ berjaya dipadam!')),
        );
      }
    } catch (e) {
      print('❌ Ralat memadam set MCQ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memadam set MCQ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _manageQuestions(Map<String, dynamic> mcqSet) {
    // ✅ DATA VALIDATION: Validate MCQ set before navigation
    if (mcqSet['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Set MCQ tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => McqQuestionsPage(mcqSet: mcqSet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _mcqSetList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Tiada set MCQ dicipta', style: TextStyle(fontSize: 18)),
                      Text('Klik butang + untuk cipta set MCQ pertama',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _mcqSetList.length,
                  itemBuilder: (context, index) {
                    final mcqSet = _mcqSetList[index];
                    
                    // ✅ DATA VALIDATION: Safe access to nested data
                    final questionCount = mcqSet['mcq_question'] != null &&
                            (mcqSet['mcq_question'] as List).isNotEmpty
                        ? (mcqSet['mcq_question'][0] as Map<String, dynamic>)['count'] ?? 0
                        : 0;
                    
                    // ✅ DATA VALIDATION: Safe title display
                    final title = mcqSet['title']?.toString() ?? 'Tiada Tajuk';
                    final description = mcqSet['description']?.toString();
                    
                    return Card(
                      color: TeacherColors.card,
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(Icons.quiz, color: const Color.fromARGB(255, 174, 202, 160), size: 32),
                        title: Text(
                          title,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (description != null &&
                                description.trim().isNotEmpty)
                              Text(description),
                            Text('$questionCount soalan'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: const Color.fromARGB(255, 175, 211, 158)),
                              onPressed: () => _editMcqSet(mcqSet),
                              tooltip: 'Edit Set',
                            ),
                            IconButton(
                              icon: Icon(Icons.list_alt, color: Colors.blue),
                              onPressed: () => _manageQuestions(mcqSet),
                              tooltip: 'Urus Soalan',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: TeacherColors.danger),
                              onPressed: () => _deleteMcqSet(mcqSet['id'].toString()),
                              tooltip: 'Padam Set',
                            ),
                          ],
                        ),
                        onTap: () => _manageQuestions(mcqSet),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createMcqSet,
        child: Icon(Icons.add),
        backgroundColor: const Color.fromARGB(255, 180, 216, 164),
        tooltip: 'Cipta Set MCQ',
      ),
    );
  }
}

// =============================================================================
// CREATE/EDIT MCQ SET DIALOG
// =============================================================================

class CreateMcqSetDialog extends StatefulWidget {
  final Map<String, dynamic>? mcqSet;
  final Function onSave;

  const CreateMcqSetDialog({this.mcqSet, required this.onSave});

  @override
  _CreateMcqSetDialogState createState() => _CreateMcqSetDialogState();
}

class _CreateMcqSetDialogState extends State<CreateMcqSetDialog> {
  // ✅ FIXED: Changed from 'final' to 'late final'
  late final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.mcqSet != null) {
      // ✅ DATA VALIDATION: Safe initialization
      _titleController.text = widget.mcqSet!['title']?.toString() ?? '';
      _descriptionController.text = widget.mcqSet!['description']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveMcqSet() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final title = _titleController.text.trim();
        final description = _descriptionController.text.trim();
        
        // ✅ DATA VALIDATION: Additional validation
        if (title.isEmpty) {
          throw Exception('Tajuk tidak boleh kosong');
        }

        if (title.length > 200) {
          throw Exception('Tajuk terlalu panjang (maksimum 200 aksara)');
        }

        if (description.length > 500) {
          throw Exception('Penerangan terlalu panjang (maksimum 500 aksara)');
        }

        final mcqSetData = {
          'title': title,
          'description': description.isEmpty ? null : description,
        };

        if (widget.mcqSet != null) {
          final mcqSetId = widget.mcqSet!['id'];
          if (mcqSetId == null) {
            throw Exception('ID set MCQ tidak valid');
          }
          
          await _supabase
              .from('mcq_set')
              .update(mcqSetData)
              .eq('id', mcqSetId);
        } else {
          await _supabase.from('mcq_set').insert(mcqSetData);
        }

        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Set MCQ berjaya disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('❌ Ralat menyimpan set MCQ: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat menyimpan set MCQ: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.mcqSet != null ? 'Edit Set MCQ' : 'Cipta Set MCQ Baru'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tajuk Set*',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Ujian Matematik Bab 1',
                ),
                maxLength: 200,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sila masukkan tajuk set';
                  }
                  if (value.trim().length > 200) {
                    return 'Tajuk terlalu panjang (maksimum 200 aksara)';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Penerangan (opsional)',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Ujian ini meliputi topik algebra...',
                ),
                maxLength: 500,
                maxLines: 2,
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Penerangan terlalu panjang (maksimum 500 aksara)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        TextButton(
          onPressed: _isSaving ? null : _saveMcqSet,
          child: _isSaving
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Simpan', style: TextStyle(color: const Color.fromARGB(255, 166, 211, 145))),
        ),
      ],
    );
  }
}

// =============================================================================
// MCQ QUESTIONS PAGE
// =============================================================================

class McqQuestionsPage extends StatefulWidget {
  final Map<String, dynamic> mcqSet;

  const McqQuestionsPage({required this.mcqSet});

  @override
  _McqQuestionsPageState createState() => _McqQuestionsPageState();
}

class _McqQuestionsPageState extends State<McqQuestionsPage> {
  // ✅ FIXED: Changed from 'final' to 'late final'
  late final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _questionList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      // ✅ DATA VALIDATION: Validate MCQ set ID
      final mcqSetId = widget.mcqSet['id'];
      if (mcqSetId == null) {
        print('⚠️ MCQ Set ID tidak valid');
        setState(() => _isLoading = false);
        return;
      }

      final response = await _supabase
          .from('mcq_question')
          .select('*')
          .eq('mcq_set_id', mcqSetId)
          .order('created_at', ascending: true);

      // ✅ DATA VALIDATION: Validate response
      if (response == null) {
        print('⚠️ Response soalan null');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ DATA VALIDATION: Filter valid questions
      List<Map<String, dynamic>> validQuestions = [];
      for (var question in response) {
        // Validate required fields
        if (question['id'] == null || 
            question['question_text'] == null ||
            question['correct_answer'] == null) {
          print('⚠️ Skip soalan tidak valid: ${question['id']}');
          continue;
        }

        // Validate correct answer is one of a,b,c,d
        final correctAnswer = question['correct_answer'].toString().toLowerCase();
        if (!['a', 'b', 'c', 'd'].contains(correctAnswer)) {
          print('⚠️ Skip soalan: jawapan betul tidak valid: $correctAnswer');
          continue;
        }

        // Validate all options exist
        final hasAllOptions = ['a', 'b', 'c', 'd'].every((option) {
          final optionText = question['option_$option'];
          return optionText != null && optionText.toString().trim().isNotEmpty;
        });

        if (!hasAllOptions) {
          print('⚠️ Skip soalan: pilihan jawapan tidak lengkap');
          continue;
        }

        validQuestions.add(question);
      }

      setState(() {
        _questionList = validQuestions;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Ralat memuat soalan: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat soalan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addQuestion() async {
    // ✅ DATA VALIDATION: Validate MCQ set ID
    final mcqSetId = widget.mcqSet['id'];
    if (mcqSetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Set MCQ tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => McqQuestionFormDialog(
        mcqSetId: mcqSetId,
        onSave: _loadQuestions,
      ),
    );
  }

  Future<void> _editQuestion(Map<String, dynamic> question) async {
    // ✅ DATA VALIDATION: Validate question before editing
    if (question['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Soalan tidak valid untuk diedit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final mcqSetId = widget.mcqSet['id'];
    if (mcqSetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Set MCQ tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => McqQuestionFormDialog(
        mcqSetId: mcqSetId,
        question: question,
        onSave: _loadQuestions,
      ),
    );
  }

  Future<void> _deleteQuestion(String id) async {
    try {
      // ✅ DATA VALIDATION: Validate question ID
      if (id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ID soalan tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Padam Soalan'),
              content: Text('Adakah anda pasti mahu memadam soalan ini?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Padam', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;

      if (confirm) {
        await _supabase.from('mcq_question').delete().eq('id', id);
        _loadQuestions();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Soalan berjaya dipadam!')),
        );
      }
    } catch (e) {
      print('❌ Ralat memadam soalan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memadam soalan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ DATA VALIDATION: Safe title access
    final mcqSetTitle = widget.mcqSet['title']?.toString() ?? 'Set MCQ';

    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: AppBar(
        title: Text('Urus Soalan - $mcqSetTitle'),
        backgroundColor: TeacherColors.topBar,
        foregroundColor: TeacherColors.textDark,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _questionList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Tiada soalan ditambah', style: TextStyle(fontSize: 18)),
                      Text('Klik butang + untuk tambah soalan',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _questionList.length,
                  itemBuilder: (context, index) {
                    final question = _questionList[index];
                    
                    // ✅ DATA VALIDATION: Safe data access
                    final questionText = question['question_text']?.toString() ?? '[Tiada teks soalan]';
                    final explanation = question['explanation']?.toString();
                    
                    return Card(
                      color: TeacherColors.card,
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: TeacherColors.primaryGreen,
                                  radius: 16,
                                  child: Text('${index + 1}',
                                      style: TextStyle(color: Colors.white, fontSize: 14)),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    questionText,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: TeacherColors.primaryGreen),
                                  onPressed: () => _editQuestion(question),
                                  tooltip: 'Edit Soalan',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: TeacherColors.danger),
                                  onPressed: () => _deleteQuestion(question['id'].toString()),
                                  tooltip: 'Padam Soalan',
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildOptionRow('A', question['option_a']?.toString(), question['correct_answer'] == 'a'),
                            _buildOptionRow('B', question['option_b']?.toString(), question['correct_answer'] == 'b'),
                            _buildOptionRow('C', question['option_c']?.toString(), question['correct_answer'] == 'c'),
                            _buildOptionRow('D', question['option_d']?.toString(), question['correct_answer'] == 'd'),
                            if (explanation != null &&
                                explanation.trim().isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.lightbulb, color: Colors.blue, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          explanation,
                                          style: TextStyle(
                                            color: Colors.blue.shade800,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestion,
        child: Icon(Icons.add),
        backgroundColor: TeacherColors.primaryGreen,
        tooltip: 'Tambah Soalan',
      ),
    );
  }

  Widget _buildOptionRow(String label, String? text, bool isCorrect) {
    // ✅ DATA VALIDATION: Safe text display
    final displayText = text ?? 'Tiada teks';
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCorrect ? TeacherColors.success : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isCorrect ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                color: isCorrect ? TeacherColors.success : Colors.black87,
                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isCorrect) Icon(Icons.check_circle, color: TeacherColors.success, size: 20),
        ],
      ),
    );
  }
}

// =============================================================================
// MCQ QUESTION FORM DIALOG
// =============================================================================

class McqQuestionFormDialog extends StatefulWidget {
  final String mcqSetId;
  final Map<String, dynamic>? question;
  final Function onSave;

  const McqQuestionFormDialog({
    required this.mcqSetId,
    this.question,
    required this.onSave,
  });

  @override
  _McqQuestionFormDialogState createState() => _McqQuestionFormDialogState();
}

class _McqQuestionFormDialogState extends State<McqQuestionFormDialog> {
  // ✅ FIXED: Changed from 'final' to 'late final'
  late final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _explanationController = TextEditingController();
  String _correctAnswer = 'a';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      // ✅ DATA VALIDATION: Safe initialization with defaults
      _questionController.text = widget.question!['question_text']?.toString() ?? '';
      _optionAController.text = widget.question!['option_a']?.toString() ?? '';
      _optionBController.text = widget.question!['option_b']?.toString() ?? '';
      _optionCController.text = widget.question!['option_c']?.toString() ?? '';
      _optionDController.text = widget.question!['option_d']?.toString() ?? '';
      _correctAnswer = widget.question!['correct_answer']?.toString() ?? 'a';
      _explanationController.text = widget.question!['explanation']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        // ✅ DATA VALIDATION: Validate all fields
        final questionText = _questionController.text.trim();
        final optionA = _optionAController.text.trim();
        final optionB = _optionBController.text.trim();
        final optionC = _optionCController.text.trim();
        final optionD = _optionDController.text.trim();
        final explanation = _explanationController.text.trim();
        
        // Additional validation
        if (questionText.isEmpty) throw Exception('Soalan tidak boleh kosong');
        if (optionA.isEmpty) throw Exception('Pilihan A tidak boleh kosong');
        if (optionB.isEmpty) throw Exception('Pilihan B tidak boleh kosong');
        if (optionC.isEmpty) throw Exception('Pilihan C tidak boleh kosong');
        if (optionD.isEmpty) throw Exception('Pilihan D tidak boleh kosong');
        
        if (questionText.length > 500) {
          throw Exception('Soalan terlalu panjang (maksimum 500 aksara)');
        }
        
        if (optionA.length > 200 || optionB.length > 200 || 
            optionC.length > 200 || optionD.length > 200) {
          throw Exception('Pilihan jawapan terlalu panjang (maksimum 200 aksara)');
        }
        
        if (explanation.length > 1000) {
          throw Exception('Penjelasan terlalu panjang (maksimum 1000 aksara)');
        }
        
        // Check for duplicate options
        final options = [optionA, optionB, optionC, optionD];
        final uniqueOptions = options.toSet();
        if (uniqueOptions.length < options.length) {
          throw Exception('Pilihan jawapan tidak boleh sama');
        }

        final questionData = {
          'question_text': questionText,
          'option_a': optionA,
          'option_b': optionB,
          'option_c': optionC,
          'option_d': optionD,
          'correct_answer': _correctAnswer,
          'explanation': explanation.isEmpty ? null : explanation,
          'marks': 1,
          'mcq_set_id': widget.mcqSetId,
        };

        if (widget.question != null) {
          final questionId = widget.question!['id'];
          if (questionId == null) {
            throw Exception('ID soalan tidak valid');
          }
          
          await _supabase
              .from('mcq_question')
              .update(questionData)
              .eq('id', questionId);
        } else {
          await _supabase.from('mcq_question').insert(questionData);
        }

        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Soalan berjaya disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('❌ Ralat menyimpan soalan: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat menyimpan soalan: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                widget.question != null ? 'Edit Soalan' : 'Tambah Soalan Baru',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          labelText: 'Soalan*',
                          border: OutlineInputBorder(),
                          hintText: 'Masukkan teks soalan di sini...',
                        ),
                        maxLength: 500,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Sila masukkan soalan';
                          }
                          if (value.trim().length > 500) {
                            return 'Soalan terlalu panjang (maksimum 500 aksara)';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      Text('Pilihan Jawapan*:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      _buildOptionField('A', _optionAController, 'Pilihan pertama'),
                      SizedBox(height: 8),
                      _buildOptionField('B', _optionBController, 'Pilihan kedua'),
                      SizedBox(height: 8),
                      _buildOptionField('C', _optionCController, 'Pilihan ketiga'),
                      SizedBox(height: 8),
                      _buildOptionField('D', _optionDController, 'Pilihan keempat'),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _correctAnswer,
                        decoration: InputDecoration(
                          labelText: 'Jawapan Betul*',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(value: 'a', child: Text('Pilihan A')),
                          DropdownMenuItem(value: 'b', child: Text('Pilihan B')),
                          DropdownMenuItem(value: 'c', child: Text('Pilihan C')),
                          DropdownMenuItem(value: 'd', child: Text('Pilihan D')),
                        ],
                        validator: (value) {
                          if (value == null || !['a', 'b', 'c', 'd'].contains(value)) {
                            return 'Sila pilih jawapan betul';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() => _correctAnswer = value!),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _explanationController,
                        decoration: InputDecoration(
                          labelText: 'Penjelasan/Catatan (opsional)',
                          border: OutlineInputBorder(),
                          hintText: 'Masukkan penjelasan atau nota untuk soalan ini...',
                        ),
                        maxLength: 1000,
                        maxLines: 3,
                        validator: (value) {
                          if (value != null && value.length > 1000) {
                            return 'Penjelasan terlalu panjang (maksimum 1000 aksara)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text('Batal'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeacherColors.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Simpan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionField(String label, TextEditingController controller, String hintText) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Pilihan $label*',
        border: OutlineInputBorder(),
        hintText: hintText,
        prefixIcon: CircleAvatar(
          radius: 12,
          backgroundColor: TeacherColors.primaryGreen,
          child: Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
      maxLength: 200,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Sila masukkan pilihan $label';
        }
        if (value.trim().length > 200) {
          return 'Pilihan terlalu panjang (maksimum 200 aksara)';
        }
        return null;
      },
    );
  }
}