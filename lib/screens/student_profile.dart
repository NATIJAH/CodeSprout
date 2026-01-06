import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_storage_helper.dart';
import 'edit_profile_student.dart';
import 'chat_list_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class ViewProfilePage extends StatefulWidget {
  const ViewProfilePage({super.key});

  @override
  State<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  final supabase = Supabase.instance.client;
  late SupabaseStorageHelper storageHelper;

  Map<String, dynamic>? profile;
  bool loading = true;
  String? errorMsg;

  // Statistics data
  int totalAssignments = 0;
  double averageGrade = 0.0;
  int daysActive = 0;
  int onTimeCount = 0;
  int lateCount = 0;
  bool loadingStats = true;

  // AI Support state
  String _aiReply = "";
  bool _loadingAi = false;
  final TextEditingController _aiController = TextEditingController();

  // Color scheme
  final Color headerColor = const Color(0xFFE8F4F8);
  final Color cardColor = Colors.white;
  final Color accentColor = const Color(0xFF0066CC);

  @override
  void initState() {
    super.initState();
    storageHelper = SupabaseStorageHelper(supabase: supabase);
    fetchProfile();
    fetchStatistics();
  }

  @override
  void dispose() {
    _aiController.dispose();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    setState(() => loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          loading = false;
          errorMsg = "No user logged in";
        });
        return;
      }

      final data = await supabase
          .from("profile_student")
          .select()
          .eq("id", user.id)
          .maybeSingle();

      setState(() {
        profile = data;
        loading = false;
        errorMsg = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Error loading profile: $e";
      });
    }
  }

  Future<void> fetchStatistics() async {
    setState(() => loadingStats = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Get profile to get email
      final profileData = await supabase
          .from("profile_student")
          .select('email, created_at')
          .eq("id", user.id)
          .maybeSingle();

      if (profileData == null) return;

      final userEmail = profileData['email'];

      // 1. Total Assignments Completed
      final completedTasks = await supabase
          .from('tasks')
          .select()
          .eq('student_email', userEmail)
          .eq('status', 'completed');

      totalAssignments = completedTasks.length;

      // 2. Average Grade (from points)
      if (completedTasks.isNotEmpty) {
        final points = completedTasks
            .where((task) => task['points'] != null)
            .map((task) => (task['points'] as num).toDouble())
            .toList();

        if (points.isNotEmpty) {
          averageGrade = points.reduce((a, b) => a + b) / points.length;
        }
      }

      // 3. Days Active (from created_at)
      if (profileData['created_at'] != null) {
        final createdDate = DateTime.parse(profileData['created_at']);
        daysActive = DateTime.now().difference(createdDate).inDays;
      }

      // 4. On Time vs Late
      for (var task in completedTasks) {
        if (task['completed_timestamp'] != null && task['due_date'] != null) {
          try {
            final completed = DateTime.parse(task['completed_timestamp']);
            final due = DateTime.parse(task['due_date']);

            if (completed.isBefore(due) || completed.isAtSameMomentAs(due)) {
              onTimeCount++;
            } else {
              lateCount++;
            }
          } catch (e) {
            debugPrint("Date parse error: $e");
          }
        }
      }

      setState(() => loadingStats = false);
    } catch (e) {
      debugPrint("Statistics error: $e");
      setState(() => loadingStats = false);
    }
  }

  Future<void> pickAndUploadImage() async {
    final result = await storageHelper.pickAndUploadImage(bucketName: 'profile-images');
    if (result != null && result['url'] != null) {
      await supabase
          .from("profile_student")
          .update({"avatar_url": result['url']})
          .eq("id", supabase.auth.currentUser!.id);

      fetchProfile();
    }
  }

  // AI Support Function
  Future<void> _askAi(String message, [Function? dialogSetState]) async {
    if (!mounted) return;

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
          ..setRequestHeader('Authorization', 'Bearer ${supabase.auth.currentSession?.accessToken ?? ""}')
          ..onLoad.first.then((_) {
            if (!mounted) return;
            try {
              if (req.status == 200) {
                final responseData = req.responseText;
                if (responseData != null && responseData.isNotEmpty) {
                  final jsonResp = jsonDecode(responseData);

                  if (!mounted) return;
                  updateState(() {
                    _aiReply = jsonResp['message'] ?? "Tiada jawapan dari AI.";
                    _loadingAi = false;
                  });
                }
              }
            } catch (e) {
              debugPrint("❌ AI Parse error: $e");
              if (!mounted) return;
              updateState(() {
                _aiReply = "Ralat membaca jawapan AI.";
                _loadingAi = false;
              });
            }
          })
          ..onError.first.then((error) {
            debugPrint("❌ AI Request error: $error");
            if (!mounted) return;
            updateState(() {
              _aiReply = "Ralat berlaku. Sila cuba lagi.";
              _loadingAi = false;
            });
          })
          ..send(jsonEncode({'message': message}));
      } else {
        final response = await supabase.functions.invoke(
          'ai-support',
          body: {'message': message},
        );

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
            title: const Text("Bantuan AI"),
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
                    _askAi(text, setDialogState);
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

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tukar Kata Laluan"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Kata Laluan Lama",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Kata Laluan Baru",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Sahkan Kata Laluan Baru",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPass = newPasswordController.text.trim();
              final confirmPass = confirmPasswordController.text.trim();

              if (newPass.isEmpty || confirmPass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sila isi semua medan")),
                );
                return;
              }

              if (newPass != confirmPass) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kata laluan tidak sepadan")),
                );
                return;
              }

              try {
                await supabase.auth.updateUser(UserAttributes(password: newPass));
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kata laluan berjaya ditukar!")),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Ralat: $e")),
                );
              }
            },
            child: const Text("Tukar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMsg != null) {
      return Scaffold(body: Center(child: Text(errorMsg!)));
    }

    if (profile == null) {
      return const Scaffold(
          body: Center(child: Text("No student profile found")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section with profile picture and name
            Container(
              width: double.infinity,
              color: headerColor,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: profile!['avatar_url'] != null
                              ? NetworkImage(profile!['avatar_url'])
                              : null,
                          child: profile!['avatar_url'] == null
                              ? const Icon(Icons.person, size: 70, color: Colors.white)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    profile!['full_name']?.toString().toUpperCase() ?? "STUDENT NAME",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile!['matric_no'] ?? "",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Role/Status card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    profile!['institution']?.toString().toUpperCase() ?? "PELAJAR",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // User Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "User details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditStudentProfilePage(),
                            ),
                          );
                          fetchProfile();
                        },
                        child: Text(
                          "Edit profile",
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _detailRow("Email address", profile!['email'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Phone Number", profile!['phone'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Age", profile!['age']?.toString() ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Class", profile!['class'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Timezone", "Asia/Kuala_Lumpur"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Statistics Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Statistics",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: loadingStats
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                      children: [
                        _statRow(
                            "Total Assignments Completed",
                            totalAssignments.toString(),
                            Icons.check_circle,
                            Colors.green),
                        const Divider(height: 30),
                        _statRow(
                            "Average Grade",
                            averageGrade > 0
                                ? "${averageGrade.toStringAsFixed(1)} points"
                                : "N/A",
                            Icons.star,
                            Colors.amber),
                        const Divider(height: 30),
                        _statRow("Days Active", "$daysActive days",
                            Icons.calendar_today, Colors.blue),
                        const Divider(height: 30),
                        _statRow(
                            "On Time / Late",
                            "$onTimeCount / $lateCount",
                            Icons.timer,
                            onTimeCount > lateCount
                                ? Colors.green
                                : Colors.orange),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Quick Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _actionRow("Change Password", Icons.lock, () {
                          _showChangePasswordDialog();
                        }),
                        const Divider(height: 24),
                        _actionRow("Contact Teacher", Icons.chat, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ChatListScreen()),
                          );
                        }),
                        const Divider(height: 24),
                        _actionRow("Bantuan AI", Icons.smart_toy, () {
                          _openAiSupport();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionRow(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}