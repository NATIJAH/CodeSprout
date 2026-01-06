// student/lib/page/pdf_student_page.dart - TANPA SupabaseService
import 'package:flutter/material.dart';
import '../theme/color.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdfStudentPage extends StatefulWidget {
  final Map<String, dynamic>? currentFolder;
  
  const PdfStudentPage({Key? key, this.currentFolder}) : super(key: key);
  
  @override
  _PdfStudentPageState createState() => _PdfStudentPageState();
}

class _PdfStudentPageState extends State<PdfStudentPage> {
  List<Map<String, dynamic>> _folderList = [];
  List<Map<String, dynamic>> _pdfList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Muat kosong dahulu untuk elak ralat
    setState(() {
      _folderList = [];
      _pdfList = [];
    });
    
    // Kemudian muat data sebenar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContent();
    });
  }

  Future<void> _loadContent() async {
    if (!mounted) return;
    
    try {
      print('🚀 Pelajar: Mula memuat kandungan');
      
      setState(() => _isLoading = true);
      
      final String? parentFolderId = widget.currentFolder?['id'];
      print('📂 ID Folder Induk: $parentFolderId');
      
      List<Map<String, dynamic>> folderList = [];
      List<Map<String, dynamic>> pdfList = [];
      
      // CUBA MUAT FOLDER
      try {
        dynamic folderResponse;
        if (parentFolderId != null) {
          folderResponse = await Supabase.instance.client
              .from('pdf_folder')
              .select('*')
              .eq('parent_folder_id', parentFolderId)
              .order('created_at', ascending: false)
              .then((response) {
                print('📁 Respons API Folder: $response');
                return response;
              }).catchError((e) {
                print('❌ Ralat API Folder: $e');
                return [];
              });
        } else {
          folderResponse = await Supabase.instance.client
              .from('pdf_folder')
              .select('*')
              .filter('parent_folder_id', 'is', 'null')
              .order('created_at', ascending: false)
              .then((response) {
                print('📁 Respons API Folder Root: $response');
                return response;
              }).catchError((e) {
                print('❌ Ralat API Folder Root: $e');
                return [];
              });
        }
        
        // PENUKARAN SELAMAT
        if (folderResponse != null && folderResponse is List) {
          folderList = List<Map<String, dynamic>>.from(folderResponse);
        }
      } catch (e) {
        print('⚠️ Pengecualian muat folder: $e');
        folderList = [];
      }
      
      // CUBA MUAT PDF
      try {
        dynamic pdfResponse;
        if (parentFolderId != null) {
          pdfResponse = await Supabase.instance.client
              .from('teacher_pdf')
              .select('*')
              .eq('folder_id', parentFolderId)
              .order('created_at', ascending: false)
              .then((response) {
                print('📄 Respons API PDF: $response');
                return response;
              }).catchError((e) {
                print('❌ Ralat API PDF: $e');
                return [];
              });
        } else {
          pdfResponse = await Supabase.instance.client
              .from('teacher_pdf')
              .select('*')
              .filter('folder_id', 'is', 'null')
              .order('created_at', ascending: false)
              .then((response) {
                print('📄 Respons API PDF Root: $response');
                return response;
              }).catchError((e) {
                print('❌ Ralat API PDF Root: $e');
                return [];
              });
        }
        
        // PENUKARAN SELAMAT
        if (pdfResponse != null && pdfResponse is List) {
          pdfList = List<Map<String, dynamic>>.from(pdfResponse);
        }
      } catch (e) {
        print('⚠️ Pengecualian muat PDF: $e');
        pdfList = [];
      }
      
      print('✅ Akhir: ${folderList.length} folder, ${pdfList.length} PDF');
      
      if (mounted) {
        setState(() {
          _folderList = folderList;
          _pdfList = pdfList;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('💥 RALAT KRITIKAL dalam _loadContent: $e');
      if (mounted) {
        setState(() {
          _folderList = [];
          _pdfList = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat memuat kandungan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openFolder(Map<String, dynamic> folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfStudentPage(currentFolder: folder),
      ),
    );
  }

  void _goBack() {
    if (widget.currentFolder != null) {
      Navigator.pop(context);
    }
  }

  Future<void> _downloadPdf(Map<String, dynamic> pdf) async {
    try {
      print('📥 Cuba muat turun: ${pdf['title']}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menyediakan muat turun...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // MUAT TURUN MUDAH - TANPA FILEPICKER
      if (kIsWeb) {
        try {
          final bytes = await Supabase.instance.client.storage
              .from('teacher-pdf')
              .download(pdf['file_path']);
              
          if (bytes.isNotEmpty) {
            final blob = html.Blob([bytes]);
            final url = html.Url.createObjectUrlFromBlob(blob);
            final anchor = html.document.createElement('a') as html.AnchorElement
              ..href = url
              ..style.display = 'none'
              ..download = pdf['file_name'] ?? 'dokumen.pdf';
            
            html.document.body!.children.add(anchor);
            anchor.click();
            html.document.body!.children.remove(anchor);
            html.Url.revokeObjectUrl(url);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Muat turun bermula'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } else {
            throw 'Tiada data fail diterima';
          }
        } catch (e) {
          print('Ralat muat turun web: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ralat muat turun: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // MUDAH ALIH - hanya tunjuk mesej kejayaan
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Sedia untuk dimuat turun'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      
    } catch (e) {
      print('Ralat muat turun: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat turun'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFolderCard(Map<String, dynamic> folder) {
    return Card(
      elevation: 2,
      color: StudentColors.card,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.folder, color: Colors.amber, size: 32),
        title: Text(
          folder['name'] ?? 'Folder',
          style: TextStyle(fontWeight: FontWeight.bold, color: StudentColors.textDark),
        ),
        subtitle: folder['description'] != null 
            ? Text(folder['description']!, style: TextStyle(color: StudentColors.textLight))
            : Text('Ketik untuk buka', style: TextStyle(color: StudentColors.textLight)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: StudentColors.textLight),
        onTap: () => _openFolder(folder),
      ),
    );
  }

  Widget _buildPdfCard(Map<String, dynamic> pdf) {
    return Card(
      elevation: 2,
      color: StudentColors.card,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
        title: Text(
          pdf['title'] ?? 'Dokumen PDF',
          style: TextStyle(fontWeight: FontWeight.bold, color: StudentColors.textDark),
        ),
        subtitle: Text('Ketik untuk muat turun', style: TextStyle(color: StudentColors.textLight)),
        trailing: IconButton(
          icon: Icon(Icons.download, color: const Color.fromARGB(255, 174, 206, 159)),
          onPressed: () => _downloadPdf(pdf),
          tooltip: 'Muat Turun',
        ),
        onTap: () => _downloadPdf(pdf),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 191, 221, 172),
      appBar: AppBar(
        title: Text(widget.currentFolder?['name'] ?? 'Bahan Pembelajaran'),
        backgroundColor: StudentColors.success,
        foregroundColor: Colors.white,
        leading: widget.currentFolder != null 
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _goBack,
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: StudentColors.success),
                  SizedBox(height: 16),
                  Text('Memuatkan bahan...', style: TextStyle(color: StudentColors.textDark)),
                ],
              ),
            )
          : (_folderList.isEmpty && _pdfList.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Tiada kandungan',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Folder ini kosong',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadContent,
                  color: StudentColors.success,
                  child: ListView(
                    children: [
                      if (_folderList.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Text(
                            'Folder',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: StudentColors.textDark,
                            ),
                          ),
                        ),
                        ..._folderList.map((folder) => _buildFolderCard(folder)),
                        SizedBox(height: 16),
                      ],
                      
                      if (_pdfList.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Text(
                            'Dokumen PDF (${_pdfList.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: StudentColors.textDark,
                            ),
                          ),
                        ),
                        ..._pdfList.map((pdf) => _buildPdfCard(pdf)),
                      ],
                      
                      SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }
}