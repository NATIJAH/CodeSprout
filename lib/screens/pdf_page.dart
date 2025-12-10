// teacher/lib/page/pdf_page.dart - COMPLETE WITH FULL CRUD
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../service/supabase_service.dart';
import '../theme/color.dart';
import 'dart:io'; // Add this for File class
import 'dart:html' as html; // Add this for web
import 'package:flutter/foundation.dart'; // Add this for kIsWeb

class PdfPage extends StatefulWidget {
  final Map<String, dynamic>? folder;
  const PdfPage({Key? key, this.folder}) : super(key: key);
  
  @override
  _PdfPageState createState() => _PdfPageState();
}

class _PdfPageState extends State<PdfPage> {
  List<Map<String, dynamic>> _folderList = [];
  List<Map<String, dynamic>> _pdfList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      setState(() => _isLoading = true);
      final String? parentFolderId = widget.folder?['id'];
      
      print('🔄 Loading content for folder: $parentFolderId');
      
      // Load subfolders
      dynamic folderResponse;
      if (parentFolderId != null) {
        folderResponse = await SupabaseService.client
            .from('pdf_folder')
            .select('*')
            .eq('parent_folder_id', parentFolderId)
            .order('created_at', ascending: false);
      } else {
        folderResponse = await SupabaseService.client
            .from('pdf_folder')
            .select('*')
            .filter('parent_folder_id', 'is', 'null')
            .order('created_at', ascending: false);
      }

      // Load PDFs
      dynamic pdfResponse;
      if (parentFolderId != null) {
        pdfResponse = await SupabaseService.client
            .from('teacher_pdf')
            .select('*')
            .eq('folder_id', parentFolderId)
            .order('created_at', ascending: false);
      } else {
        pdfResponse = await SupabaseService.client
            .from('teacher_pdf')
            .select('*')
            .filter('folder_id', 'is', 'null')
            .order('created_at', ascending: false);
      }

      print('📁 Loaded ${folderResponse.length} subfolders');
      print('📄 Loaded ${pdfResponse.length} PDFs');

      setState(() {
        _folderList = List<Map<String, dynamic>>.from(folderResponse);
        _pdfList = List<Map<String, dynamic>>.from(pdfResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading content: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading content: $e')),
      );
    }
  }

  // EDIT FOLDER
  Future<void> _editFolder(Map<String, dynamic> folder) async {
    final nameController = TextEditingController(text: folder['name']);
    final descController = TextEditingController(text: folder['description'] ?? '');
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Folder Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text,
              'description': descController.text,
            }),
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await SupabaseService.client
            .from('pdf_folder')
            .update({
              'name': result['name'],
              'description': result['description'].isEmpty ? null : result['description'],
            })
            .eq('id', folder['id']);

        await _loadContent();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder updated successfully! ✅')),
        );
      } catch (e) {
        print('Error updating folder: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating folder: $e')),
        );
      }
    }
  }

  // DELETE FOLDER
  Future<void> _deleteFolder(Map<String, dynamic> folder) async {
    // Check if folder has content
    try {
      final hasSubfolders = await SupabaseService.client
          .from('pdf_folder')
          .select('id')
          .eq('parent_folder_id', folder['id'])
          .limit(1);

      final hasPdfs = await SupabaseService.client
          .from('teacher_pdf')
          .select('id')
          .eq('folder_id', folder['id'])
          .limit(1);

      bool hasContent = hasSubfolders.isNotEmpty || hasPdfs.isNotEmpty;

      if (hasContent) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Cannot Delete Folder'),
            content: Text('This folder contains subfolders or PDFs. Please delete all contents first.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    } catch (e) {
      print('Error checking folder content: $e');
    }

    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Folder'),
        content: Text('Are you sure you want to delete "${folder['name']}"?'),
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
      try {
        await SupabaseService.client
            .from('pdf_folder')
            .delete()
            .eq('id', folder['id']);

        await _loadContent();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder deleted successfully! 🗑️')),
        );
      } catch (e) {
        print('Error deleting folder: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting folder: $e')),
        );
      }
    }
  }

  // EDIT PDF
  Future<void> _editPdf(Map<String, dynamic> pdf) async {
    final titleController = TextEditingController(text: pdf['title']);
    
    String? newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit PDF Name'),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: 'Enter new PDF name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, titleController.text),
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != pdf['title']) {
      try {
        await SupabaseService.client
            .from('teacher_pdf')
            .update({'title': newTitle})
            .eq('id', pdf['id']);

        await _loadContent();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF updated successfully! ✅')),
        );
      } catch (e) {
        print('Error updating PDF: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating PDF: $e')),
        );
      }
    }
  }

  // DELETE PDF
  Future<void> _deletePdf(Map<String, dynamic> pdf) async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete PDF'),
        content: Text('Are you sure you want to delete "${pdf['title']}"? This action cannot be undone.'),
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
      try {
        // Delete from storage first
        await SupabaseService.client.storage
            .from('teacher-pdf')
            .remove([pdf['file_path']]);

        // Then delete from database
        await SupabaseService.client
            .from('teacher_pdf')
            .delete()
            .eq('id', pdf['id']);

        await _loadContent();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF deleted successfully! 🗑️')),
        );
      } catch (e) {
        print('Error deleting PDF: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting PDF: $e')),
        );
      }
    }
  }

  // DOWNLOAD PDF
