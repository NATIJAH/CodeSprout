// teacher/lib/page/mcq_page.dart
import 'package:flutter/material.dart';
import '../service/supabase_service.dart';
import '../theme/color.dart';

class McqPage extends StatefulWidget {
  @override
  _McqPageState createState() => _McqPageState();
}

class _McqPageState extends State<McqPage> {
  List<Map<String, dynamic>> _mcqSetList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMcqSets();
  }

  Future<void> _loadMcqSets() async {
    try {
      final response = await SupabaseService.client
    .from('mcq_set')
    .select('*, mcq_question(count)')
    .order('created_at', ascending: false);

      
      setState(() {
        _mcqSetList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading MCQ sets: $e');
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
          title: Text('Delete MCQ Set'),
          content: Text('Are you sure you want to delete this MCQ set and all its questions?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;

      if (confirm) {
        // Delete questions first (due to foreign key)
        await SupabaseService.client
            .from('mcq_question')
            .delete()
            .eq('mcq_set_id', id);

        // Then delete the set
        await SupabaseService.client
            .from('mcq_set')
            .delete()
            .eq('id', id);

        _loadMcqSets();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MCQ set deleted successfully!')),
        );
      }
    } catch (e) {
      print('Error deleting MCQ set: $e');
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
                      Text('No MCQ sets created yet', style: TextStyle(fontSize: 18)),
                      Text('Click the + button to create your first MCQ set', 
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _mcqSetList.length,
                  itemBuilder: (context, index) {
                    final mcqSet = _mcqSetList[index];
                    return Card(
                      color: TeacherColors.card,
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(Icons.quiz, color: TeacherColors.primaryGreen, size: 32),
                        title: Text(
                          mcqSet['title'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (mcqSet['description'] != null)
                              Text(mcqSet['description']!),
                            Text('${mcqSet['mcq_question'][0]['count']} questions')

     ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: TeacherColors.primaryGreen),
                              onPressed: () => _editMcqSet(mcqSet),
                            ),
                            IconButton(
                              icon: Icon(Icons.manage_search, color: Colors.blue),
                              onPressed: () => _manageQuestions(mcqSet),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: TeacherColors.danger),
                              onPressed: () => _deleteMcqSet(mcqSet['id']),
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
        backgroundColor: TeacherColors.primaryGreen,
        tooltip: 'Create MCQ Set',
      ),
    );
  }
}

class CreateMcqSetDialog extends StatefulWidget {
  final Map<String, dynamic>? mcqSet;
  final Function onSave;

  const CreateMcqSetDialog({this.mcqSet, required this.onSave});

  @override
  _CreateMcqSetDialogState createState() => _CreateMcqSetDialogState();
}

class _CreateMcqSetDialogState extends State<CreateMcqSetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _questionCount = 5;

  @override
  void initState() {
    super.initState();
    if (widget.mcqSet != null) {
      _titleController.text = widget.mcqSet!['title'];
      _descriptionController.text = widget.mcqSet!['description'] ?? '';
    }
  }

  Future<void> _saveMcqSet() async {
    if (_formKey.currentState!.validate()) {
      try {
final mcqSetData = {
  'title': _titleController.text,
  'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
  // REMOVE THIS LINE: 'created_by': null,
};

       
        if (widget.mcqSet != null) {
          await SupabaseService.client
              .from('mcq_set')
              .update(mcqSetData)
              .eq('id', widget.mcqSet!['id']);
        } else {
          await SupabaseService.client
              .from('mcq_set')
              .insert(mcqSetData);
        }

        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MCQ set saved successfully!')),
        );
      } catch (e) {
        print('Error saving MCQ set: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving MCQ set: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.mcqSet != null ? 'Edit MCQ Set' : 'Create New MCQ Set'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Set Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Enter set title' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
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
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveMcqSet,
          child: Text('Save', style: TextStyle(color: TeacherColors.primaryGreen)),
        ),
      ],
    );
  }
}
class McqQuestionsPage extends StatefulWidget {
  final Map<String, dynamic> mcqSet;

  const McqQuestionsPage({required this.mcqSet});

  @override
  _McqQuestionsPageState createState() => _McqQuestionsPageState();
}

class _McqQuestionsPageState extends State<McqQuestionsPage> {
  List<Map<String, dynamic>> _questionList = [];
  bool _isLoading = true;

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
_questionList = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading questions: $e');
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
          title: Text('Delete Question'),
          content: Text('Are you sure you want to delete this question?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;

      if (confirm) {
        await SupabaseService.client
            .from('mcq_question')
            .delete()
            .eq('id', id);

        _loadQuestions();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question deleted successfully!')),
        );
      }
    } catch (e) {
      print('Error deleting question: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: AppBar(
        title: Text('Manage Questions - ${widget.mcqSet['title']}'),
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
                      Text('No questions added yet', style: TextStyle(fontSize: 18)),
                      Text('Click the + button to add questions', 
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
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: TeacherColors.primaryGreen,
                          child: Text('${index + 1}', style: TextStyle(color: Colors.white)),
                        ),
                        title: Text(
                          question['question_text'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('A: ${question['option_a']}'),
                            Text('B: ${question['option_b']}'),
                            Text('C: ${question['option_c']}'),
                            Text('D: ${question['option_d']}'),
                            SizedBox(height: 4),
                            Text(
                              'Correct: ${question['correct_answer'].toUpperCase()}',
                              style: TextStyle(
                                color: TeacherColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (question['explanation'] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    'Notes: ${question['explanation']}',
                                    style: TextStyle(
                                      color: TeacherColors.textLight,
                                      fontStyle: FontStyle.italic,
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
                              icon: Icon(Icons.edit, color: TeacherColors.primaryGreen),
                              onPressed: () => _editQuestion(question),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: TeacherColors.danger),
                              onPressed: () => _deleteQuestion(question['id']),
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
        tooltip: 'Add Question',
      ),
    );
  }
}

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
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _explanationController = TextEditingController();
  String _correctAnswer = 'a';

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionController.text = widget.question!['question_text'];
      _optionAController.text = widget.question!['option_a'];
      _optionBController.text = widget.question!['option_b'];
      _optionCController.text = widget.question!['option_c'];
      _optionDController.text = widget.question!['option_d'];
      _correctAnswer = widget.question!['correct_answer'];
      _explanationController.text = widget.question!['explanation'] ?? '';
    }
  }

  Future<void> _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      try {
        final questionData = {
          'question_text': _questionController.text,
          'option_a': _optionAController.text,
          'option_b': _optionBController.text,
          'option_c': _optionCController.text,
          'option_d': _optionDController.text,
          'correct_answer': _correctAnswer,
          'explanation': _explanationController.text.isEmpty ? null : _explanationController.text,
          'marks': 1,
          'mcq_set_id': widget.mcqSetId,
          'created_by': null,
        };

        if (widget.question != null) {
          // Update existing question
          await SupabaseService.client
              .from('mcq_question')
              .update(questionData)
              .eq('id', widget.question!['id']);
        } else {
          // Insert new question
          await SupabaseService.client
              .from('mcq_question')
              .insert(questionData);
        }

        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question saved successfully!')),
        );
      } catch (e) {
        print('Error saving question: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving question: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.question != null ? 'Edit Question' : 'Add New Question'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Enter question' : null,
                maxLines: 2,
              ),
              SizedBox(height: 12),
              Text('Options:'),
              TextFormField(
                controller: _optionAController,
                decoration: InputDecoration(
                  labelText: 'Option A',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Enter option A' : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _optionBController,
                decoration: InputDecoration(
                  labelText: 'Option B',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Enter option B' : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _optionCController,
                decoration: InputDecoration(
                  labelText: 'Option C',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Enter option C' : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _optionDController,
                decoration: InputDecoration(
                  labelText: 'Option D',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Enter option D' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _correctAnswer,
                decoration: InputDecoration(
                  labelText: 'Correct Answer',
                  border: OutlineInputBorder(),
                ),
                items: ['a', 'b', 'c', 'd'].map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text('Option ${option.toUpperCase()}'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _correctAnswer = value!),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _explanationController,
                decoration: InputDecoration(
                  labelText: 'Explanation/Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'This will appear after students answer',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveQuestion,
          child: Text('Save', style: TextStyle(color: TeacherColors.primaryGreen)),
        ),
      ],
    );
  }
}