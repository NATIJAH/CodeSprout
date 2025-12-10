import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ProgressReportScreen extends StatefulWidget {
  final String? initialStudentId;
  const ProgressReportScreen({super.key, this.initialStudentId});

  @override
  State<ProgressReportScreen> createState() => _ProgressReportScreenState();
}

class _ProgressReportScreenState extends State<ProgressReportScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _students = [];
  String? _selectedStudentId;
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchStudents().then((_) {
      if (widget.initialStudentId != null) {
        _selectedStudentId = widget.initialStudentId;
        _fetchPerformance(widget.initialStudentId!);
      }
    });
  }

  Future<void> _fetchStudents() async {
    setState(() => _loading = true);
    try {
      final data = await supabase.from('profiles').select('id, full_name, email').eq('role', 'student');
      _students = List<Map<String, dynamic>>.from(data ?? []);
    } catch (e) {
      debugPrint('Failed to fetch students: $e');
      _students = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchPerformance(String studentId) async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('student_performance')
          .select()
          .eq('student_id', studentId)
          .order('recorded_at', ascending: true);
      _rows = List<Map<String, dynamic>>.from(data ?? []);
    } catch (e) {
      debugPrint('Failed to fetch performance: $e');
      _rows = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  List<FlSpot> _buildSpots() {
    final spots = <FlSpot>[];
    for (var i = 0; i < _rows.length; i++) {
      final p = _rows[i];
      final percent = (p['percentage'] as num?)?.toDouble() ?? ((p['score'] != null && p['max_score'] != null) ? (p['score'] / p['max_score'] * 100.0) : 0.0);
      spots.add(FlSpot(i.toDouble(), percent));
    }
    return spots;
  }

  Future<Uint8List?> _captureChartAsPng() async {
    // Chart capture is not supported on web
    try {
      // Only attempt chart capture on non-web platforms
      return null;
    } catch (e) {
      debugPrint('Error capturing chart: $e');
      return null;
    }
  }

  Future<void> _generatePdf() async {
    if (_selectedStudentId == null) return;
    final student = _students.firstWhere((s) => s['id'] == _selectedStudentId, orElse: () => {});
    final chartPng = await _captureChartAsPng();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Student Progress Report')),
          pw.Text('Student: ${student['full_name'] ?? student['email'] ?? ''}'),
          pw.SizedBox(height: 8),
          if (chartPng != null) pw.Center(child: pw.Image(pw.MemoryImage(chartPng), height: 200)),
          pw.SizedBox(height: 12),
          pw.Text('Scores', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            context: context,
            data: <List<String>>[
              ['Date', 'Activity', 'Score', 'Max', 'Percentage', 'Grade'],
              ..._rows.map((r) => [
                    (r['recorded_at']?.toString() ?? ''),
                    (r['activity_id']?.toString() ?? ''),
                    (r['score']?.toString() ?? ''),
                    (r['max_score']?.toString() ?? ''),
                    (r['percentage']?.toString() ?? ''),
                    (r['grade']?.toString() ?? ''),
                  ])
            ],
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: 'progress-${student['full_name'] ?? student['id']}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: (_selectedStudentId == null || _rows.isEmpty) ? null : _generatePdf,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select student'),
                    items: _students.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['full_name'] ?? s['email'] ?? s['id']))).toList(),
                    value: _selectedStudentId,
                    onChanged: (val) async {
                      setState(() => _selectedStudentId = val);
                      if (val != null) await _fetchPerformance(val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _rows.isEmpty
                        ? const Center(child: Text('No performance data'))
                        : Column(
                            children: [
                              RepaintBoundary(
                                key: _chartKey,
                                child: SizedBox(
                                  height: 220,
                                  child: LineChart(
                                    LineChartData(
                                      gridData: FlGridData(show: true),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                      ),
                                      borderData: FlBorderData(show: true),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _buildSpots(),
                                          isCurved: true,
                                          barWidth: 3,
                                          dotData: FlDotData(show: true),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _rows.length,
                                  itemBuilder: (context, i) {
                                    final r = _rows[i];
                                    return Card(
                                      child: ListTile(
                                        title: Text('${r['subject'] ?? "Activity ${r['activity_id'] ?? ''}"} - ${r['percentage'] ?? ''}%'),
                                        subtitle: Text('Score: ${r['score'] ?? ''}/${r['max_score'] ?? ''} | Grade: ${r['grade'] ?? ''}'),
                                        trailing: Text(r['recorded_at']?.toString() ?? ''),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}