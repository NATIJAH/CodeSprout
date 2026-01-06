// teacher_edit_task.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

// Matcha Colors
class MatchaColors {
  static const primary = Color(0xFF7C9473);
  static const light = Color(0xFFA8B99E);
  static const dark = Color(0xFF5A6C51);
  static const background = Color(0xFFF5F7F3);
  static const accent = Color(0xFFB8C5A8);
  static const surface = Colors.white;
}

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

  String priority = 'Sederhana';
  String category = 'Tugasan';
  bool isLoading = false;

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
    
    // Map English to Malay
    final priorityMap = {
      'Low': 'Rendah',
      'Medium': 'Sederhana',
      'High': 'Tinggi',
      'Urgent': 'Segera'
    };
    final categoryMap = {
      'Assignment': 'Tugasan',
      'Homework': 'Kerja Rumah',
      'Project': 'Projek',
      'Quiz': 'Kuiz',
      'Reading': 'Bacaan',
      'Lab Work': 'Kerja Makmal',
      'Other': 'Lain-lain'
    };
    
    priority = priorityMap[widget.task['priority']] ?? 'Sederhana';
    category = categoryMap[widget.task['category']] ?? 'Tugasan';
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
    if (fileBytes == null || fileName == null) return null;

    setState(() => isUploadingFile = true);

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('Pengguna tidak disahkan');

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
      print('Ralat memuat naik fail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat naik fail: $e'),
            backgroundColor: const Color(0xFFE88D3D),
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

  Future<void> updateTask() async {
    if (titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Sila masukkan tajuk tugasan'),
            ],
          ),
          backgroundColor: const Color(0xFFE88D3D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (dueCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Sila masukkan tarikh akhir'),
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

      // Map Malay back to English for database
      final priorityMap = {
        'Rendah': 'Low',
        'Sederhana': 'Medium',
        'Tinggi': 'High',
        'Segera': 'Urgent'
      };
      final categoryMap = {
        'Tugasan': 'Assignment',
        'Kerja Rumah': 'Homework',
        'Projek': 'Project',
        'Kuiz': 'Quiz',
        'Bacaan': 'Reading',
        'Kerja Makmal': 'Lab Work',
        'Lain-lain': 'Other'
      };

      await supabase
          .from('Tasks')
          .update({
            'title': titleCtrl.text.trim(),
            'description_text': descCtrl.text.trim(),
            'due_date': dueCtrl.text.trim(),
            'priority': priorityMap[priority] ?? 'Medium',
            'category': categoryMap[category] ?? 'Assignment',
            'points': int.tryParse(pointsCtrl.text) ?? 100,
            'attachment_url': newFileUrl,
            'attachment_name': newFileName,
          })
          .eq('id', widget.task['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Tugasan berjaya dikemas kini!'),
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
            content: Text('Ralat mengemas kini tugasan: $e'),
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Segera':
        return const Color(0xFFDC4C4C);
      case 'Tinggi':
        return const Color(0xFFE88D3D);
      case 'Sederhana':
        return MatchaColors.primary;
      case 'Rendah':
        return MatchaColors.light;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: MatchaColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            backgroundColor: MatchaColors.surface,
            foregroundColor: MatchaColors.dark,
            title: const Text(
              'Edit Tugasan',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
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
                    // Title Field
                    _buildTextField(
                      controller: titleCtrl,
                      label: 'Tajuk *',
                      hint: 'Masukkan tajuk tugasan',
                      icon: Icons.title_outlined,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 20),

                    // Description Field
                    _buildTextField(
                      controller: descCtrl,
                      label: 'Penerangan',
                      hint: 'Masukkan penerangan tugasan',
                      icon: Icons.description_outlined,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 20),

                    // Category and Priority Row
                    isWideScreen
                        ? Row(
                            children: [
                              Expanded(child: _buildCategoryDropdown()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildPriorityDropdown()),
                            ],
                          )
                        : Column(
                            children: [
                              _buildCategoryDropdown(),
                              const SizedBox(height: 20),
                              _buildPriorityDropdown(),
                            ],
                          ),
                    const SizedBox(height: 20),

                    // Points and Due Date Row
                    isWideScreen
                        ? Row(
                            children: [
                              Expanded(child: _buildPointsField()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDueDateField()),
                            ],
                          )
                        : Column(
                            children: [
                              _buildPointsField(),
                              const SizedBox(height: 20),
                              _buildDueDateField(),
                            ],
                          ),
                    const SizedBox(height: 24),

                    // File Attachment Section
                    _buildFileSection(),
                    const SizedBox(height: 32),

                    // Update Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading || isUploadingFile ? null : updateTask,
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
                                    isUploadingFile ? 'Memuat naik fail...' : 'Mengemas kini...',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Simpan Perubahan',
                                    style: TextStyle(
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
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
        fillColor: MatchaColors.surface,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: category,
      decoration: InputDecoration(
        labelText: 'Kategori',
        prefixIcon: const Icon(Icons.category_outlined),
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
        fillColor: MatchaColors.surface,
      ),
      items: ['Tugasan', 'Kerja Rumah', 'Projek', 'Kuiz', 'Bacaan', 'Kerja Makmal', 'Lain-lain']
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      onChanged: (val) => setState(() => category = val!),
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<String>(
      value: priority,
      decoration: InputDecoration(
        labelText: 'Keutamaan',
        prefixIcon: const Icon(Icons.flag_outlined),
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
        fillColor: MatchaColors.surface,
      ),
      items: ['Rendah', 'Sederhana', 'Tinggi', 'Segera']
          .map((p) => DropdownMenuItem(
                value: p,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(p),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(p),
                  ],
                ),
              ))
          .toList(),
      onChanged: (val) => setState(() => priority = val!),
    );
  }

  Widget _buildPointsField() {
    return _buildTextField(
      controller: pointsCtrl,
      label: 'Mata',
      hint: '100',
      icon: Icons.stars_outlined,
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildDueDateField() {
    return _buildTextField(
      controller: dueCtrl,
      label: 'Tarikh Akhir *',
      hint: 'YYYY-MM-DD',
      icon: Icons.calendar_today_outlined,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: MatchaColors.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          dueCtrl.text = date.toIso8601String().split('T')[0];
        }
      },
    );
  }

  Widget _buildFileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MatchaColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MatchaColors.light.withOpacity(0.3)),
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
                  color: MatchaColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.attach_file, color: MatchaColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lampiran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MatchaColors.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Existing file
          if (existingFileName != null && !removeExistingFile && fileBytes == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MatchaColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MatchaColors.primary.withOpacity(0.3)),
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
                          'Fail semasa',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          existingFileName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: MatchaColors.dark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() => removeExistingFile = true);
                    },
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            )
          else if (fileName != null && fileBytes != null)
            // New file selected
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE88D3D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE88D3D).withOpacity(0.3)),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fail baru',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fileName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: MatchaColors.dark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
            // No file
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
                        decoration: const BoxDecoration(
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
                        'PDF, DOC, DOCX, TXT, PNG, JPG',
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

          if ((existingFileName != null && !removeExistingFile) || fileBytes != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: pickFile,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Ganti Fail'),
              style: TextButton.styleFrom(
                foregroundColor: MatchaColors.primary,
              ),
            ),
          ],
        ],
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