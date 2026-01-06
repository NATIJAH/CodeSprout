// student_task_submission.dart - Bahasa Melayu
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

// Shared Matcha Colors
class MatchaColors {
  static const primary = Color(0xFF7C9473);
  static const light = Color(0xFFA8B99E);
  static const dark = Color(0xFF5A6C51);
  static const background = Color(0xFFF5F7F3);
  static const accent = Color(0xFFB8C5A8);
  static const surface = Colors.white;
}

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
      print('Ralat memuatkan penghantaran: $e');
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Fail dipilih: $fileName')),
                ],
              ),
              backgroundColor: MatchaColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat memilih fail: $e'),
            backgroundColor: const Color(0xFFDC4C4C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<String?> uploadFileToSupabase() async {
    if (fileBytes == null || fileName == null) return submissionFileUrl;

    setState(() => isUploadingFile = true);

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('Pengguna tidak disahkan');

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
      print('Ralat memuat naik fail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat naik fail: $e'),
            backgroundColor: const Color(0xFFDC4C4C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return null;
    } finally {
      setState(() => isUploadingFile = false);
    }
  }

  Future<void> submitTask() async {
    if (descriptionCtrl.text.trim().isEmpty && fileBytes == null && submissionFileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Sila tambah keterangan atau muat naik fail')),
            ],
          ),
          backgroundColor: const Color(0xFFE88D3D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('Pengguna tidak disahkan');

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
        await supabase.from('submissions').insert(submissionData);
      } else {
        await supabase
            .from('submissions')
            .update(submissionData)
            .eq('id', existingSubmission!['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(existingSubmission == null
                      ? 'Tugasan berjaya dihantar!'
                      : 'Penghantaran berjaya dikemas kini!'),
                ),
              ],
            ),
            backgroundColor: MatchaColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat: $e'),
            backgroundColor: const Color(0xFFDC4C4C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> openAttachment(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tidak dapat membuka fail'),
            backgroundColor: const Color(0xFFDC4C4C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'Urgent':
        return const Color(0xFFDC4C4C);
      case 'High':
        return const Color(0xFFE88D3D);
      case 'Medium':
        return MatchaColors.primary;
      case 'Low':
        return MatchaColors.light;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;
    final dueDate = widget.task['due_date'] != null
        ? DateTime.tryParse(widget.task['due_date'])
        : null;
    final isOverdue = dueDate != null && 
        dueDate.isBefore(DateTime.now()) && 
        widget.task['status_text'] != 'completed';

    return Scaffold(
      backgroundColor: MatchaColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            backgroundColor: MatchaColors.surface,
            foregroundColor: MatchaColors.dark,
            title: Text(
              widget.task['title'] ?? 'Penghantaran Tugasan',
              style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                padding: EdgeInsets.all(isWideScreen ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Task Details Section
                    _buildSection(
                      icon: Icons.info_outline,
                      title: 'Butiran Tugasan',
                      color: MatchaColors.primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.task['description_text'] != null) ...[
                            Text(
                              widget.task['description_text'],
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade800,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Task Metadata
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (dueDate != null)
                                _buildInfoChip(
                                  icon: Icons.calendar_today_outlined,
                                  label: '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                                  color: isOverdue ? const Color(0xFFDC4C4C) : MatchaColors.primary,
                                ),
                              if (widget.task['points'] != null)
                                _buildInfoChip(
                                  icon: Icons.stars_outlined,
                                  label: '${widget.task['points']} mata',
                                  color: const Color(0xFFE88D3D),
                                ),
                              if (widget.task['category'] != null)
                                _buildInfoChip(
                                  icon: Icons.category_outlined,
                                  label: widget.task['category'],
                                  color: const Color(0xFF9B7EBD),
                                ),
                              if (widget.task['priority'] != null)
                                _buildInfoChip(
                                  icon: Icons.flag_outlined,
                                  label: widget.task['priority'],
                                  color: _getPriorityColor(widget.task['priority']),
                                ),
                            ],
                          ),

                          if (isOverdue) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC4C4C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFDC4C4C).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFDC4C4C),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Tugasan ini telah lewat',
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Teacher's Attachment
                          if (widget.task['attachment_url'] != null) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Lampiran Guru',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => openAttachment(widget.task['attachment_url']),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: MatchaColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: MatchaColors.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: MatchaColors.primary.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.file_present_outlined,
                                          color: MatchaColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          widget.task['attachment_name'] ?? 'Muat Turun Lampiran',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: MatchaColors.dark,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.download_outlined,
                                        color: MatchaColors.primary,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submission Form Section
                    _buildSection(
                      icon: existingSubmission == null 
                          ? Icons.upload_file_outlined 
                          : Icons.edit_outlined,
                      title: existingSubmission == null 
                          ? 'Penghantaran Anda' 
                          : 'Kemas Kini Penghantaran',
                      color: MatchaColors.primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description Field
                          TextField(
                            controller: descriptionCtrl,
                            decoration: InputDecoration(
                              labelText: "Keterangan / Nota",
                              hintText: "Terangkan kerja anda atau tambah nota...",
                              prefixIcon: const Icon(Icons.notes_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: MatchaColors.light),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: MatchaColors.light.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: MatchaColors.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: MatchaColors.background,
                            ),
                            maxLines: 6,
                          ),

                          const SizedBox(height: 20),

                          // File Upload Section
                          const Text(
                            'Lampiran',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (submissionFileUrl != null && fileBytes == null)
                            // Existing file
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: MatchaColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: MatchaColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: MatchaColors.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_outline,
                                      color: MatchaColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Fail yang dihantar',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          fileName ?? 'Fail dilampirkan',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: MatchaColors.dark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.swap_horiz),
                                    onPressed: pickFile,
                                    tooltip: 'Ganti fail',
                                    color: MatchaColors.primary,
                                  ),
                                ],
                              ),
                            )
                          else if (fileBytes != null)
                            // New file selected
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE88D3D).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE88D3D).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE88D3D).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.insert_drive_file_outlined,
                                      color: Color(0xFFE88D3D),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      fileName!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: MatchaColors.dark,
                                      ),
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
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            )
                          else
                            // No file selected
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: pickFile,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: MatchaColors.light.withOpacity(0.5),
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: MatchaColors.background,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.upload_file_outlined,
                                          color: MatchaColors.primary,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Klik untuk muat naik fail',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: MatchaColors.dark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'PDF, DOC, DOCX, TXT, PNG, JPG, ZIP',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading || isUploadingFile ? null : submitTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MatchaColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
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
                                  Text(
                                    isUploadingFile ? 'Memuat naik fail...' : 'Menghantar...',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    existingSubmission == null 
                                        ? Icons.send_outlined 
                                        : Icons.update_outlined,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    existingSubmission == null 
                                        ? 'Hantar Tugasan' 
                                        : 'Kemas Kini Penghantaran',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MatchaColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MatchaColors.light.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: MatchaColors.dark.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MatchaColors.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    descriptionCtrl.dispose();
    super.dispose();
  }
}