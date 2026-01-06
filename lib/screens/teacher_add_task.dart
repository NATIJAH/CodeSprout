import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class TeacherAddTask extends StatefulWidget {
  const TeacherAddTask({super.key});

  @override
  _TeacherAddTaskState createState() => _TeacherAddTaskState();
}

class _TeacherAddTaskState extends State<TeacherAddTask> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final dueCtrl = TextEditingController();
  final pointsCtrl = TextEditingController(text: '100');
  final supabase = Supabase.instance.client;

  // Matcha Green Color Palette
  static const Color matchaGreen = Color(0xFF87A96B);
  static const Color matchaLight = Color(0xFFC8D5B9);
  static const Color matchaDark = Color(0xFF5F7A4E);
  static const Color matchaAccent = Color(0xFFA4C2A5);
  static const Color bgLight = Color(0xFFF8FAF6);

  bool isLoading = false;
  String priority = 'Sederhana';
  String category = 'Tugasan';
  
  // File upload
  Uint8List? fileBytes;
  String? fileName;
  bool isUploadingFile = false;

  final Map<String, String> priorityMap = {
    'Rendah': 'Low',
    'Sederhana': 'Medium',
    'Tinggi': 'High',
    'Mendesak': 'Urgent',
  };

  final Map<String, String> categoryMap = {
    'Tugasan': 'Assignment',
    'Kerja Rumah': 'Homework',
    'Projek': 'Project',
    'Kuiz': 'Quiz',
    'Bacaan': 'Reading',
    'Kerja Makmal': 'Lab Work',
    'Lain-lain': 'Other',
  };

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
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Fail dipilih: $fileName', style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
            backgroundColor: matchaGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Ralat memilih fail: $e')),
            ],
          ),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      print('Error uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat naik fail: $e'),
            backgroundColor: Colors.orange[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Future<void> addTask() async {
    if (titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Sila masukkan tajuk tugasan'),
            ],
          ),
          backgroundColor: Colors.orange[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (dueCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Sila masukkan tarikh akhir'),
            ],
          ),
          backgroundColor: Colors.orange[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        throw Exception('Pengguna tidak disahkan. Sila log masuk semula.');
      }

      String? fileUrl;
      if (fileBytes != null) {
        fileUrl = await uploadFileToSupabase();
      }

      final response = await supabase.from('Tasks').insert({
        'title': titleCtrl.text.trim(),
        'description_text': descCtrl.text.trim(),
        'teacher_uid': currentUser.id,
        'due_date': dueCtrl.text.trim(),
        'status_text': 'pending',
        'priority': priorityMap[priority] ?? 'Medium',
        'category': categoryMap[category] ?? 'Assignment',
        'points': int.tryParse(pointsCtrl.text) ?? 100,
        'attachment_url': fileUrl,
        'attachment_name': fileName,
        'created_timestamp': DateTime.now().toIso8601String(),
      }).select();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Tugasan berjaya dicipta!', style: TextStyle(fontSize: 15)),
              ],
            ),
            backgroundColor: matchaGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Ralat mencipta tugasan: $e')),
              ],
            ),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Rendah':
        return Colors.green;
      case 'Sederhana':
        return matchaGreen;
      case 'Tinggi':
        return Colors.orange;
      case 'Mendesak':
        return Colors.red;
      default:
        return matchaGreen;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tugasan':
        return Icons.assignment;
      case 'Kerja Rumah':
        return Icons.home_work;
      case 'Projek':
        return Icons.folder_special;
      case 'Kuiz':
        return Icons.quiz;
      case 'Bacaan':
        return Icons.menu_book;
      case 'Kerja Makmal':
        return Icons.science;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: matchaDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Tugasan Baru',
          style: TextStyle(
            color: matchaDark,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 800;
          
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWideScreen ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [matchaGreen, matchaDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: matchaGreen.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.add_task,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cipta Tugasan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Lengkapkan maklumat tugasan untuk pelajar',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),

                    // Form Container
                    Container(
                      padding: EdgeInsets.all(isWideScreen ? 32 : 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            'Maklumat Asas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: matchaDark,
                            ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: titleCtrl,
                            decoration: InputDecoration(
                              labelText: "Tajuk Tugasan *",
                              hintText: "Contoh: Tugasan Matematik Bab 5",
                              prefixIcon: Icon(Icons.title, color: matchaGreen),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: matchaLight),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: matchaLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: matchaGreen, width: 2),
                              ),
                              filled: true,
                              fillColor: bgLight,
                            ),
                          ),
                          SizedBox(height: 20),

                          // Description
                          TextField(
                            controller: descCtrl,
                            decoration: InputDecoration(
                              labelText: "Keterangan",
                              hintText: "Masukkan keterangan tugasan...",
                              prefixIcon: Icon(Icons.description, color: matchaGreen),
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: matchaLight),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: matchaLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: matchaGreen, width: 2),
                              ),
                              filled: true,
                              fillColor: bgLight,
                            ),
                            maxLines: 4,
                          ),
                          SizedBox(height: 32),

                          // Category and Priority Row
                          Text(
                            'Kategori & Keutamaan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: matchaDark,
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          isWideScreen
                              ? Row(
                                  children: [
                                    Expanded(child: _buildCategoryDropdown()),
                                    SizedBox(width: 16),
                                    Expanded(child: _buildPriorityDropdown()),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildCategoryDropdown(),
                                    SizedBox(height: 16),
                                    _buildPriorityDropdown(),
                                  ],
                                ),
                          SizedBox(height: 32),

                          // Points and Due Date
                          Text(
                            'Markah & Tarikh',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: matchaDark,
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          isWideScreen
                              ? Row(
                                  children: [
                                    Expanded(child: _buildPointsField()),
                                    SizedBox(width: 16),
                                    Expanded(flex: 2, child: _buildDueDateField()),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildPointsField(),
                                    SizedBox(height: 16),
                                    _buildDueDateField(),
                                  ],
                                ),
                          SizedBox(height: 32),

                          // File Attachment
                          Text(
                            'Lampiran Fail',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: matchaDark,
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: bgLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: matchaLight, width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (fileName != null)
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: matchaLight),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: matchaLight.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            fileName!.endsWith('.pdf')
                                                ? Icons.picture_as_pdf
                                                : fileName!.endsWith('.doc') || 
                                                  fileName!.endsWith('.docx')
                                                    ? Icons.description
                                                    : Icons.image,
                                            color: matchaDark,
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fileName!,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: matchaDark,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Sedia untuk dimuat naik',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: matchaGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.close, color: Colors.red[400]),
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
                                  Column(
                                    children: [
                                      Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 48,
                                        color: matchaGreen,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Muat naik fail lampiran',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: matchaDark,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'PDF, DOC, DOCX, TXT, PNG, JPG, JPEG',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      OutlinedButton.icon(
                                        onPressed: pickFile,
                                        icon: Icon(Icons.upload_file),
                                        label: Text('Pilih Fail'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: matchaGreen,
                                          side: BorderSide(color: matchaGreen, width: 2),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 32),

                          // Create Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading || isUploadingFile ? null : addTask,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 18),
                                backgroundColor: matchaGreen,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[300],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading || isUploadingFile
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          isUploadingFile 
                                              ? 'Memuat naik fail...' 
                                              : 'Mencipta tugasan...',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle, size: 24),
                                        SizedBox(width: 12),
                                        Text(
                                          "Cipta Tugasan",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: category,
      decoration: InputDecoration(
        labelText: "Kategori",
        prefixIcon: Icon(_getCategoryIcon(category), color: matchaGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: matchaLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: matchaLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: matchaGreen, width: 2),
        ),
        filled: true,
        fillColor: bgLight,
      ),
      items: categoryMap.keys
          .map((cat) => DropdownMenuItem(
                value: cat,
                child: Row(
                  children: [
                    Icon(_getCategoryIcon(cat), size: 20, color: matchaDark),
                    SizedBox(width: 8),
                    Text(cat),
                  ],
                ),
              ))
          .toList(),
      onChanged: (val) => setState(() => category = val!),
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<String>(
      value: priority,
      decoration: InputDecoration(
        labelText: "Keutamaan",
        prefixIcon: Icon(Icons.flag, color: matchaGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: matchaLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: matchaLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: matchaGreen, width: 2),
        ),
        filled: true,
        fillColor: bgLight,
      ),
      items: priorityMap.keys
          .map((p) => DropdownMenuItem(
                value: p,
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: _getPriorityColor(p),
                    ),
                    SizedBox(width: 12),
                    Text(p),
                  ],
                ),
              ))
          .toList(),
      onChanged: (val) => setState(() => priority = val!),
    );
  }

  Widget _buildPointsField() {
    return TextField(
      controller: pointsCtrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: "Markah",
        hintText: "100",
        prefixIcon: Icon(Icons.stars, color: matchaGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: matchaLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: matchaLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: matchaGreen, width: 2),
        ),
        filled: true,
        fillColor: bgLight,
      ),
    );
  }

  Widget _buildDueDateField() {
    return TextField(
      controller: dueCtrl,
      decoration: InputDecoration(
        labelText: "Tarikh Akhir *",
        hintText: "Pilih tarikh",
        prefixIcon: Icon(Icons.calendar_today, color: matchaGreen),
        suffixIcon: Icon(Icons.arrow_drop_down, color: matchaDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: matchaLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: matchaLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: matchaGreen, width: 2),
        ),
        filled: true,
        fillColor: bgLight,
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: matchaGreen,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: matchaDark,
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
      readOnly: true,
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