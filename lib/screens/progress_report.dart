// student/lib/page/progress_page.dart

import 'package:flutter/material.dart';
import '../service/supabase_service.dart';
import '../theme/color.dart';

class ProgressPage extends StatefulWidget {
  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  Map<String, dynamic> _progressData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;

      // Dapatkan percubaan MCQ
      final mcqResponse = await SupabaseService.client
          .from('student_mcq_attempts')
          .select('*, mcq_set!inner(title)')
          .eq('student_id', user.id)
          .order('submitted_at', ascending: false);

      // Dapatkan kemajuan PDF
      final pdfResponse = await SupabaseService.client
          .from('student_pdf_progress')
          .select('*, teacher_pdf!inner(title)')
          .eq('student_id', user.id)
          .eq('viewed', true)
          .order('last_viewed', ascending: false);

      // Dapatkan jumlah PDF - TELAH DIPERBETULKAN
      final totalPdfsResponse = await SupabaseService.client
          .from('teacher_pdf')
          .select()
          .then((response) => response.length);

      // Kira statistik
      int totalMcqAttempts = mcqResponse.length;
      
      int totalCorrect = 0;
      int totalQuestions = 0;
      
      for (var attempt in mcqResponse) {
        final correct = attempt['correct_answers'];
        final total = attempt['total_questions'];
        
        if (correct is int) totalCorrect += correct;
        if (total is int) totalQuestions += total;
      }
      
      double avgScore = totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0;

      int viewedPdfs = pdfResponse.length;
      int totalPdfs = totalPdfsResponse; // Sudah menjadi int
      double pdfCompletion = totalPdfs > 0 ? (viewedPdfs / totalPdfs * 100) : 0;

      setState(() {
        _progressData = {
          'mcq_attempts': mcqResponse,
          'pdf_progress': pdfResponse,
          'stats': {
            'total_attempts': totalMcqAttempts,
            'total_correct': totalCorrect,
            'total_questions': totalQuestions,
            'avg_score': avgScore,
            'viewed_pdfs': viewedPdfs,
            'total_pdfs': totalPdfs,
            'pdf_completion': pdfCompletion,
          },
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Ralat memuat kemajuan: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStatsCard() {
    final stats = _progressData['stats'] ?? {};
    return Card(
      elevation: 2,
      color: StudentColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Prestasi Keseluruhan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: StudentColors.textDark,
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                _buildStatItem(
                  'Ujian MCQ',
                  '${stats['total_attempts'] ?? 0}',
                  Icons.quiz,
                  StudentColors.success, // ✅ TUKAR KE HIJAU
                ),
                _buildStatItem(
                  'Purata Markah',
                  '${(stats['avg_score'] ?? 0).toStringAsFixed(1)}%',
                  Icons.assessment,
                  StudentColors.success, // ✅ TUKAR KE HIJAU
                ),
                _buildStatItem(
                  'Bahan Dibaca',
                  '${stats['viewed_pdfs'] ?? 0}/${stats['total_pdfs'] ?? 0}',
                  Icons.book,
                  StudentColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: StudentColors.textDark,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: StudentColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(String title, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: StudentColors.textDark,
                ),
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[200],
          color: color,
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildMcqHistory() {
    final attempts = _progressData['mcq_attempts'] ?? [];
    if (attempts.isEmpty) {
      return Card(
        color: StudentColors.card,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 50, color: Colors.grey),
                SizedBox(height: 10),
                Text(
                  'Tiada percubaan ujian lagi',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      color: StudentColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Percubaan Ujian Terkini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: StudentColors.textDark,
              ),
            ),
            SizedBox(height: 12),
            ...attempts.take(5).map((attempt) => _buildAttemptItem(attempt)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptItem(Map<String, dynamic> attempt) {
    final mcqSet = attempt['mcq_set'] ?? {};
    final score = attempt['score'] ?? 0;
    final total = attempt['total_questions'] ?? 1;
    final percentage = total > 0 ? (score / total * 100) : 0;
    final submittedAt = attempt['submitted_at'] != null
        ? DateTime.parse(attempt['submitted_at']).toLocal()
        : DateTime.now();

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getScoreColor(percentage).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.quiz,
              color: _getScoreColor(percentage),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mcqSet['title'] ?? 'Ujian Tidak Dikenali',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: StudentColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Markah: $score/$total',
                  style: TextStyle(
                    fontSize: 12,
                    color: StudentColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(percentage),
                ),
              ),
              SizedBox(height: 4),
              Text(
                _formatDate(submittedAt),
                style: TextStyle(
                  fontSize: 10,
                  color: StudentColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final pdfProgress = _progressData['pdf_progress'] ?? [];
    if (pdfProgress.isEmpty) {
      return Card(
        color: StudentColors.card,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history_toggle_off, size: 50, color: Colors.grey),
                SizedBox(height: 10),
                Text(
                  'Tiada aktiviti terkini',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      color: StudentColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bahan Dilihat Terkini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: StudentColors.textDark,
              ),
            ),
            SizedBox(height: 12),
            ...pdfProgress.take(5).map((progress) => _buildActivityItem(progress)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> progress) {
    final pdf = progress['teacher_pdf'] ?? {};
    final lastViewed = progress['last_viewed'] != null
        ? DateTime.parse(progress['last_viewed']).toLocal()
        : DateTime.now();

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: StudentColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.picture_as_pdf,
            color: StudentColors.success,
            size: 20,
          ),
        ),
        title: Text(
          pdf['title'] ?? 'Bahan Tidak Dikenali',
          style: TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          'Dilihat ${_timeAgo(lastViewed)}',
          style: TextStyle(fontSize: 12, color: StudentColors.textLight),
        ),
        trailing: Icon(Icons.check_circle, color: StudentColors.success, size: 16),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return StudentColors.success;
    if (percentage >= 60) return StudentColors.warning;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan lepas';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lepas';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lepas';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minit lepas';
    } else {
      return 'Baru sahaja';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: AppBar(
        title: Text('Kemajuan Saya'),
        backgroundColor: StudentColors.success, // ✅ TUKAR KE HIJAU
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: StudentColors.success)) // ✅ HIJAU
          : RefreshIndicator(
              onRefresh: _loadProgress,
              color: StudentColors.success, // ✅ HIJAU
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCard(),
                    SizedBox(height: 20),
                    _buildProgressChart(
                      'Prestasi MCQ',
                      (_progressData['stats']?['avg_score'] ?? 0).toDouble(),
                      StudentColors.success, // ✅ TUKAR KE HIJAU
                    ),
                    SizedBox(height: 16),
                    _buildProgressChart(
                      'Kemajuan Bahan',
                      (_progressData['stats']?['pdf_completion'] ?? 0).toDouble(),
                      StudentColors.success, // ✅ TUKAR KE HIJAU
                    ),
                    SizedBox(height: 24),
                    _buildMcqHistory(),
                    SizedBox(height: 20),
                    _buildRecentActivity(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}