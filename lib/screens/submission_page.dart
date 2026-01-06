import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../service/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubmissionPage extends StatefulWidget {
  @override
  _SubmissionPageState createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {
  // ✅ FIXED: Get client safely
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      final response = await _supabase
          .from('student_submissions')
          .select('*')
          .order('submitted_at', ascending: false);

      setState(() {
        _submissions = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuatkan data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(String filePath, String fileName) async {
    try {
      print('Downloading: $filePath');
      
      if (kIsWeb) {
        final bytes = await _supabase.storage
            .from('teacher-pdf')
            .download(filePath);
            
        if (bytes != null) {
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.document.createElement('a') as html.AnchorElement
            ..href = url
            ..style.display = 'none'
            ..download = fileName;
          
          html.document.body!.children.add(anchor);
          anchor.click();
          html.document.body!.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Download started'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download ready'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      print('Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Student Submissions'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.green))
          : _submissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No submissions yet',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Students will appear here when they submit',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSubmissions,
                  color: Colors.green,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _submissions.length,
                    itemBuilder: (context, index) {
                      final submission = _submissions[index];
                      return _buildSubmissionCard(submission);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSubmissions,
        child: Icon(Icons.refresh),
        backgroundColor: Colors.green,
        tooltip: 'Refresh',
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    return Card(
      elevation: 2,
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
        title: Text(
          submission['assignment_title'] ?? 'Tugasan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: ${submission['student_name'] ?? 'Unknown'}'),
              SizedBox(height: 4),
              Text('File: ${submission['file_name']}'),
              if (submission['description'] != null && 
                  submission['description'].toString().isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  'Description: ${submission['description']}',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
              SizedBox(height: 4),
              Text(
                'Submitted: ${_formatDate(submission['submitted_at'])}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () => _downloadFile(
            submission['file_path'],
            submission['file_name'],
          ),
          icon: Icon(Icons.download, size: 18),
          label: Text('Download'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
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
}