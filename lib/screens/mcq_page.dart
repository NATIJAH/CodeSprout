import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/color.dart';

class McqPage extends StatefulWidget {
  @override
  _McqPageState createState() => _McqPageState();
}

class _McqPageState extends State<McqPage> {
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
      setState(() => _isLoading = true);
      
      final response = await _supabase
          .from('mcq_set')
          .select('*, mcq_question(count)')
          .order('created_at', ascending: false);

      // ✅ VALIDASI DATA: Semak struktur response
      if (response == null) {
        print('⚠️ Tiada data diterima dari server');
        _showSnackBar('Ralat: Tiada data diterima dari server', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // ✅ VALIDASI DATA: Filter set MCQ yang sah
      List<Map<String, dynamic>> validMcqSets = [];
      for (var mcqSet in response) {
        // Semak field wajib
        if (mcqSet['id'] == null || mcqSet['title'] == null) {
          print('⚠️ Langkau set MCQ: ID atau tajuk tiada');
          continue;
        }

        // Semak tajuk tidak kosong
        if (mcqSet['title'].toString().trim().isEmpty) {
          print('⚠️ Langkau set MCQ: Tajuk kosong');
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
      _showSnackBar('Gagal memuat set MCQ: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _createMcqSet() async {
    await showDialog(
      context: context,
      builder: (context) => CreateMcqSetDialog(onSave: _loadMcqSets),
    );
  }

  Future<void> _editMcqSet(Map<String, dynamic> mcqSet) async {
    // ✅ VALIDASI DATA: Semak set MCQ sebelum edit
    if (mcqSet['id'] == null || mcqSet['title'] == null) {
      _showSnackBar('Set MCQ tidak sah untuk diedit', Colors.red);
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => CreateMcqSetDialog(mcqSet: mcqSet, onSave: _loadMcqSets),
    );
  }

  Future<void> _deleteMcqSet(String id) async {
    try {
      // ✅ VALIDASI DATA: Semak ID sebelum padam
      if (id.isEmpty) {
        _showSnackBar('ID set MCQ tidak sah', Colors.red);
        return;
      }

      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Padam Set MCQ', style: TextStyle(color: Colors.red)),
              content: Text(
                'Adakah anda pasti mahu memadam set MCQ ini?\n\n🔴 Amaran: Semua soalan dalam set ini juga akan dipadam.',
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Padam'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ) ??
          false;

      if (confirm) {
        // Padam soalan dahulu (constraint foreign key)
        await _supabase
            .from('mcq_question')
            .delete()
            .eq('mcq_set_id', id);

        // Kemudian padam set MCQ
        await _supabase.from('mcq_set').delete().eq('id', id);

        await _loadMcqSets();
        _showSnackBar('✅ Set MCQ berjaya dipadam!', TeacherColors.success);
      }
    } catch (e) {
      print('❌ Ralat memadam set MCQ: $e');
      _showSnackBar('Gagal memadam set MCQ: ${e.toString()}', Colors.red);
    }
  }

  void _manageQuestions(Map<String, dynamic> mcqSet) {
    // ✅ VALIDASI DATA: Semak set MCQ sebelum navigasi
    if (mcqSet['id'] == null) {
      _showSnackBar('Set MCQ tidak sah', Colors.red);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => McqQuestionsPage(mcqSet: mcqSet),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: TeacherColors.primaryGreen,
                strokeWidth: 2.5,
              ),
            )
          : _mcqSetList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 80,
                        color: TeacherColors.primaryGreen.withOpacity(0.3),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Tiada Set MCQ Dijumpai',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: TeacherColors.textDark,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Mula cipta set MCQ pertama anda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Semua Set MCQ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: TeacherColors.textDark,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _mcqSetList.length,
                        itemBuilder: (context, index) {
                          final mcqSet = _mcqSetList[index];
                          
                          // ✅ VALIDASI DATA: Akses data dengan selamat
                          final questionCount = mcqSet['mcq_question'] != null &&
                                  (mcqSet['mcq_question'] as List).isNotEmpty
                              ? (mcqSet['mcq_question'][0] as Map<String, dynamic>)['count'] ?? 0
                              : 0;
                          
                          final title = mcqSet['title']?.toString() ?? 'Tajuk Tidak Diketahui';
                          final description = mcqSet['description']?.toString();
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: TeacherColors.primaryGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.quiz,
                                  color: TeacherColors.primaryGreen,
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: TeacherColors.textDark,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (description != null && description.trim().isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4, bottom: 6),
                                      child: Text(
                                        description,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: TeacherColors.primaryGreen.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$questionCount soalan',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: TeacherColors.primaryGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, size: 22),
                                    color: TeacherColors.primaryGreen,
                                    onPressed: () => _editMcqSet(mcqSet),
                                    tooltip: 'Edit Set',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.list_alt, size: 22),
                                    color: Colors.blue,
                                    onPressed: () => _manageQuestions(mcqSet),
                                    tooltip: 'Urus Soalan',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, size: 22),
                                    color: TeacherColors.danger,
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
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createMcqSet,
        child: Icon(Icons.add, color: Colors.white, size: 28),
        backgroundColor: TeacherColors.primaryGreen,
        tooltip: 'Cipta Set MCQ Baru',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }
}

// =============================================================================
// DIALOG: CIPTA/EDIT MCQ SET
// =============================================================================

class CreateMcqSetDialog extends StatefulWidget {
  final Map<String, dynamic>? mcqSet;
  final Function onSave;

  const CreateMcqSetDialog({this.mcqSet, required this.onSave});

  @override
  _CreateMcqSetDialogState createState() => _CreateMcqSetDialogState();
}

class _CreateMcqSetDialogState extends State<CreateMcqSetDialog> {
  late final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.mcqSet != null) {
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
        
        // ✅ VALIDASI DATA: Validasi tambahan
        if (title.isEmpty) throw Exception('Tajuk tidak boleh kosong');
        if (title.length > 200) throw Exception('Tajuk terlalu panjang (maksimum 200 aksara)');
        if (description.length > 500) throw Exception('Penerangan terlalu panjang (maksimum 500 aksara)');

        final mcqSetData = {
          'title': title,
          'description': description.isEmpty ? null : description,
        };

        if (widget.mcqSet != null) {
          final mcqSetId = widget.mcqSet!['id'];
          if (mcqSetId == null) throw Exception('ID set MCQ tidak sah');
          
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
            content: Text('✅ Set MCQ berjaya disimpan!'),
            backgroundColor: TeacherColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TeacherColors.primaryGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.quiz, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    widget.mcqSet != null ? 'Edit Set MCQ' : 'Cipta Set MCQ Baru',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maklumat Set MCQ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: TeacherColors.textDark,
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tajuk Set*',
                          labelStyle: TextStyle(color: TeacherColors.primaryGreen),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: TeacherColors.primaryGreen, width: 2),
                          ),
                          hintText: 'Contoh: Ujian Matematik Bab 1',
                          prefixIcon: Icon(Icons.title, color: TeacherColors.primaryGreen),
                        ),
                        maxLength: 200,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '🔴 Sila masukkan tajuk set';
                          }
                          if (value.trim().length > 200) {
                            return '🔴 Tajuk terlalu panjang (maksimum 200 aksara)';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 20),
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Penerangan (Opsional)',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: TeacherColors.primaryGreen, width: 2),
                          ),
                          hintText: 'Contoh: Ujian ini meliputi topik algebra...',
                          prefixIcon: Icon(Icons.description, color: Colors.grey[600]),
                        ),
                        maxLength: 500,
                        maxLines: 3,
                        validator: (value) {
                          if (value != null && value.length > 500) {
                            return '🔴 Penerangan terlalu panjang (maksimum 500 aksara)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(
                      'BATAL',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveMcqSet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeacherColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            children: [
                              Icon(Icons.save, size: 18),
                              SizedBox(width: 8),
                              Text('SIMPAN'),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HALAMAN: SOALAN MCQ
// =============================================================================

class McqQuestionsPage extends StatefulWidget {
  final Map<String, dynamic> mcqSet;

  const McqQuestionsPage({required this.mcqSet});

  @override
  _McqQuestionsPageState createState() => _McqQuestionsPageState();
}

class _McqQuestionsPageState extends State<McqQuestionsPage> {
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
      setState(() => _isLoading = true);
      
      // ✅ VALIDASI DATA: Semak ID set MCQ
      final mcqSetId = widget.mcqSet['id'];
      if (mcqSetId == null) {
        print('⚠️ ID Set MCQ tidak sah');
        _showSnackBar('Set MCQ tidak sah', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final response = await _supabase
          .from('mcq_question')
          .select('*')
          .eq('mcq_set_id', mcqSetId)
          .order('created_at', ascending: true);

      // ✅ VALIDASI DATA: Semak response
      if (response == null) {
        print('⚠️ Tiada response soalan');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ VALIDASI DATA: Filter soalan yang sah
      List<Map<String, dynamic>> validQuestions = [];
      for (var question in response) {
        // Semak field wajib
        if (question['id'] == null || 
            question['question_text'] == null ||
            question['correct_answer'] == null) {
          print('⚠️ Langkau soalan tidak sah: ${question['id']}');
          continue;
        }

        // Semak jawapan betul adalah a,b,c,d
        final correctAnswer = question['correct_answer'].toString().toLowerCase();
        if (!['a', 'b', 'c', 'd'].contains(correctAnswer)) {
          print('⚠️ Langkau soalan: jawapan betul tidak sah: $correctAnswer');
          continue;
        }

        // Semak semua pilihan wujud
        final hasAllOptions = ['a', 'b', 'c', 'd'].every((option) {
          final optionText = question['option_$option'];
          return optionText != null && optionText.toString().trim().isNotEmpty;
        });

        if (!hasAllOptions) {
          print('⚠️ Langkau soalan: pilihan jawapan tidak lengkap');
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
      _showSnackBar('Gagal memuat soalan: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _addQuestion() async {
    // ✅ VALIDASI DATA: Semak ID set MCQ
    final mcqSetId = widget.mcqSet['id'];
    if (mcqSetId == null) {
      _showSnackBar('Set MCQ tidak sah', Colors.red);
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
    // ✅ VALIDASI DATA: Semak soalan sebelum edit
    if (question['id'] == null) {
      _showSnackBar('Soalan tidak sah untuk diedit', Colors.red);
      return;
    }

    final mcqSetId = widget.mcqSet['id'];
    if (mcqSetId == null) {
      _showSnackBar('Set MCQ tidak sah', Colors.red);
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
      // ✅ VALIDASI DATA: Semak ID soalan
      if (id.isEmpty) {
        _showSnackBar('ID soalan tidak sah', Colors.red);
        return;
      }

      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Padam Soalan', style: TextStyle(color: Colors.red)),
              content: Text('Adakah anda pasti mahu memadam soalan ini?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Padam'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ) ??
          false;

      if (confirm) {
        await _supabase.from('mcq_question').delete().eq('id', id);
        await _loadQuestions();
        _showSnackBar('✅ Soalan berjaya dipadam!', TeacherColors.success);
      }
    } catch (e) {
      print('❌ Ralat memadam soalan: $e');
      _showSnackBar('Gagal memadam soalan: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mcqSetTitle = widget.mcqSet['title']?.toString() ?? 'Set MCQ';

    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: AppBar(
        title: Text(
          'Urus Soalan - $mcqSetTitle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: TeacherColors.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: TeacherColors.primaryGreen,
                strokeWidth: 2.5,
              ),
            )
          : _questionList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 80,
                        color: TeacherColors.primaryGreen.withOpacity(0.3),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Tiada Soalan Dijumpai',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: TeacherColors.textDark,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Mula tambah soalan pertama anda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _addQuestion,
                        child: Text(
                          'TAMBAH SOALAN PERTAMA',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TeacherColors.primaryGreen,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Semua Soalan (${_questionList.length})',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: TeacherColors.textDark,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: TeacherColors.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.list, size: 16, color: TeacherColors.primaryGreen),
                                SizedBox(width: 6),
                                Text(
                                  '${_questionList.length} soalan',
                                  style: TextStyle(
                                    color: TeacherColors.primaryGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _questionList.length,
                        itemBuilder: (context, index) {
                          final question = _questionList[index];
                          
                          final questionText = question['question_text']?.toString() ?? '[Tiada teks soalan]';
                          final explanation = question['explanation']?.toString();
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: TeacherColors.primaryGreen,
                                radius: 18,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                questionText,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: TeacherColors.textDark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Jawapan Betul: ${question['correct_answer'].toString().toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: TeacherColors.primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, size: 20),
                                    color: TeacherColors.primaryGreen,
                                    onPressed: () => _editQuestion(question),
                                    tooltip: 'Edit Soalan',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, size: 20),
                                    color: TeacherColors.danger,
                                    onPressed: () => _deleteQuestion(question['id'].toString()),
                                    tooltip: 'Padam Soalan',
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Pilihan jawapan
                                      _buildOptionItem('A', question['option_a']?.toString(), question['correct_answer'] == 'a'),
                                      _buildOptionItem('B', question['option_b']?.toString(), question['correct_answer'] == 'b'),
                                      _buildOptionItem('C', question['option_c']?.toString(), question['correct_answer'] == 'c'),
                                      _buildOptionItem('D', question['option_d']?.toString(), question['correct_answer'] == 'd'),
                                      
                                      // Penjelasan
                                      if (explanation != null && explanation.trim().isNotEmpty)
                                        Container(
                                          margin: EdgeInsets.only(top: 16),
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue.shade100),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.lightbulb, size: 18, color: Colors.blue),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Penjelasan',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.blue.shade800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                explanation,
                                                style: TextStyle(
                                                  color: Colors.blue.shade800,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestion,
        child: Icon(Icons.add, color: Colors.white, size: 28),
        backgroundColor: TeacherColors.primaryGreen,
        tooltip: 'Tambah Soalan Baru',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }

  Widget _buildOptionItem(String label, String? text, bool isCorrect) {
    final displayText = text ?? 'Tiada teks';
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? TeacherColors.success.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect ? TeacherColors.success.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCorrect ? TeacherColors.success : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isCorrect ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                color: isCorrect ? TeacherColors.success : Colors.grey.shade800,
                fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
          if (isCorrect)
            Icon(Icons.check_circle, color: TeacherColors.success, size: 22),
        ],
      ),
    );
  }
}

// =============================================================================
// DIALOG: BORANG SOALAN MCQ
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
        // ✅ VALIDASI DATA: Validasi semua field
        final questionText = _questionController.text.trim();
        final optionA = _optionAController.text.trim();
        final optionB = _optionBController.text.trim();
        final optionC = _optionCController.text.trim();
        final optionD = _optionDController.text.trim();
        final explanation = _explanationController.text.trim();
        
        // Validasi wajib
        if (questionText.isEmpty) throw Exception('Soalan tidak boleh kosong');
        if (optionA.isEmpty) throw Exception('Pilihan A tidak boleh kosong');
        if (optionB.isEmpty) throw Exception('Pilihan B tidak boleh kosong');
        if (optionC.isEmpty) throw Exception('Pilihan C tidak boleh kosong');
        if (optionD.isEmpty) throw Exception('Pilihan D tidak boleh kosong');
        
        // Validasi panjang
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
        
        // Semak pilihan duplikat
        final options = [optionA, optionB, optionC, optionD];
        final uniqueOptions = options.toSet();
        if (uniqueOptions.length < options.length) {
          throw Exception('🔴 Pilihan jawapan tidak boleh sama');
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
          if (questionId == null) throw Exception('ID soalan tidak sah');
          
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
            content: Text('✅ Soalan berjaya disimpan!'),
            backgroundColor: TeacherColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TeacherColors.primaryGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.question_answer, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    widget.question != null ? 'Edit Soalan MCQ' : 'Tambah Soalan MCQ Baru',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maklumat Soalan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: TeacherColors.textDark,
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // Soalan
                      TextFormField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          labelText: 'Soalan*',
                          labelStyle: TextStyle(color: TeacherColors.primaryGreen),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: TeacherColors.primaryGreen, width: 2),
                          ),
                          hintText: 'Masukkan teks soalan di sini...',
                          prefixIcon: Icon(Icons.question_mark, color: TeacherColors.primaryGreen),
                        ),
                        maxLength: 500,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '🔴 Sila masukkan soalan';
                          }
                          if (value.trim().length > 500) {
                            return '🔴 Soalan terlalu panjang (maksimum 500 aksara)';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 20),
                      
                      Text(
                        'Pilihan Jawapan*',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: TeacherColors.textDark,
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      _buildOptionField('A', _optionAController, 'Pilihan pertama'),
                      SizedBox(height: 12),
                      _buildOptionField('B', _optionBController, 'Pilihan kedua'),
                      SizedBox(height: 12),
                      _buildOptionField('C', _optionCController, 'Pilihan ketiga'),
                      SizedBox(height: 12),
                      _buildOptionField('D', _optionDController, 'Pilihan keempat'),
                      
                      SizedBox(height: 20),
                      
                      // Jawapan Betul
                      DropdownButtonFormField<String>(
                        value: _correctAnswer,
                        decoration: InputDecoration(
                          labelText: 'Jawapan Betul*',
                          labelStyle: TextStyle(color: TeacherColors.primaryGreen),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: TeacherColors.primaryGreen, width: 2),
                          ),
                          prefixIcon: Icon(Icons.check_circle, color: TeacherColors.primaryGreen),
                        ),
                        items: [
                          DropdownMenuItem(value: 'a', child: Text('Pilihan A')),
                          DropdownMenuItem(value: 'b', child: Text('Pilihan B')),
                          DropdownMenuItem(value: 'c', child: Text('Pilihan C')),
                          DropdownMenuItem(value: 'd', child: Text('Pilihan D')),
                        ],
                        validator: (value) {
                          if (value == null || !['a', 'b', 'c', 'd'].contains(value)) {
                            return '🔴 Sila pilih jawapan betul';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() => _correctAnswer = value!),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Penjelasan
                      TextFormField(
                        controller: _explanationController,
                        decoration: InputDecoration(
                          labelText: 'Penjelasan/Catatan (Opsional)',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: TeacherColors.primaryGreen, width: 2),
                          ),
                          hintText: 'Masukkan penjelasan atau nota untuk soalan ini...',
                          prefixIcon: Icon(Icons.lightbulb, color: Colors.grey[600]),
                        ),
                        maxLength: 1000,
                        maxLines: 3,
                        validator: (value) {
                          if (value != null && value.length > 1000) {
                            return '🔴 Penjelasan terlalu panjang (maksimum 1000 aksara)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(
                      'BATAL',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeacherColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            children: [
                              Icon(Icons.save, size: 18),
                              SizedBox(width: 8),
                              Text('SIMPAN'),
                            ],
                          ),
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
        labelStyle: TextStyle(color: TeacherColors.primaryGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: TeacherColors.primaryGreen, width: 2),
        ),
        hintText: hintText,
        prefixIcon: Container(
          width: 40,
          alignment: Alignment.center,
          child: CircleAvatar(
            radius: 12,
            backgroundColor: TeacherColors.primaryGreen,
            child: Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      maxLength: 200,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '🔴 Sila masukkan pilihan $label';
        }
        if (value.trim().length > 200) {
          return '🔴 Pilihan terlalu panjang (maksimum 200 aksara)';
        }
        return null;
      },
    );
  }
}