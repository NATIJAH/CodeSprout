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

      setState(() {
        _mcqSetList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Ralat memuat set MCQ: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createMcqSet() async {
    await showDialog(
      context: context,
      builder: (context) => CreateMcqSetDialog(onSave: _loadMcqSets),
    );
  }

  Future<void> _editMcqSet(Map<String, dynamic> mcqSet) async {
    await showDialog(
      context: context,
      builder: (context) => CreateMcqSetDialog(mcqSet: mcqSet, onSave: _loadMcqSets),
    );
  }

  Future<void> _deleteMcqSet(String id) async {
    try {
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
        await _supabase
            .from('mcq_question')
            .delete()
            .eq('mcq_set_id', id);

        await _supabase.from('mcq_set').delete().eq('id', id);

        _loadMcqSets();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Set MCQ berjaya dipadam!')),
        );
      }
    } catch (e) {
      print('Ralat memadam set MCQ: $e');
    }
  }

  void _manageQuestions(Map<String, dynamic> mcqSet) {
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
                    final questionCount = mcqSet['mcq_question'] != null &&
                            (mcqSet['mcq_question'] as List).isNotEmpty
                        ? mcqSet['mcq_question'][0]['count'] ?? 0
                        : 0;
                    return Card(
                      color: TeacherColors.card,
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(Icons.quiz, color: const Color.fromARGB(255, 174, 202, 160), size: 32),
                        title: Text(
                          mcqSet['title'] ?? 'Tiada Tajuk',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (mcqSet['description'] != null &&
                                mcqSet['description'].toString().isNotEmpty)
                              Text(mcqSet['description']),
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
                              onPressed: () => _deleteMcqSet(mcqSet['id']),
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
      _titleController.text = widget.mcqSet!['title'] ?? '';
      _descriptionController.text = widget.mcqSet!['description'] ?? '';
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
        final mcqSetData = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        };

        if (widget.mcqSet != null) {
          await _supabase
              .from('mcq_set')
              .update(mcqSetData)
              .eq('id', widget.mcqSet!['id']);
        } else {
          await _supabase.from('mcq_set').insert(mcqSetData);
        }

        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Set MCQ berjaya disimpan!')),
        );
      } catch (e) {
        print('Ralat menyimpan set MCQ: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat menyimpan set MCQ: $e')),
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
                  labelText: 'Tajuk Set',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Sila masukkan tajuk set' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Penerangan (opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
      final response = await _supabase
          .from('mcq_question')
          .select('*')
          .eq('mcq_set_id', widget.mcqSet['id'])
          .order('created_at', ascending: true);

      setState(() {
        _questionList = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      print('Ralat memuat soalan: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addQuestion() async {
    await showDialog(
      context: context,
      builder: (context) => McqQuestionFormDialog(
        mcqSetId: widget.mcqSet['id'],
        onSave: _loadQuestions,
      ),
    );
  }

  Future<void> _editQuestion(Map<String, dynamic> question) async {
    await showDialog(
      context: context,
      builder: (context) => McqQuestionFormDialog(
        mcqSetId: widget.mcqSet['id'],
        question: question,
        onSave: _loadQuestions,
      ),
    );
  }

  Future<void> _deleteQuestion(String id) async {
    try {
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
      print('Ralat memadam soalan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: AppBar(
        title: Text('Urus Soalan - ${widget.mcqSet['title']}'),
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
                                    question['question_text'] ?? '',
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
                                  onPressed: () => _deleteQuestion(question['id']),
                                  tooltip: 'Padam Soalan',
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildOptionRow('A', question['option_a'], question['correct_answer'] == 'a'),
                            _buildOptionRow('B', question['option_b'], question['correct_answer'] == 'b'),
                            _buildOptionRow('C', question['option_c'], question['correct_answer'] == 'c'),
                            _buildOptionRow('D', question['option_d'], question['correct_answer'] == 'd'),
                            if (question['explanation'] != null &&
                                question['explanation'].toString().isNotEmpty)
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
                                          question['explanation'],
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
          Expanded(child: Text(text ?? '')),
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
      _questionController.text = widget.question!['question_text'] ?? '';
      _optionAController.text = widget.question!['option_a'] ?? '';
      _optionBController.text = widget.question!['option_b'] ?? '';
      _optionCController.text = widget.question!['option_c'] ?? '';
      _optionDController.text = widget.question!['option_d'] ?? '';
      _correctAnswer = widget.question!['correct_answer'] ?? 'a';
      _explanationController.text = widget.question!['explanation'] ?? '';
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
        final questionData = {
          'question_text': _questionController.text.trim(),
          'option_a': _optionAController.text.trim(),
          'option_b': _optionBController.text.trim(),
          'option_c': _optionCController.text.trim(),
          'option_d': _optionDController.text.trim(),
          'correct_answer': _correctAnswer,
          'explanation': _explanationController.text.trim().isEmpty
              ? null
              : _explanationController.text.trim(),
          'marks': 1,
          'mcq_set_id': widget.mcqSetId,
        };

        if (widget.question != null) {
          await _supabase
              .from('mcq_question')
              .update(questionData)
              .eq('id', widget.question!['id']);
        } else {
          await _supabase.from('mcq_question').insert(questionData);
        }

        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Soalan berjaya disimpan!')),
        );
      } catch (e) {
        print('Ralat menyimpan soalan: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat menyimpan soalan: $e')),
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
                          labelText: 'Soalan',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Sila masukkan soalan' : null,
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      Text('Pilihan Jawapan:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      _buildOptionField('A', _optionAController),
                      SizedBox(height: 8),
                      _buildOptionField('B', _optionBController),
                      SizedBox(height: 8),
                      _buildOptionField('C', _optionCController),
                      SizedBox(height: 8),
                      _buildOptionField('D', _optionDController),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _correctAnswer,
                        decoration: InputDecoration(
                          labelText: 'Jawapan Betul',
                          border: OutlineInputBorder(),
                        ),
                        items: ['a', 'b', 'c', 'd'].map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text('Pilihan ${option.toUpperCase()}'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _correctAnswer = value!),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _explanationController,
                        decoration: InputDecoration(
                          labelText: 'Penjelasan/Catatan (opsional)',
                          border: OutlineInputBorder(),
                          hintText: 'Ini akan dipaparkan selepas pelajar menjawab',
                        ),
                        maxLines: 3,
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

  Widget _buildOptionField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Pilihan $label',
        border: OutlineInputBorder(),
        prefixIcon: CircleAvatar(
          radius: 12,
          backgroundColor: TeacherColors.primaryGreen,
          child: Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Sila masukkan pilihan $label' : null,
    );
  }
}