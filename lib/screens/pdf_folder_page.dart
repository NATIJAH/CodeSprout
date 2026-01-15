// teacher/lib/page/pdf_folder_page.dart
import 'package:flutter/material.dart';
import '../service/supabase_service.dart';
import '../theme/color.dart';
import 'pdf_page.dart'; // IMPORT HALAMAN PDF

class PdfFolderPage extends StatefulWidget {
  @override
  _PdfFolderPageState createState() => _PdfFolderPageState();
}

class _PdfFolderPageState extends State<PdfFolderPage> {
  List<Map<String, dynamic>> _folderList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Memuat senarai folder...');
      
      // Periksa sambungan internet
      final hasConnection = await _checkInternetConnection();
      if (!hasConnection) {
        throw Exception('Tiada sambungan internet. Sila semak rangkaian anda.');
      }

      final response = await SupabaseService.client
          .from('pdf_folder')
          .select('*')
          .order('created_at', ascending: false)
          .timeout(Duration(seconds: 30));

      // ✅ VALIDASI DATA: Periksa respon dari server
      if (response == null) {
        throw Exception('Server tidak memberikan respon. Sila cuba lagi.');
      }

      if (response is! List) {
        throw Exception('Format data tidak sah dari server.');
      }

      // ✅ VALIDASI DATA: Tapis folder yang sah
      List<Map<String, dynamic>> validFolders = [];
      final existingNames = <String>{};

      for (var folder in response) {
        try {
          if (folder is! Map<String, dynamic>) {
            print('⚠️ Skip folder: Format data tidak sah');
            continue;
          }

          // Validasi field wajib
          if (folder['id'] == null) {
            print('⚠️ Skip folder: ID tidak wujud');
            continue;
          }

          if (folder['name'] == null) {
            print('⚠️ Skip folder: Nama folder tidak wujud');
            continue;
          }

          // Validasi jenis data
          final folderId = folder['id'];
          if (folderId is! String && folderId is! int) {
            print('⚠️ Skip folder: ID bukan jenis string atau integer');
            continue;
          }

          // Pastikan nama folder tidak kosong selepas trim
          final folderName = folder['name'].toString().trim();
          if (folderName.isEmpty) {
            print('⚠️ Skip folder: Nama folder kosong');
            continue;
          }

          // Semak panjang nama folder
          if (folderName.length > 100) {
            print('⚠️ Skip folder: Nama folder terlalu panjang');
            continue;
          }

          // Semak nama folder unik (tidak sensitif huruf besar/kecil)
          final normalizedName = folderName.toLowerCase();
          if (existingNames.contains(normalizedName)) {
            print('⚠️ Skip folder: Nama folder "$folderName" sudah wujud');
            continue;
          }

          // Validasi penerangan jika ada
          if (folder['description'] != null) {
            final description = folder['description'].toString();
            if (description.length > 500) {
              print('⚠️ Penerangan folder "$folderName" dipendekkan');
              folder['description'] = description.substring(0, 500);
            }
          }

          existingNames.add(normalizedName);
          validFolders.add(Map<String, dynamic>.from(folder));
          
        } catch (e) {
          print('⚠️ Ralat memproses folder: $e');
          continue;
        }
      }

      print('✅ ${validFolders.length} folder berjaya dimuat');

