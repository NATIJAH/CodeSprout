import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

class StudentTaskSubmission extends StatefulWidget {
  final Map<String, dynamic> task;

  const StudentTaskSubmission({
    super.key,
    required this.task,
  });

  @override
  State<StudentTaskSubmission> createState() => _StudentTaskSubmissionState();
}

class _StudentTaskSubmissionState extends State<StudentTaskSubmission> {
  final supabase = Supabase.instance.client;
  final descriptionCtrl = TextEditingController();

  Uint8List? fileBytes;
  String? fileName;
  String? submissionFileUrl;
  bool isLoading = false;
  bool isUploadingFile = false;
  
  Map<String, dynamic>? existingSubmission;

  @override
  void initState() {
    super.initState();
    loadExistingSubmission();
  }

  Future<void> loadExistingSubmission() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final data = await supabase
          .from('submissions')
          .select()
          .eq('task_id', widget.task['id'])
          .eq('student_uid', currentUser.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          existingSubmission = data;
          descriptionCtrl.text = data['description'] ?? '';
          submissionFileUrl = data['file_url'];
          fileName = data['file_name'];
        });
      }
    } catch (e) {
      print('Error loading submission: $e');
    }
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg', 'zip'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          fileBytes = result.files.first.bytes;
          fileName = result.files.first.name;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📎 File selected: $fileName'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> uploadFileToSupabase() async {
    if (fileBytes == null || fileName == null) return submissionFileUrl;

    setState(() {
      isUploadingFile = true;
    });

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'submissions/${currentUser.id}/$timestamp-$fileName';

      await supabase.storage
          .from('task-submissions')
          .uploadBinary(filePath, fileBytes!);

      final fileUrl = supabase.storage
          .from('task-submissions')
          .getPublicUrl(filePath);

      return fileUrl;
    } catch (e) {
      print('Error uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      setState(() {
        isUploadingFile = false;
      });
    }
  }

  Future<void> submitTask() async {
    if (descriptionCtrl.text.trim().isEmpty && fileBytes == null && submissionFileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a description or upload a file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Upload file if new file selected
      String? fileUrl = await uploadFileToSupabase();

      final submissionData = {
        'task_id': widget.task['id'],
        'student_uid': currentUser.id,
        'description': descriptionCtrl.text.trim(),
        'file_url': fileUrl,
        'file_name': fileName,
        'submitted_at': DateTime.now().toIso8601String(),
        'status': 'submitted',
      };

      if (existingSubmission == null) {
        // Create new submission
        await supabase.from('submissions').insert(submissionData);
      } else {
        // Update existing submission
        await supabase
            .from('submissions')
            .update(submissionData)
            .eq('id', existingSubmission!['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingSubmission == null
                ? '✅ Task submitted successfully!'
                : '✅ Submission updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> openAttachment(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueDate = widget.task['due_date'] != null
        ? DateTime.tryParse(widget.task['due_date'])
        : null;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task['title'] ?? 'Task Submission'),
        backgroundColor: const Color(0xff5b7cff),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Details Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Task Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    
                    // Description
                    if (widget.task['description_text'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          widget.task['description_text'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),

                    // Task metadata
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (dueDate != null)
                          _buildInfoChip(
                            Icons.calendar_today,
                            'Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                            isOverdue ? Colors.red : Colors.blue,
                          ),
                        if (widget.task['points'] != null)
                          _buildInfoChip(
                            Icons.stars,
                            '${widget.task['points']} points',
                            Colors.amber,
                          ),
                        if (widget.task['category'] != null)
                          _buildInfoChip(
                            Icons.category,
                            widget.task['category'],
                            Colors.purple,
                          ),
                        if (widget.task['priority'] != null)
                          _buildInfoChip(
                            Icons.flag,
                            widget.task['priority'],
                            _getPriorityColor(widget.task['priority']),
                          ),
                      ],
                    ),

                    // Teacher's attachment
                    if (widget.task['attachment_url'] != null) ...[
                      const Divider(height: 24),
                      const Text(
                        'Teacher\'s Attachment:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => openAttachment(widget.task['attachment_url']),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.file_present, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.task['attachment_name'] ?? 'Download Attachment',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(Icons.download, color: Colors.blue.shade700),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submission Form
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.upload_file, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          existingSubmission == null ? 'Your Submission' : 'Update Submission',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Description field
                    TextField(
                      controller: descriptionCtrl,
                      decoration: const InputDecoration(
                        labelText: "Description / Notes",
                        border: OutlineInputBorder(),
                        hintText: "Describe your work or add notes...",
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),

                    // File upload section
                    if (submissionFileUrl != null && fileBytes == null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Submitted file:',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    fileName ?? 'File submitted',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.swap_horiz),
                              onPressed: pickFile,
                              tooltip: 'Replace file',
                            ),
                          ],
                        ),
                      )
                    else if (fileBytes != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fileName!,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  fileBytes = null;
                                  fileName = null;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload File'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),

                    const SizedBox(height: 8),
                    Text(
                      'Supported: PDF, DOC, DOCX, TXT, PNG, JPG, ZIP',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading || isUploadingFile ? null : submitTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xff5b7cff),
                ),
                child: isLoading || isUploadingFile
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(isUploadingFile ? 'Uploading file...' : 'Submitting...'),
                        ],
                      )
                    : Text(
                        existingSubmission == null ? 'Submit Task' : 'Update Submission',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    descriptionCtrl.dispose();
    super.dispose();
  }
}