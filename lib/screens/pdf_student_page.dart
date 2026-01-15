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
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Inisialisasi senarai kosong
    _folderList = [];
    _pdfList = [];
    
    // Muat data selepas UI dibina
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContent();
    });
  }

  // Fungsi untuk memaparkan mesej ralat mesra pengguna
  void _showErrorSnackbar(String message, {bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? StudentColors.success : Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Validasi data folder
  bool _validateFolderData(Map<String, dynamic> folder) {
    // Pastikan folder tidak null
    if (folder == null) return false;
    
    // Pastikan ada ID
    if (folder['id'] == null || folder['id'].toString().isEmpty) {
      print('❌ Folder tidak sah: Tiada ID');
      return false;
    }
    
    // Pastikan ada nama folder
    if (folder['name'] == null || folder['name'].toString().trim().isEmpty) {
      print('❌ Folder tidak sah: Tiada nama');
      return false;
    }
    
    // Validasi tarikh jika ada
    if (folder['created_at'] != null) {
      try {
        DateTime.parse(folder['created_at'].toString());
      } catch (e) {
        print('⚠️ Format tarikh folder tidak sah: ${folder['created_at']}');
      }
    }
    
    return true;
  }

  // Validasi data PDF
  bool _validatePdfData(Map<String, dynamic> pdf) {
    // Pastikan PDF tidak null
    if (pdf == null) return false;
    
    // Pastikan ada ID
    if (pdf['id'] == null || pdf['id'].toString().isEmpty) {
      print('❌ PDF tidak sah: Tiada ID');
      return false;
    }
    
    // Pastikan ada tajuk
    if (pdf['title'] == null || pdf['title'].toString().trim().isEmpty) {
      print('❌ PDF tidak sah: Tiada tajuk');
      return false;
    }
    
    // Pastikan ada nama fail
    if (pdf['file_name'] == null || pdf['file_name'].toString().trim().isEmpty) {
      print('❌ PDF tidak sah: Tiada nama fail');
      return false;
    }
    
    // Pastikan ada path fail
    if (pdf['file_path'] == null || pdf['file_path'].toString().trim().isEmpty) {
      print('❌ PDF tidak sah: Tiada path fail');
      return false;
    }
    
    // Validasi saiz fail jika ada
    if (pdf['file_size'] != null) {
      try {
        int.parse(pdf['file_size'].toString());
      } catch (e) {
        print('⚠️ Saiz fail PDF tidak sah: ${pdf['file_size']}');
      }
    }
    
    return true;
  }

  Future<void> _loadContent() async {
    if (!mounted) return;
    
    try {
      print('🚀 Pelajar: Mula memuat kandungan...');
      
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
      
      final String? parentFolderId = widget.currentFolder?['id'];
      print('📂 ID Folder Induk: $parentFolderId');
      
      List<Map<String, dynamic>> folderList = [];
      List<Map<String, dynamic>> pdfList = [];
      
      // VALIDASI SAMBUNGAN INTERNET
      try {
        await Supabase.instance.client.from('teacher_pdf').select('count').limit(1);
      } catch (e) {
        print('🌐 Ralat sambungan internet: $e');
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Tidak dapat menyambung ke pelayan. Sila semak sambungan internet anda.';
        });
        _showErrorSnackbar('⚠️ Tiada sambungan internet');
        return;
      }
      
      // MUAT FOLDER DENGAN VALIDASI
      try {
        print('📁 Memuat senarai folder...');
        
        dynamic folderResponse;
        final client = Supabase.instance.client;
        
        if (parentFolderId != null && parentFolderId.isNotEmpty) {
          folderResponse = await client
              .from('pdf_folder')
              .select('*')
              .eq('parent_folder_id', parentFolderId)
              .order('created_at', ascending: false)
              .timeout(Duration(seconds: 10));
        } else {
          folderResponse = await client
              .from('pdf_folder')
              .select('*')
              .is_('parent_folder_id', null)
              .order('created_at', ascending: false)
              .timeout(Duration(seconds: 10));
        }
        
        // VALIDASI RESPONS FOLDER
        if (folderResponse == null) {
          print('⚠️ Respons folder adalah null');
        } else if (folderResponse is List) {
          // Tapis dan validasi setiap folder
          for (var folder in folderResponse) {
            if (_validateFolderData(folder)) {
              folderList.add(folder);
            }
          }
          print('✅ Ditemui ${folderList.length} folder sah');
        } else {
          print('⚠️ Format respons folder tidak dijangka: ${folderResponse.runtimeType}');
        }
      } catch (e) {
        print('❌ Ralat memuat folder: $e');
        _showErrorSnackbar('⚠️ Gagal memuat senarai folder');
      }
      
      // MUAT PDF DENGAN VALIDASI
      try {
        print('📄 Memuat senarai PDF...');
        
        dynamic pdfResponse;
        final client = Supabase.instance.client;
        
        if (parentFolderId != null && parentFolderId.isNotEmpty) {
          pdfResponse = await client
              .from('teacher_pdf')
              .select('*')
              .eq('folder_id', parentFolderId)
              .order('created_at', ascending: false)
              .timeout(Duration(seconds: 10));
        } else {
          pdfResponse = await client
              .from('teacher_pdf')
              .select('*')
              .is_('folder_id', null)
              .order('created_at', ascending: false)
              .timeout(Duration(seconds: 10));
        }
        
        // VALIDASI RESPONS PDF
        if (pdfResponse == null) {
          print('⚠️ Respons PDF adalah null');
        } else if (pdfResponse is List) {
          // Tapis dan validasi setiap PDF
          for (var pdf in pdfResponse) {
            if (_validatePdfData(pdf)) {
              pdfList.add(pdf);
            }
          }
          print('✅ Ditemui ${pdfList.length} PDF sah');
        } else {
          print('⚠️ Format respons PDF tidak dijangka: ${pdfResponse.runtimeType}');
        }
      } catch (e) {
        print('❌ Ralat memuat PDF: $e');
        _showErrorSnackbar('⚠️ Gagal memuat senarai dokumen');
      }
      
      // PAPARKAN MAKLUMAT JUMLAH
      final totalItems = folderList.length + pdfList.length;
      print('🎯 Jumlah kandungan: $totalItems item (${folderList.length} folder, ${pdfList.length} PDF)');
      
      if (mounted) {
        setState(() {
          _folderList = folderList;
          _pdfList = pdfList;
          _isLoading = false;
          
          if (totalItems == 0) {
            _errorMessage = 'Tiada kandungan dalam folder ini.';
          }
        });
        
        // Paparkan mesej kejayaan jika ada kandungan
        if (totalItems > 0) {
          _showErrorSnackbar('✅ Dimuatkan $totalItems item', isSuccess: true);
        }
      }
      
    } catch (e) {
      print('💥 RALAT KRITIKAL dalam _loadContent: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Ralat sistem: ${e.toString().length > 50 ? e.toString().substring(0, 50) + '...' : e.toString()}';
        });
        
        _showErrorSnackbar('❌ Ralat sistem. Sila cuba lagi.');
      }
    }
  }

  void _openFolder(Map<String, dynamic> folder) {
    // Validasi sebelum navigasi
    if (!_validateFolderData(folder)) {
      _showErrorSnackbar('⚠️ Folder tidak sah. Tidak dapat dibuka.');
      return;
    }
    
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
    // Validasi data PDF sebelum muat turun
    if (!_validatePdfData(pdf)) {
      _showErrorSnackbar('❌ Dokumen tidak sah. Tidak boleh dimuat turun.');
      return;
    }
    
    final pdfTitle = pdf['title'] ?? 'Dokumen PDF';
    final fileName = pdf['file_name'] ?? 'dokumen.pdf';
    final filePath = pdf['file_path'];
    
    print('📥 Mula muat turun: $pdfTitle');
    
    try {
      // Tunjukkan mesej pemuatan
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Menyediakan "$pdfTitle"...',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            duration: Duration(seconds: 5),
            backgroundColor: StudentColors.success,
          ),
        );
      }
      
      // VALIDASI PATH FAIL
      if (filePath == null || filePath.toString().trim().isEmpty) {
        throw 'Path fail tidak ditemui';
      }
      
      // MUAT TURUN UNTUK WEB
      if (kIsWeb) {
        try {
          print('🌐 Muat turun untuk web: $filePath');
          
          // Dapatkan data fail
          final bytes = await Supabase.instance.client.storage
              .from('teacher-pdf')
              .download(filePath)
              .timeout(Duration(seconds: 30));
          
          // VALIDASI DATA FAIL
          if (bytes == null) {
            throw 'Tiada data diterima dari pelayan';
          }
          
          if (bytes.isEmpty) {
            throw 'Fail kosong (0 bait)';
          }
          
          // Dapatkan saiz fail dalam format mesra
          final fileSize = bytes.length;
          String sizeText;
          if (fileSize < 1024) {
            sizeText = '$fileSize B';
          } else if (fileSize < 1024 * 1024) {
            sizeText = '${(fileSize / 1024).toStringAsFixed(1)} KB';
          } else {
            sizeText = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
          }
          
          print('✅ Fail diterima: $sizeText');
          
          // Cipta fail untuk dimuat turun
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.document.createElement('a') as html.AnchorElement
            ..href = url
            ..style.display = 'none'
            ..download = fileName;
          
          html.document.body!.children.add(anchor);
          anchor.click();
          
          // Bersihkan
          Future.delayed(Duration(milliseconds: 100), () {
            html.document.body!.children.remove(anchor);
            html.Url.revokeObjectUrl(url);
          });
          
          // Tunjukkan mesej kejayaan
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _showErrorSnackbar('✅ "$pdfTitle" ($sizeText) sedang dimuat turun', isSuccess: true);
          }
          
        } catch (e) {
          print('❌ Ralat muat turun web: $e');
          throw 'Gagal memuat turun: ${e.toString()}';
        }
      } else {
        // UNTUK MUDAH ALIH - hanya tunjuk mesej
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showErrorSnackbar('📱 Sila gunakan versi web untuk muat turun', isSuccess: true);
        }
      }
      
    } catch (e) {
      print('❌ Ralat muat turun PDF: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        String errorMessage = 'Gagal memuat turun "$pdfTitle"';
        
        // Mesej ralat khusus berdasarkan jenis ralat
        if (e.toString().contains('timeout')) {
          errorMessage = 'Masa untuk muat turun tamat. Sila cuba lagi.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Sambungan internet terputus. Sila semak rangkaian anda.';
        } else if (e.toString().contains('not found')) {
          errorMessage = 'Fail tidak ditemui di pelayan.';
        }
        
        _showErrorSnackbar('❌ $errorMessage');
      }
    }
  }

  Widget _buildFolderCard(Map<String, dynamic> folder) {
    // Validasi data untuk paparan
    final folderName = folder['name']?.toString() ?? 'Folder Tanpa Nama';
    final description = folder['description']?.toString() ?? 'Klik untuk buka';
    final date = folder['created_at']?.toString() ?? '';
    
    String dateText = '';
    if (date.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(date);
        dateText = 'Dibuat: ${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
      } catch (e) {
        dateText = 'Tarikh tidak sah';
      }
    }
    
    return Card(
      elevation: 3,
      color: StudentColors.card,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.folder_open, color: Colors.amber, size: 28),
        ),
        title: Text(
          folderName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: StudentColors.textDark,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: TextStyle(
                color: StudentColors.textLight,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (dateText.isNotEmpty)
              Text(
                dateText,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: StudentColors.textLight),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _openFolder(folder),
      ),
    );
  }

  Widget _buildPdfCard(Map<String, dynamic> pdf) {
    // Validasi data untuk paparan
    final title = pdf['title']?.toString() ?? 'Dokumen Tanpa Tajuk';
    final fileName = pdf['file_name']?.toString() ?? 'file.pdf';
    final fileSize = pdf['file_size'];
    
    String sizeText = 'Saiz tidak diketahui';
    if (fileSize != null) {
      try {
        final size = int.tryParse(fileSize.toString()) ?? 0;
        if (size < 1024) {
          sizeText = '$size B';
        } else if (size < 1024 * 1024) {
          sizeText = '${(size / 1024).toStringAsFixed(1)} KB';
        } else {
          sizeText = '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
      } catch (e) {
        sizeText = 'Saiz tidak sah';
      }
    }
    
    return Card(
      elevation: 3,
      color: StudentColors.card,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: StudentColors.textDark,
            fontSize: 16,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fail: $fileName',
              style: TextStyle(
                color: StudentColors.textLight,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Saiz: $sizeText • Klik untuk muat turun',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: StudentColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.download, color: StudentColors.success, size: 20),
          ),
          onPressed: () => _downloadPdf(pdf),
          tooltip: 'Muat Turun $title',
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _downloadPdf(pdf),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            SizedBox(height: 20),
            Text(
              'Ralat Memuatkan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: StudentColors.success,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Cuba Lagi'),
                ],
              ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: _goBack,
              child: Text(
                'Kembali Ke Folder Sebelum',
                style: TextStyle(color: StudentColors.success),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 100,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              'Folder Kosong',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Tiada folder atau dokumen dalam folder ini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.currentFolder?['name'] != null 
                ? 'Folder: ${widget.currentFolder!['name']}'
                : 'Folder Utama',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: StudentColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Segar Semula'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadContent,
      color: StudentColors.success,
      backgroundColor: Colors.white,
      displacement: 40,
      strokeWidth: 3,
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 10),
          
          // PAPARAN FOLDER
          if (_folderList.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.folder, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Folder (${_folderList.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: StudentColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            ..._folderList.map((folder) => _buildFolderCard(folder)),
            SizedBox(height: 16),
          ],
          
          // PAPARAN PDF
          if (_pdfList.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Dokumen PDF (${_pdfList.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: StudentColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            ..._pdfList.map((pdf) => _buildPdfCard(pdf)),
          ],
          
          // RUANG KOSONG DI BAWAH
          SizedBox(height: 30),
          
          // MAKLUMAT STATISTIK
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Jumlah: ${_folderList.length} folder, ${_pdfList.length} dokumen',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          
          SizedBox(height: 50),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 240, 248, 235),
      appBar: AppBar(
        title: Text(
          widget.currentFolder?['name'] ?? '📚 Bahan Pembelajaran',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: StudentColors.success,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: widget.currentFolder != null 
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: _goBack,
                tooltip: 'Kembali',
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 22),
            onPressed: _loadContent,
            tooltip: 'Segar Semula Kandungan',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: StudentColors.success,
                      backgroundColor: Colors.green[50],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Memuatkan kandungan...',
                    style: TextStyle(
                      fontSize: 16,
                      color: StudentColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.currentFolder?['name'] ?? 'Folder Utama',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : _hasError
            ? _buildErrorView()
            : (_folderList.isEmpty && _pdfList.isEmpty)
              ? _buildEmptyView()
              : _buildContent(),
    );
  }
}