      setState(() {
        _folderList = validFolders;
        _isLoading = false;
        _errorMessage = null;
      });

    } catch (e) {
      print('❌ Ralat memuat folder: $e');
      
      String errorMessage;
      if (e.toString().contains('timeout')) {
        errorMessage = 'Masa untuk memuat folder telah tamat. Sila cuba lagi.';
      } else if (e.toString().contains('internet')) {
        errorMessage = 'Tiada sambungan internet. Sila semak rangkaian anda.';
      } else if (e.toString().contains('Server')) {
        errorMessage = 'Masalah dengan pelayan. Sila cuba sebentar lagi.';
      } else {
        errorMessage = 'Gagal memuat folder: ${e.toString().replaceAll('Exception: ', '')}';
      }

      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });

      // Tunjukkan notifikasi hanya jika widget masih dalam tree
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Cuba Lagi',
              textColor: Colors.white,
              onPressed: _loadFolders,
            ),
          ),
        );
      }
    }
  }

  Future<bool> _checkInternetConnection() async {
    // Fungsi simulasi semakan sambungan internet
    // Anda boleh gantikan dengan package connectivity sebenar jika ada
    try {
      // Cuba buat request ringkas ke Supabase
      await SupabaseService.client
          .from('pdf_folder')
          .select('count')
          .limit(1)
          .timeout(Duration(seconds: 5));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _createFolder() async {
    await showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(
        existingFolderNames: _folderList.map((f) => f['name'].toString().toLowerCase()).toList(),
        onSave: _loadFolders,
      ),
    );
  }

  Future<void> _editFolder(Map<String, dynamic> folder) async {
    // ✅ VALIDASI DATA: Validasi folder sebelum edit
    if (folder['id'] == null) {
      _showErrorMessage('Folder tidak mempunyai ID yang sah.');
      return;
    }

    if (folder['name'] == null) {
      _showErrorMessage('Folder tidak mempunyai nama yang sah.');
      return;
    }

    // Dapatkan senarai nama folder lain untuk semakan pendua
    final otherFolderNames = _folderList
        .where((f) => f['id'].toString() != folder['id'].toString())
        .map((f) => f['name'].toString().toLowerCase())
        .toList();

    await showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(
        folder: folder,
        existingFolderNames: otherFolderNames,
        onSave: _loadFolders,
      ),
    );
  }

  Future<void> _deleteFolder(String id) async {
    // ✅ VALIDASI DATA: Validasi ID sebelum penghapusan
    if (id.isEmpty) {
      _showErrorMessage('ID folder tidak sah.');
      return;
    }

    // Cari folder untuk dapatkan nama
    final folder = _folderList.firstWhere(
      (f) => f['id'].toString() == id,
      orElse: () => {},
    );

    final folderName = folder['name']?.toString() ?? 'Folder ini';

    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('🔒 Sahkan Penghapusan Folder'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Adakah anda pasti mahu memadam folder "$folderName"?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, size: 18, color: Colors.red.shade700),
                            SizedBox(width: 8),
                            Text(
                              'TINDAKAN INI TIDAK BOLEH DIBATALKAN',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Semua PDF dalam folder ini akan dipadam\n'
                          '• Data tidak boleh dipulihkan semula\n'
                          '• Pastikan anda telah membuat sandaran jika perlu',
                          style: TextStyle(fontSize: 13, color: Colors.red.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal', style: TextStyle(color: Colors.grey.shade700)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: Text('Ya, Padam Folder'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      setState(() => _isLoading = true);

      // ✅ VALIDASI DATA: Semak jika folder wujud sebelum penghapusan
      final folderExists = await SupabaseService.client
          .from('pdf_folder')
          .select('id, name')
          .eq('id', id)
          .maybeSingle()
          .timeout(Duration(seconds: 10));

      if (folderExists == null) {
        throw Exception('Folder tidak wujud dalam pangkalan data.');
      }

      // Tunjukkan dialog pemuatan
      bool deleteSuccessful = false;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            Future<void> performDelete() async {
              try {
                // Padam PDF dalam folder ini dahulu
                await SupabaseService.client
                    .from('teacher_pdf')
                    .delete()
                    .eq('folder_id', id)
                    .timeout(Duration(seconds: 15));

                // Kemudian padam folder
                await SupabaseService.client
                    .from('pdf_folder')
                    .delete()
                    .eq('id', id)
                    .timeout(Duration(seconds: 15));

                deleteSuccessful = true;
                
                if (mounted) {
                  Navigator.pop(context);
                  _loadFolders();
                  _showSuccessMessage('Folder "$folderName" berjaya dipadam!');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showErrorMessage('Gagal memadam folder: ${e.toString()}');
                }
              }
            }

            // Mulakan penghapusan
            WidgetsBinding.instance.addPostFrameCallback((_) => performDelete());

            return AlertDialog(
              title: Text('Memadam Folder...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Sedang memadam folder "$folderName"...\n\n'
                    'Sila tunggu sebentar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        ),
      );

      if (!deleteSuccessful) {
        await _loadFolders();
      }

    } catch (e) {
      print('❌ Ralat memadam folder: $e');
      
      String errorMsg;
      if (e.toString().contains('timeout')) {
        errorMsg = 'Masa untuk memadam folder telah tamat. Sila cuba lagi.';
      } else if (e.toString().contains('wujud')) {
        errorMsg = 'Folder tidak ditemui. Ia mungkin telah dipadam.';
      } else {
        errorMsg = 'Ralat sistem: ${e.toString().replaceAll('Exception: ', '')}';
      }

      _showErrorMessage(errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openFolder(Map<String, dynamic> folder) {
    // ✅ VALIDASI DATA: Validasi folder sebelum navigasi
    if (folder['id'] == null) {
      _showErrorMessage('Folder tidak mempunyai ID yang sah.');
      return;
    }

    final folderName = folder['name']?.toString() ?? 'Folder Tanpa Nama';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPage(folder: folder),
      ),
    ).then((_) {
      // Refresh senarai folder selepas kembali dari halaman PDF
      _loadFolders();
    });
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 20),
            Text(
              'Ralat Memuat Folder',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage ?? 'Ralat tidak diketahui',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.red.shade800,
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFolders,
              icon: Icon(Icons.refresh),
              label: Text('Cuba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 20),
          Text(
            'Tiada Folder Dicipta',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Anda belum mempunyai sebarang folder. Cipta folder pertama anda untuk mula menyusun PDF.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _createFolder,
            icon: Icon(Icons.create_new_folder),
            label: Text('Cipta Folder Pertama'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderList() {
    return RefreshIndicator(
      onRefresh: _loadFolders,
      backgroundColor: TeacherColors.background,
      color: TeacherColors.primaryGreen,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _folderList.length,
        itemBuilder: (context, index) {
          final folder = _folderList[index];
          
          // ✅ VALIDASI DATA: Akses data yang selamat
          final folderName = folder['name']?.toString() ?? 'Folder Tanpa Nama';
          final folderDescription = folder['description']?.toString();
          final folderId = folder['id']?.toString();
          final createdAt = folder['created_at'];
          
          // Format tarikh jika ada
          String? formattedDate;
          if (createdAt != null) {
            try {
              final date = DateTime.parse(createdAt.toString());
              formattedDate = '${date.day}/${date.month}/${date.year}';
            } catch (e) {
              formattedDate = null;
            }
          }

          return Card(
            color: TeacherColors.card,
            elevation: 3,
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 133, 185).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.folder,
                  color: const Color.fromARGB(255, 0, 133, 185),
                  size: 28,
                ),
              ),
              title: Text(
                folderName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (folderDescription != null && folderDescription.trim().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 4),
                      child: Text(
                        folderDescription,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      if (formattedDate != null)
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                            SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            SizedBox(width: 12),
                          ],
                        ),
                      Icon(Icons.touch_app, size: 12, color: Colors.grey.shade500),
                      SizedBox(width: 4),
                      Text(
                        'Ketik untuk buka folder',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
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
                    icon: Icon(Icons.edit, size: 20),
                    onPressed: () => _editFolder(folder),
                    tooltip: 'Edit Folder',
                    color: TeacherColors.primaryGreen,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20),
                    onPressed: folderId != null ? () => _deleteFolder(folderId) : null,
                    tooltip: 'Padam Folder',
                    color: Colors.red.shade400,
                  ),
                ],
              ),
              onTap: () => _openFolder(folder),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: AppBar(
        title: Text(
          'Folder PDF',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: TeacherColors.card,
        elevation: 1,
        actions: [
          if (_folderList.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadFolders,
              tooltip: 'Segarkan Semula',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: TeacherColors.primaryGreen,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Memuat senarai folder...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _folderList.isEmpty
                  ? _buildEmptyView()
                  : _buildFolderList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createFolder,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Folder Baru',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: TeacherColors.primaryGreen,
        tooltip: 'Cipta Folder Baru',
        elevation: 4,
      ),
    );
  }
}

class CreateFolderDialog extends StatefulWidget {
  final Map<String, dynamic>? folder;
  final List<String> existingFolderNames;
  final Function onSave;

  const CreateFolderDialog({
    this.folder,
    required this.existingFolderNames,
    required this.onSave,
  });

  @override
  _CreateFolderDialogState createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.folder != null;
    
    if (_isEditMode) {
      _nameController.text = widget.folder!['name']?.toString() ?? '';
      _descriptionController.text = widget.folder!['description']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _validateFolderName(String value) {
    final name = value.trim();
    
    if (name.isEmpty) {
      return 'Sila masukkan nama folder';
    }
    
    if (name.length < 2) {
      return 'Nama folder terlalu pendek (minimum 2 aksara)';
    }
    
    if (name.length > 100) {
      return 'Nama folder terlalu panjang (maksimum 100 aksara)';
    }
    
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(name)) {
      return 'Tidak boleh mengandungi aksara khas: < > : " / \\ | ? *';
    }
    
    final startsWithInvalid = RegExp(r'^[ .]');
    final endsWithInvalid = RegExp(r'[ .]$');
    if (startsWithInvalid.hasMatch(name)) {
      return 'Tidak boleh bermula dengan ruang atau titik';
    }
    if (endsWithInvalid.hasMatch(name)) {
      return 'Tidak boleh berakhir dengan ruang atau titik';
    }
    
    // Semak nama folder unik
    final normalizedNewName = name.toLowerCase();
    if (widget.existingFolderNames.contains(normalizedNewName)) {
      return 'Nama "$name" sudah digunakan. Sila pilih nama lain.';
    }
    
    // Semak nama folder tidak hanya mengandungi nombor
    if (RegExp(r'^\d+$').hasMatch(name)) {
      return 'Nama folder tidak boleh hanya mengandungi nombor';
    }
    
    // Semak nama folder tidak mengandungi perkataan tidak sesuai
    final inappropriateWords = ['null', 'undefined', 'test', 'contoh'];
    if (inappropriateWords.contains(name.toLowerCase())) {
      return 'Sila gunakan nama folder yang lebih deskriptif';
    }
    
    return '';
  }

  String _validateDescription(String? value) {
    if (value == null || value.isEmpty) return '';
    
    if (value.length > 500) {
      return 'Penerangan terlalu panjang (maksimum 500 aksara)';
    }
    
    return '';
  }

  Future<void> _saveFolder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final folderName = _nameController.text.trim();
      final folderDescription = _descriptionController.text.trim();
      
      // Validasi tambahan
      final nameError = _validateFolderName(folderName);
      if (nameError.isNotEmpty) {
        throw Exception(nameError);
      }
      
      final descError = _validateDescription(folderDescription);
      if (descError.isNotEmpty) {
        throw Exception(descError);
      }

      final folderData = {
        'name': folderName,
        'description': folderDescription.isEmpty ? null : folderDescription,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_isEditMode) {
        final folderId = widget.folder!['id'];
        if (folderId == null) {
          throw Exception('ID folder tidak sah untuk diedit');
        }
        
        await SupabaseService.client
            .from('pdf_folder')
            .update(folderData)
            .eq('id', folderId)
            .timeout(Duration(seconds: 15));
      } else {
        folderData['created_at'] = DateTime.now().toIso8601String();
        await SupabaseService.client
            .from('pdf_folder')
            .insert(folderData)
            .timeout(Duration(seconds: 15));
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode 
                ? 'Folder "$folderName" berjaya dikemaskini!' 
                : 'Folder "$folderName" berjaya dicipta!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      print('❌ Ralat menyimpan folder: $e');
      
      String errorMessage;
      if (e.toString().contains('timeout')) {
        errorMessage = 'Masa untuk menyimpan folder telah tamat. Sila cuba lagi.';
      } else if (e.toString().contains('unik') || e.toString().contains('unique')) {
        errorMessage = 'Nama folder sudah wujud. Sila pilih nama lain.';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isEditMode ? Icons.edit : Icons.create_new_folder,
            color: TeacherColors.primaryGreen,
            size: 24,
          ),
          SizedBox(width: 12),
          Text(
            _isEditMode ? 'Kemaskini Folder' : 'Cipta Folder Baru',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              
              // Nama Folder
              Text(
                'Nama Folder*',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Nota Matematik, Latihan Sains, dll.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: TeacherColors.primaryGreen, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(Icons.folder, color: Colors.grey.shade500),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(fontSize: 15),
                maxLength: 100,
                validator: (value) {
                  final error = _validateFolderName(value ?? '');
                  return error.isEmpty ? null : error;
                },
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 4),
              
              // Penerangan
              Text(
                'Penerangan (Opsional)',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Terangkan tujuan folder ini (maksimum 500 aksara)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(fontSize: 15),
                maxLength: 500,
                maxLines: 4,
                minLines: 2,
                validator: (value) {
                  final error = _validateDescription(value);
                  return error.isEmpty ? null : error;
                },
                textInputAction: TextInputAction.done,
              ),
              
              // Nota
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                        SizedBox(width: 8),
                        Text(
                          'Nota Penting:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Nama folder mesti unik dan tidak boleh diulang\n'
                      '• Gunakan nama yang deskriptif dan mudah difahami\n'
                      '• Folder boleh mengandungi pelbagai fail PDF',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(
            'BATAL',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveFolder,
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherColors.primaryGreen,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isEditMode ? Icons.save : Icons.add, size: 18),
                    SizedBox(width: 6),
                    Text(
                      _isEditMode ? 'KEMASKINI' : 'SIMPAN',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}