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

  @override
  void dispose() {
    _searchController.dispose();
    _feedbackController.dispose();
    _aiController.dispose();
    super.dispose();
  }

  // ================= LOAD FAQ =================
  Future<void> _loadFaqs() async {
    try {
      final data = await Supabase.instance.client
          .from('faq')
          .select()
          .eq('role', 'teacher');

      if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ralat: $e")),
      );
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
  Future<void> _askAi(String message, [Function? dialogSetState]) async {
    if (!mounted) return;

    // Use dialogSetState if provided, otherwise use setState
    final updateState = dialogSetState ?? setState;

    updateState(() {
      _loadingAi = true;
      _aiReply = "";
    });

    try {
      debugPrint("🤖 Asking AI: $message");

      if (kIsWeb) {
        final req = html.HttpRequest();
        req
          ..open(
            'POST',
            'https://fyvfocfbxrdaoyecbfzm.supabase.co/functions/v1/ai-support',
          )
          ..setRequestHeader('Content-Type', 'application/json')
          ..setRequestHeader('Authorization', 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken ?? ""}')
          ..onLoad.first.then((_) {
            if (!mounted) return;
            try {
              debugPrint("✅ AI Response received: ${req.status}");
              debugPrint("📦 Response Text: ${req.responseText}");

              if (req.status == 200) {
                final responseData = req.responseText;
                if (responseData != null && responseData.isNotEmpty) {
                  final jsonResp = jsonDecode(responseData);
                  debugPrint("🔍 Parsed JSON: $jsonResp");

                  if (!mounted) return;
                  updateState(() {
                    _aiReply = jsonResp['message'] ?? "Tiada jawapan dari AI.";
                    _loadingAi = false;
                  });
                } else {
                  if (!mounted) return;
                  updateState(() {
                    _aiReply = "Tiada jawapan dari AI.";
                    _loadingAi = false;
                  });
                }
              } else {
                debugPrint("❌ AI Error status: ${req.status}");
                debugPrint("Response: ${req.responseText}");
                if (!mounted) return;
                updateState(() {
                  _aiReply = "Ralat: Status ${req.status}. Cuba lagi.";
                  _loadingAi = false;
                });
              }
            } catch (e) {
              debugPrint("❌ AI Parse error: $e");
              if (!mounted) return;
              updateState(() {
                _aiReply = "Ralat membaca jawapan AI: $e";
                _loadingAi = false;
              });
            }
          })
          ..onError.first.then((error) {
            debugPrint("❌ AI Request error: $error");
            if (!mounted) return;
            updateState(() {
              _aiReply = "Ralat berlaku. Sila semak connection. Error: $error";
              _loadingAi = false;
            });
          })
          ..send(jsonEncode({'message': message}));
      } else {
        // For mobile/desktop
        final response = await Supabase.instance.client.functions.invoke(
          'ai-support',
          body: {'message': message},
        );

        debugPrint("✅ AI Response: ${response.data}");

        if (!mounted) return;
        updateState(() {
          _aiReply = response.data?['message'] ?? "Tiada jawapan dari AI.";
          _loadingAi = false;
        });
      }
    } catch (e) {
      debugPrint("❌ AI error: $e");
      if (!mounted) return;
      updateState(() {
        _aiReply = "Ralat berlaku: $e";
        _loadingAi = false;
      });
    }
  }

  void _openAiSupport() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("AI Support"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _aiController,
                    decoration: const InputDecoration(
                      hintText: "Tanya soalan anda...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  if (_loadingAi)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  if (_aiReply.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Jawapan AI:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_aiReply),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _aiReply = "";
                    _aiController.clear();
                    _loadingAi = false;
                  });
                },
                child: const Text("Tutup"),
              ),
              ElevatedButton(
                onPressed: _loadingAi ? null : () {
                  final text = _aiController.text.trim();
                  if (text.isNotEmpty) {
                    _askAi(text, setDialogState); // Pass setDialogState to update dialog UI
                  }
                },
                child: const Text("Tanya AI"),
              ),
            ],
          );
        },
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
              const Text(
                "FAQ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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