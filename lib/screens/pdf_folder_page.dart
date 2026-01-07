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

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final response = await SupabaseService.client
          .from('pdf_folder')
          .select('*')
          .order('created_at', ascending: false);

      // ✅ DATA VALIDATION: Validate response
      if (response == null) {
        print('⚠️ Response folder null dari server');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ DATA VALIDATION: Filter valid folders
      List<Map<String, dynamic>> validFolders = [];
      for (var folder in response) {
        // Validate required fields
        if (folder['id'] == null || folder['name'] == null) {
          print('⚠️ Skip folder tidak valid: ID atau nama tiada');
          continue;
        }

        // Validate data types
        if (folder['id'] is! String && folder['id'] is! int) {
          print('⚠️ Skip folder: ID bukan string atau integer');
          continue;
        }

        // Ensure name is not empty after trimming
        final folderName = folder['name'].toString().trim();
        if (folderName.isEmpty) {
          print('⚠️ Skip folder: Nama folder kosong');
          continue;
        }

        // Check for duplicate names in current list (case-insensitive)
        final exists = validFolders.any((f) => 
            f['name'].toString().toLowerCase() == folderName.toLowerCase());
        if (exists) {
          print('⚠️ Skip folder: Nama folder sudah wujud');
          continue;
        }

        validFolders.add(folder);
      }

      setState(() {
        _folderList = validFolders;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Ralat memuat folder: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat folder'),
          backgroundColor: Colors.red,
        ),
      );
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
    // ✅ DATA VALIDATION: Validate folder before editing
    if (folder['id'] == null || folder['name'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Folder tidak valid untuk diedit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get list of other folder names for duplicate check
    final otherFolderNames = _folderList
        .where((f) => f['id'] != folder['id'])
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
    try {
      // ✅ DATA VALIDATION: Validate ID before deletion
      if (id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ID folder tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Padam Folder'),
              content: Text(
                  'Adakah anda pasti mahu memadam folder ini berserta semua PDF di dalamnya?\n\nTindakan ini tidak boleh dibatalkan.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Padam', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;

      if (confirm) {
        // ✅ DATA VALIDATION: Check if folder exists before deletion
        final folderExists = await SupabaseService.client
            .from('pdf_folder')
            .select('id')
            .eq('id', id)
            .single()
            .catchError((_) => null);

        if (folderExists == null) {
          throw Exception('Folder tidak wujud');
        }

        // Padam PDF dalam folder ini dahulu
        await SupabaseService.client
            .from('teacher_pdf')
            .delete()
            .eq('folder_id', id);

        // Kemudian padam folder
        await SupabaseService.client.from('pdf_folder').delete().eq('id', id);

        _loadFolders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Folder berjaya dipadam!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Ralat memadam folder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memadam folder: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openFolder(Map<String, dynamic> folder) {
    // ✅ DATA VALIDATION: Validate folder before navigation
    if (folder['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Folder tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPage(folder: folder), // BUKA HALAMAN PDF DENGAN FOLDER
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _folderList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Tiada folder dicipta', style: TextStyle(fontSize: 18)),
                      Text('Klik butang + untuk cipta folder pertama anda',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _folderList.length,
                  itemBuilder: (context, index) {
                    final folder = _folderList[index];
                    
                    // ✅ DATA VALIDATION: Safe data access
                    final folderName = folder['name']?.toString() ?? 'Folder Tanpa Nama';
                    final folderDescription = folder['description']?.toString();
                    final folderId = folder['id']?.toString();

                    return Card(
                      color: TeacherColors.card,
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(Icons.folder, color: const Color.fromARGB(255, 0, 133, 185), size: 32),
                        title: Text(
                          folderName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (folderDescription != null && folderDescription.trim().isNotEmpty)
                              Text(
                                folderDescription,
                                style: TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            SizedBox(height: 4),
                            Text(
                              'Ketik untuk lihat PDF',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: TeacherColors.primaryGreen),
                              onPressed: () => _editFolder(folder),
                              tooltip: 'Edit Folder',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: TeacherColors.danger),
                              onPressed: folderId != null ? () => _deleteFolder(folderId) : null,
                              tooltip: 'Padam Folder',
                            ),
                          ],
                        ),
                        onTap: () => _openFolder(folder),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createFolder,
        child: Icon(Icons.add),
        backgroundColor: const Color.fromARGB(255, 179, 207, 165),
        tooltip: 'Cipta Folder',
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

  @override
  void initState() {
    super.initState();
    if (widget.folder != null) {
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

  Future<void> _saveFolder() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final folderName = _nameController.text.trim();
        final folderDescription = _descriptionController.text.trim();
        
        // ✅ DATA VALIDATION: Additional validation
        if (folderName.isEmpty) {
          throw Exception('Nama folder tidak boleh kosong');
        }

        if (folderName.length > 100) {
          throw Exception('Nama folder terlalu panjang (maksimum 100 aksara)');
        }

        if (folderDescription.length > 500) {
          throw Exception('Penerangan terlalu panjang (maksimum 500 aksara)');
        }

        // Check for duplicate folder names (case-insensitive)
        final normalizedNewName = folderName.toLowerCase();
        if (widget.existingFolderNames.contains(normalizedNewName)) {
          throw Exception('Folder dengan nama "$folderName" sudah wujud');
        }

        // Check for invalid characters in folder name
        final invalidChars = RegExp(r'[<>:"/\\|?*]');
        if (invalidChars.hasMatch(folderName)) {
          throw Exception('Nama folder mengandungi aksara tidak dibenarkan: < > : " / \\ | ? *');
        }

        // Check for folder name starting or ending with spaces/dots
        if (folderName.startsWith(' ') || folderName.startsWith('.') ||
            folderName.endsWith(' ') || folderName.endsWith('.')) {
          throw Exception('Nama folder tidak boleh bermula atau berakhir dengan ruang atau titik');
        }

        final folderData = {
          'name': folderName,
          'description': folderDescription.isEmpty ? null : folderDescription,
        };

        if (widget.folder != null) {
          final folderId = widget.folder!['id'];
          if (folderId == null) {
            throw Exception('ID folder tidak valid');
          }
          
          await SupabaseService.client
              .from('pdf_folder')
              .update(folderData)
              .eq('id', folderId);
        } else {
          await SupabaseService.client.from('pdf_folder').insert(folderData);
        }

        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Folder berjaya disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('❌ Ralat menyimpan folder: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat menyimpan folder: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.folder != null ? 'Edit Folder' : 'Cipta Folder Baru'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Folder*',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Nota Matematik, Latihan Sains, dsb.',
                  suffixIcon: Icon(Icons.folder, color: Colors.grey),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sila masukkan nama folder';
                  }
                  if (value.trim().length > 100) {
                    return 'Nama folder terlalu panjang (maksimum 100 aksara)';
                  }
                  
                  final invalidChars = RegExp(r'[<>:"/\\|?*]');
                  if (invalidChars.hasMatch(value)) {
                    return 'Tidak boleh mengandungi: < > : " / \\ | ? *';
                  }
                  
                  if (value.startsWith(' ') || value.startsWith('.') ||
                      value.endsWith(' ') || value.endsWith('.')) {
                    return 'Tidak boleh bermula/berakhir dengan ruang atau titik';
                  }
                  
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Penerangan (opsional)',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Folder untuk nota mata pelajaran Matematik...',
                ),
                maxLength: 500,
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Penerangan terlalu panjang (maksimum 500 aksara)';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              Text(
                '* Nama folder mesti unik',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveFolder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 185, 211, 173),
            foregroundColor: Colors.black87,
          ),
          child: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Simpan'),
        ),
      ],
    );
  }
}