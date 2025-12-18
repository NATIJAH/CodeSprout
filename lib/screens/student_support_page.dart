import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html; // Flutter Web only

class StudentSupportPage extends StatefulWidget {
  const StudentSupportPage({super.key});

  @override
  State<StudentSupportPage> createState() => _StudentSupportPageState();
}

class _StudentSupportPageState extends State<StudentSupportPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _aiController = TextEditingController();

  List<Map<String, dynamic>> _faqs = [];
  List<Map<String, dynamic>> _filteredFaqs = [];

  String _aiReply = "";
  bool _loadingAi = false;

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  // ================= LOAD STUDENT FAQ =================
  Future<void> _loadFaqs() async {
    try {
      final data = await Supabase.instance.client
          .from('faq')
          .select()
          .eq('role', 'student');

      setState(() {
        _faqs = List<Map<String, dynamic>>.from(data);
        _filteredFaqs = _faqs;
      });
    } catch (e) {
      debugPrint("Load FAQ error: $e");
    }
  }

  // ================= SEARCH =================
  void _searchHelp() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFaqs = _faqs.where((faq) {
        final q = (faq['question'] ?? '').toString().toLowerCase();
        final a = (faq['answer'] ?? '').toString().toLowerCase();
        return q.contains(query) || a.contains(query);
      }).toList();
    });
  }

  // ================= SUBMIT FEEDBACK =================
  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;

    try {
      await Supabase.instance.client.from('student_feedback').insert({
        'feedback': text,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback berjaya dihantar 🎓")),
      );

      _feedbackController.clear();
    } catch (e) {
      debugPrint("Feedback error: $e");
    }
  }

  // ================= AI =================
  Future<void> _askAi(String message) async {
    setState(() {
      _loadingAi = true;
      _aiReply = "";
    });

    try {
      if (kIsWeb) {
        final req = html.HttpRequest();
        req
          ..open(
            'POST',
            'https://fyvfocfbxrdaoyecbfzm.supabase.co/functions/v1/dynamic-responder',
          )
          ..setRequestHeader('Content-Type', 'application/json')
          ..onLoad.first.then((_) {
            final jsonResp = jsonDecode(req.responseText!);
            setState(() {
              _aiReply = jsonResp['message'] ?? "Tiada jawapan.";
            });
          })
          ..send(jsonEncode({'message': message}));
      } else {
        final response = await Supabase.instance.client.functions.invoke(
          'dynamic-responder',
          body: {'message': message},
        );
        setState(() {
          _aiReply = response.data?['message'] ?? "Tiada jawapan.";
        });
      }
    } catch (_) {
      setState(() => _aiReply = "Ralat berlaku.");
    } finally {
      setState(() => _loadingAi = false);
    }
  }

  void _openAiSupport() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("AI Pelajar"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _aiController,
              decoration:
              const InputDecoration(hintText: "Tanya soalan anda..."),
            ),
            const SizedBox(height: 12),
            if (_loadingAi) const CircularProgressIndicator(),
            if (_aiReply.isNotEmpty) Text(_aiReply),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_aiController.text.trim().isNotEmpty) {
                _askAi(_aiController.text.trim());
              }
            },
            child: const Text("Tanya"),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bantuan Pelajar"),
        backgroundColor: const Color(0xff4f7f67),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Cari soalan...",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchHelp,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "FAQ Pelajar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _filteredFaqs.isEmpty
                  ? const Text("Tiada soalan.")
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredFaqs.length,
                itemBuilder: (context, index) {
                  final faq = _filteredFaqs[index];
                  return Card(
                    child: ExpansionTile(
                      title: Text(faq['question']),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(faq['answer']),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                "Feedback",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Masukkan feedback anda...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _submitFeedback,
                child: const Text("Hantar"),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _openAiSupport,
                icon: const Icon(Icons.smart_toy),
                label: const Text("AI Pelajar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
