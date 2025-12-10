// teacher/lib/page/submission_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../service/supabase_service.dart';
import '../theme/color.dart';

class SubmissionPage extends StatefulWidget {
  @override
  _SubmissionPageState createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {
  int _selectedTab = 0;
  List<Map<String, dynamic>> _studentMarks = [];
  List<Map<String, dynamic>> _studentSubmissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load STUDENT MARKS/MCQ SCORES (we'll create this table next)
      final marksResponse = await SupabaseService.client
          .from('student_marks')
          .select('*')
          .order('submitted_at', ascending: false);

      // Load STUDENT SUBMISSIONS
      final submissionsResponse = await SupabaseService.client
          .from('student_submissions')
          .select('*')
          .order('submitted_at', ascending: false);

      setState(() {
        _studentMarks = List<Map<String, dynamic>>.from(marksResponse);
        _studentSubmissions = List<Map<String, dynamic>>.from(submissionsResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadFeedback(String submissionId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        String fileName = 'feedback_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final fileBytes = file.bytes;
        
        if (fileBytes != null) {
          await SupabaseService.client.storage
              .from('teacher-feedback')
              .uploadBinary(fileName, fileBytes);

          await SupabaseService.client
              .from('student_submissions')
              .update({
                'feedback_file': fileName,
                'graded': true,
                'teacher_feedback': 'Feedback provided',
              })
              .eq('id', submissionId);

          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Feedback uploaded successfully! ✅')),
          );
        }
      }
    } catch (e) {
      print('Error uploading feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _downloadSubmission(String filePath) async {
    try {
      await SupabaseService.client.storage
          .from('student-submissions')
          .download(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading student submission...')),
      );
    } catch (e) {
      print('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  Widget _buildMarksTab() {
    if (_studentMarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Student Marks Yet', style: TextStyle(fontSize: 18)),
            Text('Students haven\'t completed any MCQ tests', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _studentMarks.length,
      itemBuilder: (context, index) {
        final mark = _studentMarks[index];
        final score = mark['score'] ?? 0;
        final totalQuestions = mark['total_questions'] ?? 1;
        final percentage = (score / totalQuestions * 100).toInt();
        
        return Card(
          color: TeacherColors.card,
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getScoreColor(percentage),
              child: Text(
                '$percentage%',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            title: Text(
              mark['student_name'] ?? 'Unknown Student',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Test: ${mark['test_title'] ?? 'Unknown Test'}'),
                Text('Score: $score/$totalQuestions'),
                Text('Submitted: ${_formatDate(mark['submitted_at'])}'),
              ],
            ),
            trailing: Chip(
              backgroundColor: _getScoreColor(percentage).withOpacity(0.2),
              label: Text(
                '$percentage%',
                style: TextStyle(color: _getScoreColor(percentage), fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmissionsTab() {
    if (_studentSubmissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Student Submissions', style: TextStyle(fontSize: 18)),
            Text('Students haven\'t submitted any work yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _studentSubmissions.length,
      itemBuilder: (context, index) {
        final submission = _studentSubmissions[index];
        return Card(
          color: TeacherColors.card,
          elevation: 2,
          child: ListTile(
            leading: Icon(
              submission['graded'] == true ? Icons.assignment_turned_in : Icons.assignment,
              color: submission['graded'] == true ? TeacherColors.success : Colors.amber,
              size: 32,
            ),
            title: Text(
              submission['assignment_title'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student: ${submission['student_name']}'),
                Text('File: ${submission['file_name']}'),
                Text('Submitted: ${_formatDate(submission['submitted_at'])}'),
                if (submission['graded'] == true)
                  Text('✓ Graded', style: TextStyle(color: TeacherColors.success, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.download, color: TeacherColors.primaryGreen),
                  onPressed: () => _downloadSubmission(submission['file_path']),
                ),
                IconButton(
                  icon: Icon(Icons.feedback, color: Colors.blue),
                  onPressed: () => _uploadFeedback(submission['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return TeacherColors.success;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.amber;
    return TeacherColors.danger;
  }

  String _formatDate(String dateString) {
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
      backgroundColor: TeacherColors.background,
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: TeacherColors.topBar,
            child: Row(
              children: [
                _buildTab(0, 'Student Marks', Icons.assessment),
                _buildTab(1, 'PDF Submissions', Icons.assignment),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _selectedTab == 0 ? _buildMarksTab() : _buildSubmissionsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: Material(
        color: isSelected ? TeacherColors.primaryGreen.withOpacity(0.2) : Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: isSelected ? TeacherColors.primaryGreen : TeacherColors.textLight),
                SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? TeacherColors.primaryGreen : TeacherColors.textLight,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}