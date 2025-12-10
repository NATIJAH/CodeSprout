import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/performance_service.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final _service = PerformanceService();
  bool _loading = true;
  bool _isTeacher = false;

  // Student data
  Map<String, dynamic> _studentData = {
    'submitted': [],
    'notSubmitted': [],
    'performance': [],
  };

  // Teacher data
  Map<String, dynamic> _classStats = {
    'totalRecords': 0,
    'averageScore': '0',
    'averagePercentage': '0',
    'gradeDistribution': {},
    'atRiskStudents': [],
  };
  List<Map<String, dynamic>> _allPerformance = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Check if user is a teacher
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final teacherData = await Supabase.instance.client
            .from('profile_teacher')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        setState(() => _isTeacher = teacherData != null);
      } catch (e) {
        debugPrint('Error checking teacher role: $e');
      }
    }

    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (_isTeacher) {
        // Load teacher data
        _classStats = await _service.fetchClassPerformanceSummary();
        _allPerformance = await _service.fetchAllStudentsPerformance();
      } else {
        // Load student data
        _studentData = await _service.fetchActivitiesWithSubmissionStatus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantau Prestasi Murid'),
        backgroundColor: const Color(0xff4f7f67),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isTeacher
              ? _buildTeacherView()
              : _buildStudentView(),
    );
  }

  // ============ STUDENT VIEW ============
  Widget _buildStudentView() {
    final submitted = List<Map<String, dynamic>>.from(_studentData['submitted'] ?? []);
    final notSubmitted = List<Map<String, dynamic>>.from(_studentData['notSubmitted'] ?? []);
    final performance = List<Map<String, dynamic>>.from(_studentData['performance'] ?? []);

    final perfMap = <int, Map<String, dynamic>>{};
    for (final p in performance) {
      perfMap[p['activity_id']] = p;
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Summary stats
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Jumlah Aktiviti', (submitted.length + notSubmitted.length).toString(), Colors.blue),
                  _buildStatCard('Telah Dikumpulkan', submitted.length.toString(), Colors.green),
                  _buildStatCard('Belum Dikumpulkan', notSubmitted.length.toString(), Colors.orange),
                ],
              ),
            ),

            // Submitted section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktiviti Telah Dikumpulkan (${submitted.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (submitted.isEmpty)
                    const Center(child: Text('Tiada aktiviti yang telah dikumpulkan'))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: submitted.length,
                      itemBuilder: (context, i) {
                        final activity = submitted[i];
                        final activityId = activity['id'];
                        final perf = perfMap[activityId];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text(activity['title'] ?? 'Aktiviti ${activityId}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: perf != null
                                ? Text('Skor: ${perf['score']}/${perf['max_score']} • Gred: ${perf['grade'] ?? '-'} • ${perf['percentage'] ?? 0}%')
                                : const Text('Tiada data prestasi'),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Not submitted section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktiviti Belum Dikumpulkan (${notSubmitted.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (notSubmitted.isEmpty)
                    const Center(child: Text('Semua aktiviti telah dikumpulkan!'))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: notSubmitted.length,
                      itemBuilder: (context, i) {
                        final activity = notSubmitted[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.pending, color: Colors.orange),
                            title: Text(activity['title'] ?? 'Aktiviti',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: activity['due_date'] != null
                                ? Text('Tarikh Akhir: ${activity['due_date']}')
                                : const Text('Tiada tarikh akhir'),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ TEACHER VIEW ============
  Widget _buildTeacherView() {
    final atRiskStudents = List<Map<String, dynamic>>.from(_classStats['atRiskStudents'] ?? []);
    final gradeDistribution = _classStats['gradeDistribution'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Class Performance Summary
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Prestasi Kelas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('Jumlah Rekod', (_classStats['totalRecords'] ?? 0).toString(), Colors.blue),
                      _buildStatCard('Purata Skor', (_classStats['averageScore'] ?? 0).toString(), Colors.green),
                      _buildStatCard('Purata %', (_classStats['averagePercentage'] ?? 0).toString(), Colors.orange),
                    ],
                  ),
                ],
              ),
            ),

            // Grade Distribution
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Taburan Gred',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['A', 'B', 'C', 'D', 'E', 'F']
                        .map((grade) => Chip(
                              label: Text('$grade: ${gradeDistribution[grade] ?? 0}'),
                              backgroundColor: _getGradeColor(grade),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            // At-Risk Students
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Murid Berisiko (Skor < 50%) - ${atRiskStudents.length}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  if (atRiskStudents.isEmpty)
                    const Center(child: Text('Tiada murid berisiko! 🎉', style: TextStyle(color: Colors.green)))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: atRiskStudents.length,
                      itemBuilder: (context, i) {
                        final perf = atRiskStudents[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.red[50],
                          child: ListTile(
                            leading: const Icon(Icons.warning, color: Colors.red),
                            title: Text('Murid ID: ${perf['student_id']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Aktiviti: ${perf['activity_id']}'),
                                Text('Skor: ${perf['score']}/${perf['max_score']} (${perf['percentage']}%)'),
                                Text('Gred: ${perf['grade'] ?? '-'}'),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showFeedbackDialog(perf),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Progress Report for All Students
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laporan Kemajuan Semua Murid',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_allPerformance.isEmpty)
                    const Center(child: Text('Tiada data prestasi'))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _allPerformance.length,
                      itemBuilder: (context, i) {
                        final perf = _allPerformance[i];
                        final percentage = perf['percentage'] is num
                          ? (perf['percentage'] as num).toDouble()
                          : double.tryParse((perf['percentage'] ?? '').toString()) ?? 0.0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text('Murid: ${perf['student_id']}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percentage / 100,
                                  color: _getPercentageColor(percentage),
                                ),
                                const SizedBox(height: 4),
                                Text('Aktiviti: ${perf['activity_id']} • Skor: ${perf['score']}/${perf['max_score']} • ${percentage.toStringAsFixed(1)}% • Gred: ${perf['grade'] ?? '-'}'),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green[300]!;
      case 'B':
        return Colors.blue[300]!;
      case 'C':
        return Colors.yellow[300]!;
      case 'D':
        return Colors.orange[300]!;
      case 'E':
        return Colors.red[300]!;
      default:
        return Colors.red[400]!;
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  void _showFeedbackDialog(Map<String, dynamic> perf) {
    final feedbackCtrl = TextEditingController(text: perf['feedback'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah Maklum Balas untuk Murid ${perf['student_id']}'),
        content: TextField(
          controller: feedbackCtrl,
          decoration: const InputDecoration(labelText: 'Maklum balas'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              try {
                // Update feedback in performance record
                await Supabase.instance.client
                    .from('student_performance')
                    .update({'feedback': feedbackCtrl.text})
                    .eq('id', perf['id']);
                Navigator.pop(ctx);
                await _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maklum balas disimpan')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
