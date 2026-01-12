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
          backgroundColor: Colors.white,
          title: Text('Hantar Tugasan Baru', style: TextStyle(color: Color(0xFF2E7D32))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Nama Tugasan*',
                  labelStyle: TextStyle(color: Color(0xFF6B9B7F)),
                  hintText: 'Contoh: Latihan Bab 3',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6B9B7F)),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(color: Color(0xFF6B9B7F)),
                  hintText: 'Penerangan tentang tugasan...',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6B9B7F)),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _processFileUpload(
                  title: titleController.text,
                  description: descController.text,
                );
              },
              child: Text('Pilih File', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6B9B7F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
          backgroundColor: Color(0xFF6B9B7F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
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
        backgroundColor: Colors.white,
        title: Text('Edit Tugasan', style: TextStyle(color: Color(0xFF2E7D32))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Nama Tugasan',
                labelStyle: TextStyle(color: Color(0xFF6B9B7F)),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6B9B7F)),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Color(0xFF6B9B7F)),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6B9B7F)),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
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
            child: Text('Simpan', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6B9B7F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
          backgroundColor: Color(0xFF6B9B7F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      print('Update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update: $e'), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _deleteSubmission(String id, String filePath) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Padam Tugasan?', style: TextStyle(color: Colors.red)),
        content: Text('Adakah anda pasti mahu padam tugasan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Padam', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
          backgroundColor: Color(0xFF6B9B7F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      print('Delete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal padam: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    bool isGraded = submission['graded'] == true;
    bool isEditable = submission['is_editable'] != false && !isGraded;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isGraded 
              ? Color(0xFF66BB6A).withOpacity(0.15)
              : Color(0xFF6B9B7F).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isGraded ? Icons.assignment_turned_in : Icons.assignment,
            color: isGraded ? Color(0xFF66BB6A) : Color(0xFF6B9B7F),
            size: 24,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              submission['assignment_title']?.toString() ?? 'Tugasan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
                fontSize: 15,
              ),
            ),
            if (submission['description'] != null && 
                submission['description'].toString().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  submission['description'].toString(),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                submission['file_name']?.toString() ?? 'File',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              Text(
                'Dihantar: ${_formatDate(submission['submitted_at']?.toString())}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (isGraded) 
                Container(
                  margin: EdgeInsets.only(top: 6),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF66BB6A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Color(0xFF66BB6A).withOpacity(0.3)),
                  ),
                  child: Text(
                    '✅ Sudah Dinilai', 
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        trailing: isEditable
            ? PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Color(0xFF6B9B7F)),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Color(0xFF6B9B7F), size: 20),
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
    if (dateString == null) return 'Tarikh tidak diketahui';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E9),
      appBar: AppBar(
        title: Text(
          'Hantar Tugasan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF6B9B7F),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B9B7F),
                strokeWidth: 2.5,
              ),
            )
          : _mySubmissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 80,
                        color: Color(0xFF6B9B7F).withOpacity(0.3),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Tiada tugasan dihantar', 
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Mula hantar tugasan pertama anda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _uploadExercise,
                        child: Text(
                          'HANTAR TUGASAN PERTAMA',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6B9B7F),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMySubmissions,
                  color: Color(0xFF6B9B7F),
                  backgroundColor: Color(0xFFE8F5E9),
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
        child: Icon(Icons.add, color: Colors.white, size: 28),
        backgroundColor: Color(0xFF6B9B7F),
        tooltip: 'Hantar Tugasan Baru',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
    );
  }
}