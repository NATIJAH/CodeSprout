import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'progress_report.dart';

class AtRiskScreen extends StatefulWidget {
  const AtRiskScreen({super.key});

  @override
  State<AtRiskScreen> createState() => _AtRiskScreenState();
}

class _AtRiskScreenState extends State<AtRiskScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _performances = [];
  double _threshold = 60.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final studentsData = await supabase.from('profiles').select('id, full_name, email').eq('role', 'student');
      _students = List<Map<String, dynamic>>.from(studentsData ?? []);

      final perfData = await supabase.from('student_performance').select('student_id, score').order('recorded_at', ascending: true);
      _performances = List<Map<String, dynamic>>.from(perfData ?? []);
    } catch (e) {
      debugPrint('Error loading at-risk data: $e');
      _students = [];
      _performances = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  double _avgForStudentId(String id) {
    final rows = _performances.where((p) => p['student_id'] == id).toList();
    if (rows.isEmpty) return 0.0;
    final sum = rows.map((r) => (r['score'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a + b);
    return sum / rows.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('At-Risk Students')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Threshold:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _threshold,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: _threshold.toStringAsFixed(0),
                          onChanged: (v) => setState(() => _threshold = v),
                        ),
                      ),
                      Text('${_threshold.toStringAsFixed(0)}%')
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: _students.map((s) {
                        final id = s['id'];
                        final avg = _avgForStudentId(id);
                        if (avg >= _threshold) return const SizedBox.shrink();
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.warning, color: Colors.red),
                            title: Text(s['full_name'] ?? s['email'] ?? id),
                            subtitle: Text('Average: ${avg.toStringAsFixed(1)}%'),
                            trailing: IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ProgressReportScreen(initialStudentId: id)));
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}