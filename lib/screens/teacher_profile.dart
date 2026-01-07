import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_storage_helper.dart';
import 'edit_profile_teacher.dart';
import 'chat_list_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class ViewTeacherProfilePage extends StatefulWidget {
  const ViewTeacherProfilePage({super.key});

  @override
  State<ViewTeacherProfilePage> createState() => _ViewTeacherProfilePageState();
}

class _ViewTeacherProfilePageState extends State<ViewTeacherProfilePage> {
  final supabase = Supabase.instance.client;
  late SupabaseStorageHelper storageHelper;

  Map<String, dynamic>? profile;
  bool loading = true;
  String? errorMsg;

  // Statistics data
  int totalStudents = 0;
  int totalAssignmentsCreated = 0;
  double averageClassPerformance = 0.0;
  int activeThisMonth = 0;
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
          .from("profile_teacher")
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
          .from("profile_teacher")
          .select('email')
          .eq("id", user.id)
          .maybeSingle();

      if (profileData == null) return;

      final teacherEmail = profileData['email'];

      // 1. Total Assignments Created (by this teacher)
      final createdTasks = await supabase
          .from('tasks')
          .select()
          .eq('teacher_email', teacherEmail);

      totalAssignmentsCreated = createdTasks.length;

      // 2. Total Students (unique students assigned tasks)
      final uniqueStudents = <String>{};
      for (var task in createdTasks) {
        if (task['student_email'] != null) {
          uniqueStudents.add(task['student_email']);
        }
      }
      totalStudents = uniqueStudents.length;

      // 3. Average Class Performance (avg points of completed tasks)
      final completedTasks = createdTasks
          .where((task) => task['status'] == 'completed' && task['points'] != null)
          .toList();

      if (completedTasks.isNotEmpty) {
        final points = completedTasks
            .map((task) => (task['points'] as num).toDouble())
            .toList();

        if (points.isNotEmpty) {
          averageClassPerformance = points.reduce((a, b) => a + b) / points.length;
        }
      }

      // 4. Active This Month (students who submitted this month)
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      final activeStudentsSet = <String>{};
      for (var task in createdTasks) {
        if (task['completed_timestamp'] != null) {
          try {
            final completedDate = DateTime.parse(task['completed_timestamp']);
            if (completedDate.isAfter(firstDayOfMonth) && task['student_email'] != null) {
              activeStudentsSet.add(task['student_email']);
            }
          } catch (e) {
            debugPrint("Date parse error: $e");
          }
        }
      }
      activeThisMonth = activeStudentsSet.length;

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
          .from("profile_teacher")
          .update({"avatar_url": result['url']})
          .eq("id", supabase.auth.currentUser!.id);
      await fetchProfile();
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
      return const Scaffold(body: Center(child: Text("No teacher profile found")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Teacher Profile",
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
                          backgroundImage: profile!['avatar_url'] != null && profile!['avatar_url'] != ""
                              ? NetworkImage(profile!['avatar_url'])
                              : null,
                          child: profile!['avatar_url'] == null || profile!['avatar_url'] == ""
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
                    profile!['full_name']?.toString().toUpperCase() ?? "TEACHER NAME",
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
                    profile!['institution'] ?? "",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Role/Status card (subject)
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
                    (profile!['subject'] ?? "Teacher").toString().toUpperCase(),
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
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ViewTeacherProfilePage(),
                            ),
                          );
                          if (updated == true) {
                            await fetchProfile();
                          }
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
                        _detailRow("Full Name", profile!['full_name'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Email", profile!['email'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Phone Number", profile!['phone'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Institution", profile!['institution'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("Subject", profile!['subject'] ?? "-"),
                        const Divider(height: 30),
                        _detailRow("State", profile!['state'] ?? "-"),
                        const Divider(height: 30),
                        //_detailRow("Timezone", profile!['timezone'] ?? "-"),
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
                        _statRow("Total Students",
                            totalStudents.toString(), Icons.people, Colors.blue),
                        const Divider(height: 30),
                        _statRow(
                            "Assignments Created",
                            totalAssignmentsCreated.toString(),
                            Icons.assignment,
                            Colors.purple),
                        const Divider(height: 30),
                        _statRow(
                            "Avg Class Performance",
                            averageClassPerformance > 0
                                ? "${averageClassPerformance.toStringAsFixed(1)} pts"
                                : "N/A",
                            Icons.trending_up,
                            Colors.green),
                        const Divider(height: 30),
                        _statRow(
                            "Active This Month",
                            "$activeThisMonth students",
                            Icons.calendar_month,
                            Colors.orange),
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
                        _actionRow("Contact Students", Icons.chat, () {
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
