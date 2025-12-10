import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class TeacherEditTask extends StatefulWidget {
  final Map task;
  const TeacherEditTask({super.key, required this.task});

  @override
  _TeacherEditTaskState createState() => _TeacherEditTaskState();
}

class _TeacherEditTaskState extends State<TeacherEditTask> {
  final supabase = Supabase.instance.client;

  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController dueCtrl;
  late TextEditingController pointsCtrl;

  String priority = 'Medium';
  String category = 'Assignment';
  bool isLoading = false;

  // File upload
  Uint8List? fileBytes;
  String? fileName;
  String? existingFileUrl;
  String? existingFileName;
  bool isUploadingFile = false;
  bool removeExistingFile = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.task['title']);
    descCtrl = TextEditingController(text: widget.task['description_text']);
    dueCtrl = TextEditingController(text: widget.task['due_date']);
    pointsCtrl = TextEditingController(text: widget.task['points']?.toString() ?? '100');
    
    priority = widget.task['priority'] ?? 'Medium';
    category = widget.task['category'] ?? 'Assignment';
    existingFileUrl = widget.task['attachment_url'];
    existingFileName = widget.task['attachment_name'];
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          fileBytes = result.files.first.bytes;
          fileName = result.files.first.name;
          removeExistingFile = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📎 New file selected: $fileName'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
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
    if (fileBytes == null || fileName == null) return null;

    setState(() {
      isUploadingFile = true;
    });

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'tasks/${currentUser.id}/$timestamp-$fileName';

      await supabase.storage
          .from('task-attachments')
          .uploadBinary(filePath, fileBytes!);

      final fileUrl = supabase.storage
          .from('task-attachments')
          .getPublicUrl(filePath);

      return fileUrl;
    } catch (e) {
      print('Error uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File upload failed: $e'),
            backgroundColor: Colors.orange,
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

  Future<void> updateTask() async {
    if (titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (dueCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a due date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Upload new file if selected
      String? newFileUrl;
      String? newFileName;
      
      if (fileBytes != null) {
        newFileUrl = await uploadFileToSupabase();
        newFileName = fileName;
      } else if (removeExistingFile) {
        newFileUrl = null;
        newFileName = null;
      } else {
        newFileUrl = existingFileUrl;
        newFileName = existingFileName;
      }

      await supabase
          .from('Tasks')
          .update({
            'title': titleCtrl.text.trim(),
            'description_text': descCtrl.text.trim(),
            'due_date': dueCtrl.text.trim(),
            'priority': priority,
            'category': category,
            'points': int.tryParse(pointsCtrl.text) ?? 100,
            'attachment_url': newFileUrl,
            'attachment_name': newFileName,
          })
          .eq('id', widget.task['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Task updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating task: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Task"),
        backgroundColor: const Color(0xff5b7cff),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Title *",
                  border: OutlineInputBorder(),
                  hintText: "Enter task title",
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                  hintText: "Enter task description",
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: ['Assignment', 'Homework', 'Project', 'Quiz', 'Reading', 'Lab Work', 'Other']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => category = val!),
              ),
              const SizedBox(height: 16),

              // Priority Dropdown
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(
                  labelText: "Priority",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: ['Low', 'Medium', 'High', 'Urgent']
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: p == 'Low'
                                    ? Colors.green
                                    : p == 'Medium'
                                        ? Colors.blue
                                        : p == 'High'
                                            ? Colors.orange
                                            : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(p),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => priority = val!),
              ),
              const SizedBox(height: 16),

              // Points
              TextField(
                controller: pointsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Points",
                  border: OutlineInputBorder(),
                  hintText: "100",
                  prefixIcon: Icon(Icons.stars),
                ),
              ),
              const SizedBox(height: 16),

              // Due Date
              TextField(
                controller: dueCtrl,
                decoration: const InputDecoration(
                  labelText: "Due Date (YYYY-MM-DD) *",
                  border: OutlineInputBorder(),
                  hintText: "2025-12-31",
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    dueCtrl.text = date.toIso8601String().split('T')[0];
                  }
                },
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // File Attachment Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.attach_file, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Attachment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Existing file
                    if (existingFileName != null && !removeExistingFile && fileBytes == null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              existingFileName!.endsWith('.pdf')
                                  ? Icons.picture_as_pdf
                                  : existingFileName!.endsWith('.doc') || existingFileName!.endsWith('.docx')
                                      ? Icons.description
                                      : Icons.image,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current file:',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    existingFileName!,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  removeExistingFile = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                    // New file selected
                    if (fileName != null && fileBytes != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              fileName!.endsWith('.pdf')
                                  ? Icons.picture_as_pdf
                                  : fileName!.endsWith('.doc') || fileName!.endsWith('.docx')
                                      ? Icons.description
                                      : Icons.image,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'New file:',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    fileName!,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  fileBytes = null;
                                  fileName = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                    // Upload button
                    if ((existingFileName == null || removeExistingFile) && fileBytes == null)
                      OutlinedButton.icon(
                        onPressed: pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Choose New File'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      )
                    else if (existingFileName != null && !removeExistingFile && fileBytes == null)
                      OutlinedButton.icon(
                        onPressed: pickFile,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Replace File'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),

                    const SizedBox(height: 8),
                    Text(
                      'Supported: PDF, DOC, DOCX, TXT, PNG, JPG',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading || isUploadingFile ? null : updateTask,
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
                            Text(isUploadingFile ? 'Uploading file...' : 'Updating task...'),
                          ],
                        )
                      : const Text(
                          "Save Changes",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    dueCtrl.dispose();
    pointsCtrl.dispose();
    super.dispose();
  }
}