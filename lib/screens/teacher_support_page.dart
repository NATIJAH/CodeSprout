import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html; // Only used for Flutter Web

class TeacherSupportPage extends StatefulWidget {
  const TeacherSupportPage({super.key});

  @override
  State<TeacherSupportPage> createState() => _TeacherSupportPageState();
}

class _TeacherSupportPageState extends State<TeacherSupportPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _aiController = TextEditingController();

  List<Map<String, dynamic>> _faqs = [];
  List<Map<String, dynamic>> _filteredFaqs = [];

  // AI State
  String _aiReply = "";
  bool _loadingAi = false;

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  // ================= LOAD FAQ =================
  Future<void> _loadFaqs() async {
    try {
      final data = await Supabase.instance.client.from('faq').select();
      setState(() {
        _faqs = List<Map<String, dynamic>>.from(data ?? []);
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
      await Supabase.instance.client.from('feedback').insert({
        'feedback': text,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback dihantar! Terima kasih 😊")),
      );

      _feedbackController.clear();
    } catch (e) {
      debugPrint("Submit feedback error: $e");
    }
  }

  // ================= RESET =================
  void _redoAction() {
    _searchController.clear();
    _feedbackController.clear();
    _aiController.clear();
    setState(() {
      _filteredFaqs = _faqs;
      _aiReply = "";
    });
  }

  // ================= CONTACT SUPPORT =================
  void _contactSupport() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Contact Support"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("📞 Phone"),
            SizedBox(height: 6),
            Text(
              "012-345 6789",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text("🕘 Available: 9.00 AM – 5.00 PM"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  // ================= AI SUPPORT =================
  Future<void> _askAi(String message) async {
    setState(() {
      _loadingAi = true;
      _aiReply = "";
    });

    try {
      if (kIsWeb) {
        // Flutter Web HttpRequest
        final req = html.HttpRequest();
        req
          ..open(
            'POST',
            'https://fyvfocfbxrdaoyecbfzm.supabase.co/functions/v1/dynamic-responder',
          )
          ..setRequestHeader('Content-Type', 'application/json')
          ..onLoad.first.then((_) {
            try {
              final responseData = req.responseText;
              if (responseData != null && responseData.isNotEmpty) {
                final jsonResp = jsonDecode(responseData);
                setState(() {
                  _aiReply = jsonResp['message'] ?? "Tiada jawapan dari AI.";
                });
              } else {
                setState(() {
                  _aiReply = "Tiada jawapan dari AI.";
                });
              }
            } catch (e) {
              setState(() {
                _aiReply = "Ralat membaca jawapan AI.";
              });
            }
          })
          ..onError.first.then((_) {
            setState(() {
              _aiReply = "Ralat berlaku. Cuba lagi.";
            });
          })
          ..send(jsonEncode({'message': message}));
      } else {
        // Mobile / Desktop using Supabase SDK
        final response = await Supabase.instance.client.functions.invoke(
          'dynamic-responder',
          body: {'message': message},
        );

        setState(() {
          _aiReply = response.data?['message'] ?? "Tiada jawapan dari AI.";
        });
      }
    } catch (e) {
      debugPrint("AI error: $e");
      setState(() {
        _aiReply = "Ralat berlaku. Cuba lagi.";
      });
    } finally {
      setState(() {
        _loadingAi = false;
      });
    }
  }

  void _openAiSupport() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("AI Support"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _aiController,
              decoration: const InputDecoration(
                hintText: "Tanya soalan anda...",
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingAi) const CircularProgressIndicator(),
            if (_aiReply.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_aiReply),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _aiController.text.trim();
              if (text.isNotEmpty) {
                _askAi(text);
              }
            },
            child: const Text("Tanya AI"),
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
        title: const Text("Support & Help"),
        backgroundColor: const Color(0xff4f7f67),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFaqs,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _redoAction,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SEARCH
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Cari soalan bantuan...",
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
              // FAQ TITLE
              const Text(
                "FAQ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // FAQ LIST
              _filteredFaqs.isEmpty
                  ? const Text("Tiada FAQ ditemui.")
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredFaqs.length,
                itemBuilder: (context, index) {
                  final faq = _filteredFaqs[index];
                  return Card(
                    child: ExpansionTile(
                      title: Text(
                        faq['question'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(faq['answer'] ?? ''),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // CONTACT SUPPORT
              const Text(
                "Contact Support",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _contactSupport,
                icon: const Icon(Icons.phone),
                label: const Text("Hubungi Support"),
              ),
              const SizedBox(height: 24),
              // FEEDBACK
              const Text(
                "Hantar Feedback",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Tulis feedback anda di sini...",
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
              const SizedBox(height: 24),
              // AI SUPPORT BUTTON
              ElevatedButton.icon(
                onPressed: _openAiSupport,
                icon: const Icon(Icons.smart_toy),
                label: const Text("Hubungi AI"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
