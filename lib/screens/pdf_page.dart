// teacher/lib/page/pdf_page.dart - TANPA SupabaseService
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/color.dart';
import 'dart:io';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (!mounted) return;
    
    try {
      setState(() => _isLoading = true);
      final String? parentFolderId = widget.folder?['id'];
      
      print('🔄 Memuat kandungan untuk folder: $parentFolderId');
      
      // Muat subfolder
      dynamic folderResponse;
      if (parentFolderId != null) {
        folderResponse = await Supabase.instance.client
            .from('pdf_folder')
            .select('*')
            .eq('parent_folder_id', parentFolderId)
            .order('created_at', ascending: false);
      } else {
        folderResponse = await Supabase.instance.client
            .from('pdf_folder')
            .select('*')
            .filter('parent_folder_id', 'is', 'null')
            .order('created_at', ascending: false);
      }

      // Muat PDF
      dynamic pdfResponse;
      if (parentFolderId != null) {
        pdfResponse = await Supabase.instance.client
            .from('teacher_pdf')
            .select('*')
            .eq('folder_id', parentFolderId)
            .order('created_at', ascending: false);
      } else {
        pdfResponse = await Supabase.instance.client
            .from('teacher_pdf')
            .select('*')
            .filter('folder_id', 'is', 'null')
            .order('created_at', ascending: false);
      }

      print('📁 Dimuat ${folderResponse.length} subfolder');
      print('📄 Dimuat ${pdfResponse.length} PDF');

      if (mounted) {
        setState(() {
          _folderList = List<Map<String, dynamic>>.from(folderResponse);
          _pdfList = List<Map<String, dynamic>>.from(pdfResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Ralat memuat kandungan: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat memuat kandungan: $e')),
        );
      }
    }
  }

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
                labelText: 'Nama Folder',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Penerangan (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text,
              'description': descController.text,
            }),
            child: Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await Supabase.instance.client
            .from('pdf_folder')
            .update({
              'name': result['name'],
              'description': result['description'].isEmpty ? null : result['description'],
            })
            .eq('id', folder['id']);

        await _loadContent();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Folder berjaya dikemaskini! ✅')),
          );
        }
      } catch (e) {
        print('Ralat mengemaskini folder: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ralat mengemaskini folder: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteFolder(Map<String, dynamic> folder) async {
    try {
      final hasSubfolders = await Supabase.instance.client
          .from('pdf_folder')
          .select('id')
          .eq('parent_folder_id', folder['id'])
          .limit(1);

      final hasPdfs = await Supabase.instance.client
          .from('teacher_pdf')
          .select('id')
          .eq('folder_id', folder['id'])
          .limit(1);

      bool hasContent = hasSubfolders.isNotEmpty || hasPdfs.isNotEmpty;

      if (hasContent) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Tidak Boleh Padam Folder'),
            content: Text('Folder ini mengandungi subfolder atau PDF. Sila padam semua kandungan dahulu.'),
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
      print('Ralat menyemak kandungan folder: $e');
    }

    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Padam Folder'),
        content: Text('Adakah anda pasti mahu memadam "${folder['name']}"?'),
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
    ) ?? false;

    if (confirm) {
      try {
        await Supabase.instance.client
            .from('pdf_folder')
            .delete()
            .eq('id', folder['id']);

        await _loadContent();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Folder berjaya dipadam! 🗑️')),
          );
        }
      } catch (e) {
        print('Ralat memadam folder: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ralat memadam folder: $e')),
          );
        }
      }
    }
  }

  Future<void> _editPdf(Map<String, dynamic> pdf) async {
    final titleController = TextEditingController(text: pdf['title']);
    
    String? newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Nama PDF'),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: 'Masukkan nama PDF baharu',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, titleController.text),
            child: Text('Simpan'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != pdf['title']) {
      try {
        await Supabase.instance.client
            .from('teacher_pdf')
            .update({'title': newTitle})
            .eq('id', pdf['id']);

        await _loadContent();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF berjaya dikemaskini! ✅')),
          );
        }
      } catch (e) {
        print('Ralat mengemaskini PDF: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ralat mengemaskini PDF: $e')),
          );
        }
      }
    }
  }

  Future<void> _deletePdf(Map<String, dynamic> pdf) async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Padam PDF'),
        content: Text('Adakah anda pasti mahu memadam "${pdf['title']}"? Tindakan ini tidak boleh dibatalkan.'),
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
    ) ?? false;

    if (confirm) {
      try {
        await Supabase.instance.client.storage
            .from('teacher-pdf')
            .remove([pdf['file_path']]);

        await Supabase.instance.client
            .from('teacher_pdf')
            .delete()
            .eq('id', pdf['id']);

        await _loadContent();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF berjaya dipadam! 🗑️')),
          );
        }
      } catch (e) {
        print('Ralat memadam PDF: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ralat memadam PDF: $e')),
          );
        }
      }
    }
  }

  Future<void> _downloadPdf(Map<String, dynamic> pdf) async {
    try {
      print('📥 GURU: Memuat turun fail: ${pdf['file_path']}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Memuat turun ${pdf['title']}...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final bytes = await Supabase.instance.client.storage
          .from('teacher-pdf')
          .download(pdf['file_path']);

      if (bytes.isEmpty) {
        throw 'Tiada data fail diterima';
      }

      if (kIsWeb) {
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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Muat turun bermula: ${pdf['file_name']}'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan PDF',
          fileName: pdf['file_name'],
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ PDF berjaya disimpan: ${pdf['file_name']}'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Muat turun dibatalkan')),
            );
          }
        }
      }
      
    } catch (e) {
      print('❌ GURU: Ralat muat turun: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Muat turun gagal: ${e.toString()}')),
        );
      }
    }
  }

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
            title: Text('Namakan PDF Anda'),
            content: TextField(
              controller: pdfNameController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama PDF',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: Text('Batal')
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, pdfNameController.text),
                child: Text('Muat Naik'),
              ),
            ],
          ),
        );

        if (pdfName != null && pdfName.isNotEmpty) {
          PlatformFile file = result.files.first;
          String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final fileBytes = file.bytes;
          
          if (fileBytes != null) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(
                child: CircularProgressIndicator(),
              ),
            );

            try {
              await Supabase.instance.client.storage
                  .from('teacher-pdf')
                  .uploadBinary(fileName, fileBytes);

              await Supabase.instance.client.from('teacher_pdf').insert({
                'title': pdfName,
                'file_name': file.name,
                'file_path': fileName,
                'folder_id': widget.folder?['id'],
              });

              if (mounted) {
                Navigator.pop(context);
                await _loadContent();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('PDF berjaya dimuat naik! 🎉')),
                );
              }
            } catch (uploadError) {
              if (mounted) Navigator.pop(context);
              rethrow;
            }
          }
        }
      }
    } catch (e) {
      print('Ralat muat naik: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Muat naik gagal: $e')),
        );
      }
    }
  }

  void _openFolder(Map<String, dynamic> folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPage(folder: folder),
      ),
    );
  }

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
              tooltip: 'Padam Folder',
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () => _openFolder(folder),
      ),
    );
  }

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
            Text('Dimuat naik: ${_formatDate(pdf['created_at'])}', 
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.download, color: TeacherColors.primaryGreen),
              onPressed: () => _downloadPdf(pdf),
              tooltip: 'Muat Turun PDF',
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editPdf(pdf),
              tooltip: 'Edit Nama PDF',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: TeacherColors.danger),
              onPressed: () => _deletePdf(pdf),
              tooltip: 'Padam PDF',
            ),
          ],
        ),
      ),
    );
  }

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
        title: Text(widget.folder != null ? widget.folder!['name'] : 'Semua PDF'),
        backgroundColor: TeacherColors.topBar,
        foregroundColor: TeacherColors.textDark,
        leading: widget.folder != null 
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadContent,
            tooltip: 'Segar Semula',
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
                          Text('Folder Kosong', style: TextStyle(fontSize: 18)),
                          Text('Tambah folder atau PDF untuk bermula', 
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        if (_folderList.isNotEmpty) ...[
                          Text(
                            widget.folder != null ? 'Subfolder' : 'Folder',
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
                        
                        if (_pdfList.isNotEmpty) ...[
                          Text(
                            'Fail PDF (${_pdfList.length})',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          ..._pdfList.map((pdf) => _buildPdfItem(pdf)),
                        ],
                        
                        SizedBox(height: 80),
                      ],
                    ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => CreateFolderDialog(
                  parentFolder: widget.folder,
                  onSave: _loadContent,
                ),
              );
            },
            child: Icon(Icons.create_new_folder),
            backgroundColor: Colors.amber,
            mini: true,
            heroTag: 'folder_btn',
            tooltip: widget.folder != null ? 'Cipta Subfolder' : 'Cipta Folder',
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _uploadPdf,
            child: Icon(Icons.add),
            backgroundColor: TeacherColors.primaryGreen,
            tooltip: 'Muat Naik PDF',
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

        await Supabase.instance.client.from('pdf_folder').insert(folderData);

        if (mounted) {
          Navigator.pop(context);
          widget.onSave();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Folder berjaya dicipta!')),
          );
        }
      } catch (e) {
        print('❌ Ralat mencipta folder: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ralat mencipta folder: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.parentFolder != null ? 'Cipta Subfolder' : 'Cipta Folder Baru'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.parentFolder != null) 
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Di dalam: ${widget.parentFolder!['name']}'),
            ),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama Folder *',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Penerangan (opsional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text('Batal')
        ),
        ElevatedButton(
          onPressed: _saveFolder, 
          child: Text('Cipta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherColors.primaryGreen,
          ),
        ),
      ],
    );
  }
}