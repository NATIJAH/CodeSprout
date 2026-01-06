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

      setState(() {
        _folderList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Ralat memuat folder: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createFolder() async {
    await showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(onSave: _loadFolders),
    );
  }

  Future<void> _editFolder(Map<String, dynamic> folder) async {
    await showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(folder: folder, onSave: _loadFolders),
    );
  }

  Future<void> _deleteFolder(String id) async {
    try {
      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Padam Folder'),
              content: Text(
                  'Adakah anda pasti mahu memadam folder ini berserta semua PDF di dalamnya?'),
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
        // Padam PDF dalam folder ini dahulu
        await SupabaseService.client
            .from('teacher_pdf')
            .delete()
            .eq('folder_id', id);

        // Kemudian padam folder
        await SupabaseService.client.from('pdf_folder').delete().eq('id', id);

        _loadFolders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder berjaya dipadam!')),
        );
      }
    } catch (e) {
      print('Ralat memadam folder: $e');
    }
  }

  void _openFolder(Map<String, dynamic> folder) {
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

                    return Card(
                      color: TeacherColors.card,
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(Icons.folder, color: const Color.fromARGB(255, 0, 133, 185), size: 32),
                        title: Text(
                          folder['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (folder['description'] != null)
                              Text(folder['description']!),
                            Text('Ketik untuk lihat PDF'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: TeacherColors.primaryGreen),
                              onPressed: () => _editFolder(folder),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: TeacherColors.danger),
                              onPressed: () => _deleteFolder(folder['id']),
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
  final Function onSave;

  const CreateFolderDialog({this.folder, required this.onSave});

  @override
  _CreateFolderDialogState createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.folder != null) {
      _nameController.text = widget.folder!['name'];
      _descriptionController.text = widget.folder!['description'] ?? '';
    }
  }

  Future<void> _saveFolder() async {
    if (_formKey.currentState!.validate()) {
      try {
        final folderData = {
          'name': _nameController.text,
          'description': _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
        };

        if (widget.folder != null) {
          await SupabaseService.client
              .from('pdf_folder')
              .update(folderData)
              .eq('id', widget.folder!['id']);
        } else {
          await SupabaseService.client.from('pdf_folder').insert(folderData);
        }

        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder berjaya disimpan!')),
        );
      } catch (e) {
        print('Ralat menyimpan folder: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat menyimpan folder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.folder != null ? 'Edit Folder' : 'Cipta Folder Baru'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Folder',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Sila masukkan nama folder' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Penerangan (opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        TextButton(
          onPressed: _saveFolder,
          child: Text('Simpan', style: TextStyle(color: const Color.fromARGB(255, 185, 211, 173))),
        ),
      ],
    );
  }
}