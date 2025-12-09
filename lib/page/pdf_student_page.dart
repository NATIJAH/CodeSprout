import 'package:flutter/material.dart';
import '../service/supabase_service.dart';
import '../theme/color.dart';

class PdfStudentPage extends StatefulWidget {
  @override
  _PdfStudentPageState createState() => _PdfStudentPageState();
}

class _PdfStudentPageState extends State<PdfStudentPage> {
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

  void _openFolder(Map<String, dynamic> folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderPdfsPage(folder: folder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text('Learning Materials'),
        backgroundColor: AppColor.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _folderList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No learning materials',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColor.textLight,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your teacher will add materials here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFolders,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _folderList.length,
                    itemBuilder: (context, index) {
                      final folder = _folderList[index];
                      return _buildFolderCard(folder);
                    },
                  ),
                ),
    );
  }

  Widget _buildFolderCard(Map<String, dynamic> folder) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColor.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.folder,
            color: AppColor.primaryBlue,
            size: 28,
          ),
        ),
        title: Text(
          folder['name'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColor.textDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (folder['description'] != null)
              Text(
                folder['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.textLight,
                ),
              ),
            SizedBox(height: 4),
            Text(
              'Tap to view materials →',
              style: TextStyle(
                fontSize: 12,
                color: AppColor.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColor.primaryBlue,
        ),
        onTap: () => _openFolder(folder),
      ),
    );
  }
}

class FolderPdfsPage extends StatefulWidget {
  final Map<String, dynamic> folder;

  const FolderPdfsPage({required this.folder});

  @override
  _FolderPdfsPageState createState() => _FolderPdfsPageState();
}

class _FolderPdfsPageState extends State<FolderPdfsPage> {
  List<Map<String, dynamic>> _pdfList = [];
  Map<String, dynamic> _progressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load PDFs for this folder
      final pdfResponse = await SupabaseService.client
          .from('teacher_pdf')
          .select('*')
          .eq('folder_id', widget.folder['id'])
          .order('created_at', ascending: true);

      // Load progress for current user
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final progressResponse = await SupabaseService.client
            .from('student_pdf_progress')
            .select('*')
            .eq('student_id', user.id);

        // Convert progress list to map for easy lookup
        for (var progress in progressResponse) {
          _progressMap[progress['pdf_id']] = progress;
        }
      }

      setState(() {
        _pdfList = List<Map<String, dynamic>>.from(pdfResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading PDFs: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsViewed(String pdfId) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;

      await SupabaseService.client.from('student_pdf_progress').upsert({
        'student_id': user.id,
        'pdf_id': pdfId,
        'viewed': true,
        'last_viewed': DateTime.now().toIso8601String(),
      });

      // Update local state
      setState(() {
        _progressMap[pdfId] = {
          'viewed': true,
          'last_viewed': DateTime.now().toIso8601String(),
        };
      });
    } catch (e) {
      print('Error marking as viewed: $e');
    }
  }

  void _openPdf(Map<String, dynamic> pdf) {
    _markAsViewed(pdf['id']);
    
    // TODO: Replace with actual PDF viewer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pdf['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('PDF Viewer'),
            SizedBox(height: 8),
            Text(
              'Title: ${pdf['title']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (pdf['description'] != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Description: ${pdf['description']}'),
              ),
            SizedBox(height: 16),
            Text(
              'In a real app, this would open a PDF viewer',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              print('Opening PDF: ${pdf['title']}');
              Navigator.pop(context);
              // TODO: Add actual PDF viewer like:
              // Navigator.push(context, MaterialPageRoute(
              //   builder: (context) => PdfViewerPage(pdfUrl: pdf['file_url'])
              // ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primaryBlue,
            ),
            child: Text('Open PDF', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(widget.folder['name']),
        backgroundColor: AppColor.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _pdfList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No materials in this folder',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your teacher will add materials here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _pdfList.length,
                    itemBuilder: (context, index) {
                      final pdf = _pdfList[index];
                      final isViewed = _progressMap.containsKey(pdf['id']) &&
                          _progressMap[pdf['id']]['viewed'] == true;
                      return _buildPdfCard(pdf, isViewed);
                    },
                  ),
                ),
    );
  }

  Widget _buildPdfCard(Map<String, dynamic> pdf, bool isViewed) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isViewed
                ? AppColor.success.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.picture_as_pdf,
            color: isViewed ? AppColor.success : Colors.red,
            size: 28,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                pdf['title'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textDark,
                ),
              ),
            ),
            if (isViewed)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColor.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 12, color: AppColor.success),
                    SizedBox(width: 4),
                    Text(
                      'Viewed',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColor.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pdf['description'] != null)
              Text(
                pdf['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.textLight,
                ),
              ),
            SizedBox(height: 4),
            Text(
              'Tap to open →',
              style: TextStyle(
                fontSize: 12,
                color: AppColor.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.open_in_new,
          color: AppColor.primaryBlue,
        ),
        onTap: () => _openPdf(pdf),
      ),
    );
  }
}