// DOWNLOAD PDF
Future<void> _downloadPdf(Map<String, dynamic> pdf) async {
  try {
    print('📥 TEACHER: Downloading file: ${pdf['file_path']}');

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${pdf['title']}...'),
        duration: Duration(seconds: 2),
      ),
    );

    // Download from Supabase storage
    final bytes = await SupabaseService.client.storage
        .from('teacher-pdf')
        .download(pdf['file_path']);

    if (bytes == null) {
      throw 'No file bytes received';
    }

    // Different handling for web vs mobile
    if (kIsWeb) {
      // For web: Create download link and trigger click
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = pdf['file_name'];
      
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Download started: ${pdf['file_name']}'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // For mobile: Use FilePicker to save
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: pdf['file_name'],
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        // Save the file locally
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF saved successfully: ${pdf['file_name']}'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download cancelled')),
        );
      }
    }
    
  } catch (e) {
    print('❌ TEACHER: Download error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download failed: ${e.toString()}')),
    );
  }
}

  // UPLOAD PDF
  Future<void> _uploadPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pdfNameController = TextEditingController();
        
        String? pdfName = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Name your PDF'),
            content: TextField(
              controller: pdfNameController,
              decoration: InputDecoration(
                hintText: 'Enter PDF name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: Text('Cancel')
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, pdfNameController.text),
                child: Text('Upload'),
              ),
            ],
          ),
        );

        if (pdfName != null && pdfName.isNotEmpty) {
          PlatformFile file = result.files.first;
          String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final fileBytes = file.bytes;
          
          if (fileBytes != null) {
            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(
                child: CircularProgressIndicator(),
              ),
            );

            try {
              await SupabaseService.client.storage
                  .from('teacher-pdf')
                  .uploadBinary(fileName, fileBytes);

              await SupabaseService.client.from('teacher_pdf').insert({
                'title': pdfName,
                'file_name': file.name,
                'file_path': fileName,
                'folder_id': widget.folder?['id'],
              });

              Navigator.pop(context); // Close loading dialog
              await _loadContent();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PDF uploaded successfully! 🎉')),
              );
            } catch (uploadError) {
              Navigator.pop(context); // Close loading dialog
              rethrow;
            }
          }
        }
      }
    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  // CREATE SUBFOLDER
  Future<void> _createSubfolder() async {
    await showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(
        parentFolder: widget.folder,
        onSave: _loadContent,
      ),
    );
  }

  void _openFolder(Map<String, dynamic> folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPage(folder: folder),
      ),
    );
  }

  void _goBack() {
    Navigator.pop(context);
  }

  // BUILD FOLDER ITEM
  Widget _buildFolderItem(Map<String, dynamic> folder) {
    return Card(
      color: TeacherColors.card,
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(Icons.folder, color: Colors.amber, size: 32),
        title: Text(folder['name'], style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: folder['description'] != null ? Text(folder['description']!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => _editFolder(folder),
              tooltip: 'Edit Folder',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: TeacherColors.danger, size: 20),
              onPressed: () => _deleteFolder(folder),
              tooltip: 'Delete Folder',
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () => _openFolder(folder),
      ),
    );
  }

  // BUILD PDF ITEM
  Widget _buildPdfItem(Map<String, dynamic> pdf) {
    return Card(
      color: TeacherColors.card,
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
        title: Text(pdf['title'], style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pdf['file_name']),
            Text('Uploaded: ${_formatDate(pdf['created_at'])}', 
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.download, color: TeacherColors.primaryGreen),
              onPressed: () => _downloadPdf(pdf),
              tooltip: 'Download PDF',
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editPdf(pdf),
              tooltip: 'Edit PDF Name',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: TeacherColors.danger),
              onPressed: () => _deletePdf(pdf),
              tooltip: 'Delete PDF',
            ),
          ],
        ),
      ),
    );
  }

  // DATE FORMATTER
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: AppBar(
        title: Text(widget.folder != null ? widget.folder!['name'] : 'All PDFs'),
        backgroundColor: TeacherColors.topBar,
        foregroundColor: TeacherColors.textDark,
        leading: widget.folder != null 
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _goBack,
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadContent,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadContent,
              child: _folderList.isEmpty && _pdfList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Empty Folder', style: TextStyle(fontSize: 18)),
                          Text('Add folders or PDFs to get started', 
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        // Folders Section
                        if (_folderList.isNotEmpty) ...[
                          Text(
                            widget.folder != null ? 'Subfolders' : 'Folders',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          ..._folderList.map((folder) => _buildFolderItem(folder)),
                          SizedBox(height: 16),
                        ],
                        
                        // PDFs Section
                        if (_pdfList.isNotEmpty) ...[
                          Text(
                            'PDF Files (${_pdfList.length})',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          ..._pdfList.map((pdf) => _buildPdfItem(pdf)),
                        ],
                        
                        // Empty space at bottom
                        SizedBox(height: 80),
                      ],
                    ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.folder != null)
            FloatingActionButton(
              onPressed: _createSubfolder,
              child: Icon(Icons.create_new_folder),
              backgroundColor: Colors.amber,
              mini: true,
              heroTag: 'folder_btn',
              tooltip: 'Create Folder',
            ),
          SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _uploadPdf,
            child: Icon(Icons.add),
            backgroundColor: TeacherColors.primaryGreen,
            tooltip: 'Upload PDF',
            heroTag: 'pdf_btn',
          ),
        ],
      ),
    );
  }
}

class CreateFolderDialog extends StatefulWidget {
  final Map<String, dynamic>? parentFolder;
  final Function onSave;
  const CreateFolderDialog({Key? key, this.parentFolder, required this.onSave}) : super(key: key);
  
  @override
  _CreateFolderDialogState createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  Future<void> _saveFolder() async {
    if (_nameController.text.isNotEmpty) {
      try {
        final folderData = {
          'name': _nameController.text,
          'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        };

        if (widget.parentFolder?['id'] != null) {
          folderData['parent_folder_id'] = widget.parentFolder!['id'];
        }

        await SupabaseService.client.from('pdf_folder').insert(folderData);

        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder created successfully!')),
        );
      } catch (e) {
        print('❌ Error creating folder: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating folder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.parentFolder != null ? 'Create Subfolder' : 'Create New Folder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.parentFolder != null) 
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Inside: ${widget.parentFolder!['name']}'),
            ),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Folder Name *',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text('Cancel')
        ),
        ElevatedButton(
          onPressed: _saveFolder, 
          child: Text('Create'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherColors.primaryGreen,
          ),
        ),
      ],
    );
  }
}