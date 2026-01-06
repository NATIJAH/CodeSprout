import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseSubmissionPage extends StatefulWidget {
  @override
  _ExerciseSubmissionPageState createState() => _ExerciseSubmissionPageState();
}

class _ExerciseSubmissionPageState extends State<ExerciseSubmissionPage> {
  // ✅ FIXED: Changed to late final
  late final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _mySubmissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMySubmissions();
  }

  Future<void> _loadMySubmissions() async {
    try {
      final submissions = await _supabase
          .from('student_submissions')
          .select('*')
          .order('submitted_at', ascending: false);
      
      setState(() {
        _mySubmissions = List<Map<String, dynamic>>.from(submissions);
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadExercise() async {
    try {
      await _showUploadDialog();
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showUploadDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hantar Tugasan Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Nama Tugasan*',
                  hintText: 'Contoh: Latihan Bab 3',
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Penerangan tentang tugasan...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _processFileUpload(
                  title: titleController.text,
                  description: descController.text,
                );
              },
              child: Text('Pilih File'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 144, 194, 146)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processFileUpload({
    required String title,
    required String description,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null) return;

      final file = result.files.first;
      
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String uniqueFileName = 'sub_$timestamp.pdf';
      
      final fileBytes = file.bytes;
      if (fileBytes == null) return;

      await _supabase.storage
          .from('teacher-pdf')
          .uploadBinary(uniqueFileName, fileBytes);
      
      await _supabase
          .from('student_submissions')
          .insert({
            'assignment_title': title.isNotEmpty 
                ? title 
                : 'Tugasan ${DateTime.now().day}/${DateTime.now().month}',
            'description': description,
            'file_name': file.name,
            'file_path': uniqueFileName,
            'student_name': 'Pelajar',
            'graded': false,
            'is_editable': true,
          });

      await _loadMySubmissions();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ TUGASAN BERJAYA DIHANTAR!'),
          backgroundColor: const Color.fromARGB(255, 159, 199, 160),
        ),
      );

    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editSubmission(Map<String, dynamic> submission) async {
    final titleController = TextEditingController(
      text: submission['assignment_title']?.toString() ?? ''
    );
    final descController = TextEditingController(
      text: submission['description']?.toString() ?? ''
    );
    final id = submission['id']?.toString() ?? '';
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Tugasan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Nama Tugasan'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateSubmission(
                id: id,
                title: titleController.text,
                description: descController.text,
              );
            },
            child: Text('Simpan'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 147, 187, 148)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSubmission({
    required String id,
    required String title,
    required String description,
  }) async {
    try {
      await _supabase
          .from('student_submissions')
          .update({
            'assignment_title': title,
            'description': description,
          })
          .eq('id', id);

      await _loadMySubmissions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Tugasan dikemaskini!'), 
          backgroundColor: const Color.fromARGB(255, 156, 206, 157),
        ),
      );
    } catch (e) {
      print('Update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update: $e'), 
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSubmission(String id, String filePath) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Padam Tugasan?'),
        content: Text('Adakah anda pasti mahu padam tugasan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Padam'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.storage
          .from('teacher-pdf')
          .remove([filePath]);

      await _supabase
          .from('student_submissions')
          .delete()
          .eq('id', id);

      await _loadMySubmissions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Tugasan dipadam!'),
          backgroundColor: const Color.fromARGB(255, 166, 214, 167),
        ),
      );
    } catch (e) {
      print('Delete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal padam: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    bool isGraded = submission['graded'] == true;
    bool isEditable = submission['is_editable'] != false && !isGraded;
    
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(
          isGraded ? Icons.assignment_turned_in : Icons.assignment,
          color: isGraded ? const Color.fromARGB(255, 140, 218, 142) : Colors.blue,
          size: 32,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              submission['assignment_title']?.toString() ?? 'Tugasan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (submission['description'] != null && 
                submission['description'].toString().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  submission['description'].toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(submission['file_name']?.toString() ?? 'File'),
            Text('Dihantar: ${_formatDate(submission['submitted_at']?.toString())}'),
            if (isGraded) 
              Text('✅ Sudah Dinilai', style: TextStyle(color: Colors.green)),
          ],
        ),
        trailing: isEditable
            ? PopupMenuButton<String>(
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Padam'),
                      ],
                    ),
                  ),
                ],
                onSelected: (String value) {
                  if (value == 'edit') {
                    _editSubmission(submission);
                  } else if (value == 'delete') {
                    final filePath = submission['file_path']?.toString() ?? '';
                    final id = submission['id']?.toString() ?? '';
                    if (id.isNotEmpty && filePath.isNotEmpty) {
                      _deleteSubmission(id, filePath);
                    }
                  }
                },
              )
            : null,
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Hantar Tugasan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.green))
          : _mySubmissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Tiada tugasan dihantar', 
                        style: TextStyle(fontSize: 18)
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _uploadExercise,
                        child: Text('HANTAR TUGASAN PERTAMA'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMySubmissions,
                  color: Colors.green,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    itemCount: _mySubmissions.length,
                    itemBuilder: (context, index) {
                      return _buildSubmissionCard(_mySubmissions[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadExercise,
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
        tooltip: 'Hantar Tugasan Baru',
      ),
    );
  }
}