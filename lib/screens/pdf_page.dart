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
  bool _isUploading = false;

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
        _showErrorSnackbar('Ralat memuat kandungan. Sila cuba lagi.');
      }
    }
  }

  // Fungsi untuk menunjukkan mesej ralat
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: TeacherColors.danger,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Fungsi untuk menunjukkan mesej kejayaan
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: TeacherColors.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
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
                labelText: 'Nama Folder *',
                border: OutlineInputBorder(),
                errorText: nameController.text.isEmpty ? 'Nama folder diperlukan' : null,
              ),
              autofocus: true,
              onChanged: (value) {
                // Refresh UI untuk validation
                (context as Element).markNeedsBuild();
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Penerangan (pilihan)',
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
          ElevatedButton(
            onPressed: nameController.text.isEmpty ? null : () {
              if (nameController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'description': descController.text.trim(),
              });
            },
            child: Text('Simpan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherColors.primaryGreen,
            ),
          ),
        ],
      ),
    );

    if (result != null && result['name']!.isNotEmpty) {
      try {
        await Supabase.instance.client
            .from('pdf_folder')
            .update({
              'name': result['name'],
              'description': result['description']!.isEmpty ? null : result['description'],
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', folder['id']);

        await _loadContent();
        _showSuccessSnackbar('Folder berjaya dikemaskini! ✅');
      } catch (e) {
        print('Ralat mengemaskini folder: $e');
        _showErrorSnackbar('Ralat mengemaskini folder. Sila cuba lagi.');
      }
    }
  }

  Future<void> _deleteFolder(Map<String, dynamic> folder) async {
    bool hasContent = false;
    String contentType = '';
    
    try {
      // Periksa sama ada folder mempunyai subfolder
      final subfolders = await Supabase.instance.client
          .from('pdf_folder')
          .select('id, name')
          .eq('parent_folder_id', folder['id'])
          .limit(1);

      // Periksa sama ada folder mempunyai PDF
      final pdfs = await Supabase.instance.client
          .from('teacher_pdf')
          .select('id, title')
          .eq('folder_id', folder['id'])
          .limit(1);

      if (subfolders.isNotEmpty) {
        hasContent = true;
        contentType = 'subfolder';
      } else if (pdfs.isNotEmpty) {
        hasContent = true;
        contentType = 'PDF';
      }
    } catch (e) {
      print('Ralat menyemak kandungan folder: $e');
      _showErrorSnackbar('Ralat menyemak kandungan folder. Sila cuba lagi.');
      return;
    }

    if (hasContent) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('⚠️ Tidak Boleh Padam Folder'),
          content: Text(
            'Folder "${folder['name']}" mengandungi $contentType.\n'
            'Sila padam semua kandungan dalam folder ini terlebih dahulu.',
          ),
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

    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Padam Folder'),
        icon: Icon(Icons.warning, color: Colors.orange),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adakah anda pasti mahu memadam folder ini?'),
            SizedBox(height: 8),
            Text(
              '"${folder['name']}"',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tindakan ini tidak boleh dibatalkan.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Padam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherColors.danger,
            ),
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
        _showSuccessSnackbar('Folder berjaya dipadam! 🗑️');
      } catch (e) {
        print('Ralat memadam folder: $e');
        _showErrorSnackbar('Ralat memadam folder. Sila cuba lagi.');
      }
    }
  }

  Future<void> _editPdf(Map<String, dynamic> pdf) async {
    final titleController = TextEditingController(text: pdf['title']);
    
    String? newTitle = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Nama PDF'),
            content: TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama PDF baharu',
                border: OutlineInputBorder(),
                errorText: titleController.text.isEmpty ? 'Nama PDF diperlukan' : null,
              ),
              autofocus: true,
              onChanged: (value) {
                setState(() {});
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: titleController.text.isEmpty ? null : () {
                  if (titleController.text.trim().isEmpty) {
                    return;
                  }
                  Navigator.pop(context, titleController.text.trim());
                },
                child: Text('Simpan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherColors.primaryGreen,
                ),
              ),
            ],
          );
        },
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != pdf['title']) {
      try {
        await Supabase.instance.client
            .from('teacher_pdf')
            .update({
              'title': newTitle,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', pdf['id']);

        await _loadContent();
        _showSuccessSnackbar('PDF berjaya dikemaskini! ✅');
      } catch (e) {
        print('Ralat mengemaskini PDF: $e');
        _showErrorSnackbar('Ralat mengemaskini PDF. Sila cuba lagi.');
      }
    }
  }

  Future<void> _deletePdf(Map<String, dynamic> pdf) async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Padam PDF'),
        icon: Icon(Icons.warning, color: Colors.orange),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adakah anda pasti mahu memadam PDF ini?'),
            SizedBox(height: 8),
            Text(
              '"${pdf['title']}"',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fail: ${pdf['file_name']}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tindakan ini akan memadam fail secara kekal dan tidak boleh dibatalkan.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Padam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherColors.danger,
            ),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        // Padam fail dari storage
        await Supabase.instance.client.storage
            .from('teacher-pdf')
            .remove([pdf['file_path']]);

        // Padam rekod dari database
        await Supabase.instance.client
            .from('teacher_pdf')
            .delete()
            .eq('id', pdf['id']);

        await _loadContent();
        _showSuccessSnackbar('PDF berjaya dipadam! 🗑️');
      } catch (e) {
        print('Ralat memadam PDF: $e');
        _showErrorSnackbar('Ralat memadam PDF. Sila cuba lagi.');
      }
    }
  }

  Future<void> _downloadPdf(Map<String, dynamic> pdf) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menyediakan muat turun ${pdf['title']}...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final bytes = await Supabase.instance.client.storage
          .from('teacher-pdf')
          .download(pdf['file_path']);

      if (bytes.isEmpty) {
        throw 'Fail kosong atau tidak ditemui';
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
          _showSuccessSnackbar('Muat turun bermula: ${pdf['file_name']}');
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
            _showSuccessSnackbar('PDF berjaya disimpan: ${pdf['file_name']}');
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
      print('❌ Ralat muat turun: $e');
      if (mounted) {
        _showErrorSnackbar('Muat turun gagal: ${e.toString()}');
      }
    }
  }

  Future<void> _uploadPdf() async {
    if (_isUploading) return;
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      
      // Validasi saiz fail (maksimum 10MB)
      if (file.size > 10 * 1024 * 1024) {
        _showErrorSnackbar('Saiz fail terlalu besar. Maksimum 10MB sahaja.');
        return;
      }

      // Validasi jenis fail
      if (!file.name.toLowerCase().endsWith('.pdf')) {
        _showErrorSnackbar('Hanya fail PDF sahaja dibenarkan.');
        return;
      }

      final pdfNameController = TextEditingController(text: file.name.replaceFirst('.pdf', ''));
      
      String? pdfName = await showDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Namakan PDF Anda'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fail: ${file.name}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: pdfNameController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama PDF',
                      border: OutlineInputBorder(),
                      errorText: pdfNameController.text.isEmpty ? 'Nama PDF diperlukan' : null,
                      suffixIcon: pdfNameController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 16),
                              onPressed: () {
                                pdfNameController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: Text('Batal')
                ),
                ElevatedButton(
                  onPressed: pdfNameController.text.isEmpty ? null : () {
                    if (pdfNameController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(context, pdfNameController.text.trim());
                  },
                  child: Text('Muat Naik'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeacherColors.primaryGreen,
                  ),
                ),
              ],
            );
          },
        ),
      );

      if (pdfName != null && pdfName.isNotEmpty) {
        setState(() => _isUploading = true);
        
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
        final fileBytes = file.bytes;
        
        if (fileBytes == null) {
          setState(() => _isUploading = false);
          _showErrorSnackbar('Ralat membaca fail. Sila cuba lagi.');
          return;
        }

        // Tunjukkan dialog loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Memuat Naik PDF...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Sila tunggu sebentar...'),
              ],
            ),
          ),
        );

        try {
          // Muat naik ke storage
          await Supabase.instance.client.storage
              .from('teacher-pdf')
              .uploadBinary(fileName, fileBytes, fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: false,
              ));

          // Simpan rekod ke database
          await Supabase.instance.client.from('teacher_pdf').insert({
            'title': pdfName,
            'file_name': file.name,
            'file_path': fileName,
            'folder_id': widget.folder?['id'],
            'file_size': file.size,
            'created_at': DateTime.now().toIso8601String(),
          });

          // Tutup dialog loading
          if (mounted) Navigator.pop(context);
          
          setState(() => _isUploading = false);
          await _loadContent();
          
          _showSuccessSnackbar('PDF berjaya dimuat naik! 🎉');
        } catch (uploadError) {
          if (mounted) Navigator.pop(context);
          setState(() => _isUploading = false);
          
          print('Ralat muat naik: $uploadError');
          _showErrorSnackbar('Muat naik gagal: ${uploadError.toString()}');
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      print('Ralat memilih fail: $e');
      _showErrorSnackbar('Ralat memilih fail. Sila cuba lagi.');
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
        title: Text(
          folder['name'],
          style: TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: folder['description'] != null 
            ? Text(
                folder['description']!,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              )
            : null,
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
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
        onTap: () => _openFolder(folder),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildPdfItem(Map<String, dynamic> pdf) {
    String fileSize = '';
    if (pdf['file_size'] != null) {
      final sizeInMB = pdf['file_size'] / (1024 * 1024);
      fileSize = sizeInMB.toStringAsFixed(2) + ' MB';
    }
    
    return Card(
      color: TeacherColors.card,
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
        title: Text(
          pdf['title'],
          style: TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pdf['file_name'],
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (fileSize.isNotEmpty)
              Text(
                'Saiz: $fileSize',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            Text(
              'Dimuat naik: ${_formatDate(pdf['created_at'])}',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.download, color: TeacherColors.primaryGreen, size: 20),
              onPressed: () => _downloadPdf(pdf),
              tooltip: 'Muat Turun PDF',
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => _editPdf(pdf),
              tooltip: 'Edit Nama PDF',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: TeacherColors.danger, size: 20),
              onPressed: () => _deletePdf(pdf),
              tooltip: 'Padam PDF',
            ),
          ],
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.folder != null ? Icons.folder_open : Icons.folder,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            widget.folder != null ? 'Subfolder Kosong' : 'Tiada Folder',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.folder != null 
                ? 'Cipta subfolder atau muat naik PDF ke dalam folder ini'
                : 'Cipta folder pertama anda atau muat naik PDF',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => CreateFolderDialog(
                  parentFolder: widget.folder,
                  onSave: _loadContent,
                ),
              );
            },
            icon: Icon(Icons.create_new_folder),
            label: Text(widget.folder != null ? 'Cipta Subfolder' : 'Cipta Folder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _uploadPdf,
            icon: Icon(Icons.upload_file),
            label: Text('Muat Naik PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: AppBar(
        title: Text(
          widget.folder != null 
              ? '📁 ${widget.folder!['name']}'
              : '📚 Semua PDF',
        ),
        backgroundColor: TeacherColors.topBar,
        foregroundColor: TeacherColors.textDark,
        leading: widget.folder != null 
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Kembali',
              )
            : null,
        actions: [
          if (_isUploading)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadContent,
            tooltip: 'Segar Semula',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuatkan kandungan...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadContent,
              child: _folderList.isEmpty && _pdfList.isEmpty
                  ? SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: _buildEmptyState(),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        if (_folderList.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.only(bottom: 8, left: 4),
                            child: Row(
                              children: [
                                Icon(Icons.folder, size: 20, color: Colors.amber),
                                SizedBox(width: 8),
                                Text(
                                  widget.folder != null ? 'Subfolder' : 'Folder',
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Chip(
                                  label: Text(_folderList.length.toString()),
                                  backgroundColor: Colors.amber[100],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          ..._folderList.map((folder) => _buildFolderItem(folder)),
                          SizedBox(height: 24),
                        ],
                        
                        if (_pdfList.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.only(bottom: 8, left: 4),
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Fail PDF',
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Chip(
                                  label: Text(_pdfList.length.toString()),
                                  backgroundColor: Colors.red[100],
                                ),
                              ],
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
            onPressed: _isUploading ? null : () {
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
          SizedBox(height: 12),
          FloatingActionButton(
            onPressed: _isUploading ? null : _uploadPdf,
            child: _isUploading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.add),
            backgroundColor: _isUploading ? Colors.grey : TeacherColors.primaryGreen,
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
  bool _isSaving = false;

  String? _validateName(String value) {
    if (value.trim().isEmpty) {
      return 'Nama folder diperlukan';
    }
    if (value.trim().length < 2) {
      return 'Nama folder perlu sekurang-kurangnya 2 aksara';
    }
    if (value.trim().length > 50) {
      return 'Nama folder terlalu panjang (maksimum 50 aksara)';
    }
    return null;
  }

  Future<void> _saveFolder() async {
    if (_isSaving) return;
    
    final name = _nameController.text.trim();
    final validationError = _validateName(name);
    
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: TeacherColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final folderData = {
        'name': name,
        'description': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      if (widget.parentFolder?['id'] != null) {
        folderData['parent_folder_id'] = widget.parentFolder!['id'];
      }

      await Supabase.instance.client.from('pdf_folder').insert(folderData);

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Folder berjaya dicipta! 🎉'),
            backgroundColor: TeacherColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      print('❌ Ralat mencipta folder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat mencipta folder: ${e.toString()}'),
            backgroundColor: TeacherColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.parentFolder != null ? 'Cipta Subfolder' : 'Cipta Folder Baru',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.parentFolder != null) 
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Di dalam: ${widget.parentFolder!['name']}',
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama Folder *',
              border: OutlineInputBorder(),
              hintText: 'Contoh: Nota Matematik',
              errorText: _validateName(_nameController.text),
              prefixIcon: Icon(Icons.folder),
            ),
            autofocus: true,
            maxLength: 50,
            onChanged: (value) {
              setState(() {});
            },
          ),
          SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Penerangan (pilihan)',
              border: OutlineInputBorder(),
              hintText: 'Contoh: Nota untuk bab 1-3',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 2,
            maxLength: 100,
          ),
          SizedBox(height: 8),
          Text(
            '* Wajib diisi',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context), 
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveFolder,
          child: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Cipta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherColors.primaryGreen,
          ),
        ),
      ],
    );
  }
}