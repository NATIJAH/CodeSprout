// teacher/lib/page/pdf_folder_page.dart
import 'package:flutter/material.dart';
import 'package:teacher/service/supabase_service.dart';
import 'package:teacher/theme/color.dart';
import 'pdf_page.dart'; // IMPORT PDF PAGE

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
    print('Error loading folders: $e');
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
          title: Text('Delete Folder'),
          content: Text('Are you sure you want to delete this folder and all its PDFs?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;

      if (confirm) {
        // Delete PDFs in this folder first
        await SupabaseService.client
            .from('teacher_pdf')
            .delete()
            .eq('folder_id', id);

        // Then delete the folder
        await SupabaseService.client
            .from('pdf_folder')
            .delete()
            .eq('id', id);

        _loadFolders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder deleted successfully!')),
        );
      }
    } catch (e) {
      print('Error deleting folder: $e');
    }
  }

  void _openFolder(Map<String, dynamic> folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPage(folder: folder), // OPEN PDF PAGE WITH FOLDER
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _folderList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No folders created yet', style: TextStyle(fontSize: 18)),
                      Text('Click the + button to create your first folder', 
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
                      color: AppColor.card,
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(Icons.folder, color: Colors.amber, size: 32),
                        title: Text(
                          folder['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (folder['description'] != null)
                              Text(folder['description']!),
                            Text('Tap to view PDFs'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: AppColor.primaryGreen),
                              onPressed: () => _editFolder(folder),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: AppColor.danger),
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
        backgroundColor: AppColor.primaryGreen,
        tooltip: 'Create Folder',
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
          'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        };

        if (widget.folder != null) {
          await SupabaseService.client
              .from('pdf_folder')
              .update(folderData)
              .eq('id', widget.folder!['id']);
        } else {
          await SupabaseService.client
              .from('pdf_folder')
              .insert(folderData);
        }

        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder saved successfully!')),
        );
      } catch (e) {
        print('Error saving folder: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving folder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.folder != null ? 'Edit Folder' : 'Create New Folder'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Folder Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Enter folder name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
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
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveFolder,
          child: Text('Save', style: TextStyle(color: AppColor.primaryGreen)),
        ),
      ],
    );
  }
}