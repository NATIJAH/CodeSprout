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

  // Password change controllers
  final _passwordFormKey = GlobalKey<FormState>();

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

  // ============ DATA VALIDATION HELPERS ============

  /// Validates if a string is a valid email format
  bool _isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validates if a string is a valid phone number (Malaysian format)
  bool _isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) return true; // Optional field
    final phoneRegex = RegExp(r'^(\+?6?01)[0-46-9]-*[0-9]{7,8}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s-]'), ''));
  }

  /// Validates if age is within reasonable range
  bool _isValidAge(dynamic age) {
    if (age == null) return true; // Optional field
    try {
      final ageInt = age is int ? age : int.parse(age.toString());
      return ageInt >= 5 && ageInt <= 100;
    } catch (e) {
      return false;
    }
  }

  /// Validates password strength
  String? _validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Kata laluan diperlukan';
    }
    if (password.length < 8) {
      return 'Kata laluan mesti sekurang-kurangnya 8 aksara';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Kata laluan mesti mengandungi huruf besar';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Kata laluan mesti mengandungi huruf kecil';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Kata laluan mesti mengandungi nombor';
    }
    return null;
  }

  /// Sanitizes user input to prevent XSS and injection
  String _sanitizeInput(String? input) {
    if (input == null) return '';
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[^\w\s@.,!?-]'), ''); // Allow safe characters
  }

  /// Validates AI message input
  String? _validateAiMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return 'Sila masukkan soalan anda';
    }
    if (message.trim().length < 3) {
      return 'Soalan terlalu pendek (minimum 3 aksara)';
    }
    if (message.length > 500) {
      return 'Soalan terlalu panjang (maksimum 500 aksara)';
    }
    return null;
  }

  /// Validates profile data before displaying
  Map<String, dynamic> _validateProfileData(Map<String, dynamic>? data) {
    if (data == null) return {};

    return {
      'id': data['id'],
      'full_name': data['full_name']?.toString().trim() ?? 'Unknown',
      'email': _isValidEmail(data['email']?.toString())
          ? data['email']
          : 'Invalid Email',
      'matric_no': data['matric_no']?.toString().trim() ?? '-',
      'phone': _isValidPhone(data['phone']?.toString())
          ? data['phone']
          : 'Invalid Phone',
      'age': _isValidAge(data['age']) ? data['age'] : null,
      'class': data['class']?.toString().trim() ?? '-',
      'institution': data['institution']?.toString().trim() ?? 'PELAJAR',
      'avatar_url': data['avatar_url']?.toString().isNotEmpty == true
          ? data['avatar_url']
          : null,
      'created_at': data['created_at'],
    };
  }

  /// Validates statistics data
  bool _validateStatisticsData(List<dynamic> tasks) {
    try {
      for (var task in tasks) {
        if (task is! Map) return false;
        
        // Validate points if present
        if (task['points'] != null) {
          final points = num.tryParse(task['points'].toString());
          if (points == null || points < 0 || points > 100) {
            debugPrint('Invalid points value: ${task['points']}');
          }
        }

        // Validate dates if present
        if (task['completed_timestamp'] != null) {
          try {
            DateTime.parse(task['completed_timestamp']);
          } catch (e) {
            debugPrint('Invalid completed_timestamp: ${task['completed_timestamp']}');
          }
        }

        if (task['due_date'] != null) {
          try {
            DateTime.parse(task['due_date']);
          } catch (e) {
            debugPrint('Invalid due_date: ${task['due_date']}');
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('Statistics validation error: $e');
      return false;
    }
  }

  // ============ DATA FETCHING WITH VALIDATION ============

  Future<void> fetchProfile() async {
    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          loading = false;
          errorMsg = "No user logged in";
        });
        return;
      }

      // Validate user ID
      if (user.id.isEmpty) {
        throw Exception('Invalid user ID');
      }

      final data = await supabase
          .from("profile_student")
          .select()
          .eq("id", user.id)
          .maybeSingle();

      if (data == null) {
        setState(() {
          loading = false;
          errorMsg = "Profile not found";
        });
        return;
      }

      // Validate and sanitize profile data
      final validatedProfile = _validateProfileData(data);

      setState(() {
        profile = validatedProfile;
        loading = false;
        errorMsg = null;
      });
    } catch (e) {
      debugPrint('Profile fetch error: $e');
      setState(() {
        loading = false;
        errorMsg = "Error loading profile: ${e.toString()}";
      });
    }
  }

  Future<void> fetchStatistics() async {
    setState(() => loadingStats = true);
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => loadingStats = false);
        return;
      }

      // Get profile to get email
      final profileData = await supabase
          .from("profile_student")
          .select('email, created_at')
          .eq("id", user.id)
          .maybeSingle();

      if (profileData == null) {
        setState(() => loadingStats = false);
        return;
      }

      final userEmail = profileData['email'];

      // Validate email
      if (!_isValidEmail(userEmail?.toString())) {
        debugPrint('Invalid email in profile: $userEmail');
        setState(() => loadingStats = false);
        return;
      }

      // 1. Total Assignments Completed
      final completedTasks = await supabase
          .from('tasks')
          .select()
          .eq('student_email', userEmail)
          .eq('status', 'completed');

      // Validate tasks data
      if (!_validateStatisticsData(completedTasks)) {
        debugPrint('Invalid tasks data structure');
      }

      totalAssignments = completedTasks.length;

      // 2. Average Grade (from points) with validation
      if (completedTasks.isNotEmpty) {
        final points = completedTasks
            .where((task) => task['points'] != null)
            .map((task) {
              try {
                final pointValue = num.tryParse(task['points'].toString());
                if (pointValue != null && pointValue >= 0 && pointValue <= 100) {
                  return pointValue.toDouble();
                }
                return null;
              } catch (e) {
                debugPrint('Invalid point value: ${task['points']}');
                return null;
              }
            })
            .where((point) => point != null)
            .cast<double>()
            .toList();

        if (points.isNotEmpty) {
          averageGrade = points.reduce((a, b) => a + b) / points.length;
          // Ensure average is within valid range
          averageGrade = averageGrade.clamp(0.0, 100.0);
        }
      }

      // 3. Days Active (from created_at) with validation
      if (profileData['created_at'] != null) {
        try {
          final createdDate = DateTime.parse(profileData['created_at']);
          final now = DateTime.now();
          
          // Validate date is not in the future
          if (createdDate.isAfter(now)) {
            debugPrint('Invalid created_at date (future date): $createdDate');
            daysActive = 0;
          } else {
            daysActive = now.difference(createdDate).inDays;
            // Ensure reasonable range
            daysActive = daysActive.clamp(0, 10000);
          }
        } catch (e) {
          debugPrint("Date parse error: $e");
          daysActive = 0;
        }
      }

      // 4. On Time vs Late with validation
      int validOnTimeCount = 0;
      int validLateCount = 0;

      for (var task in completedTasks) {
        if (task['completed_timestamp'] != null && task['due_date'] != null) {
          try {
            final completed = DateTime.parse(task['completed_timestamp']);
            final due = DateTime.parse(task['due_date']);

            // Validate dates are reasonable
            final now = DateTime.now();
            if (completed.isAfter(now.add(const Duration(days: 1)))) {
              debugPrint('Invalid completed date (future): $completed');
              continue;
            }

            if (completed.isBefore(due) || completed.isAtSameMomentAs(due)) {
              validOnTimeCount++;
            } else {
              validLateCount++;
            }
          } catch (e) {
            debugPrint("Date parse error in task: $e");
          }
        }
      }

      onTimeCount = validOnTimeCount;
      lateCount = validLateCount;

      setState(() => loadingStats = false);
    } catch (e) {
      debugPrint("Statistics error: $e");
      setState(() {
        loadingStats = false;
        // Reset to safe defaults
        totalAssignments = 0;
        averageGrade = 0.0;
        daysActive = 0;
        onTimeCount = 0;
        lateCount = 0;
      });
    }
  }

  Future<void> pickAndUploadImage() async {
    try {
      final result = await storageHelper.pickAndUploadImage(
        bucketName: 'profile-images',
      );
      
      if (result != null && result['url'] != null) {
        final url = result['url'].toString();
        
        // Validate URL format
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          throw Exception('Invalid image URL format');
        }

        await supabase
            .from("profile_student")
            .update({"avatar_url": url})
            .eq("id", supabase.auth.currentUser!.id);

        await fetchProfile();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gambar profil berjaya dikemas kini')),
          );
        }
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat memuat naik gambar: $e')),
        );
      }
    }
  }

  // ============ AI SUPPORT WITH VALIDATION ============

  Future<void> _askAi(String message, [Function? dialogSetState]) async {
    if (!mounted) return;

    // Validate message
    final validationError = _validateAiMessage(message);
    if (validationError != null) {
      final updateState = dialogSetState ?? setState;
      updateState(() {
        _aiReply = validationError;
        _loadingAi = false;
      });
      return;
    }

    // Sanitize input
    final sanitizedMessage = _sanitizeInput(message);

    final updateState = dialogSetState ?? setState;

    updateState(() {
      _loadingAi = true;
      _aiReply = "";
    });

    try {
      debugPrint("🤖 Asking AI: $sanitizedMessage");

      if (kIsWeb) {
        final req = html.HttpRequest();
        req
          ..open(
            'POST',
            'https://fyvfocfbxrdaoyecbfzm.supabase.co/functions/v1/ai-support',
          )
          ..setRequestHeader('Content-Type', 'application/json')
          ..setRequestHeader(
            'Authorization',
            'Bearer ${supabase.auth.currentSession?.accessToken ?? ""}',
          )
          ..timeout = 30000 // 30 second timeout
          ..onLoad.first.then((_) {
            if (!mounted) return;
            try {
              if (req.status == 200) {
                final responseData = req.responseText;
                if (responseData != null && responseData.isNotEmpty) {
                  final jsonResp = jsonDecode(responseData);

                  // Validate response
                  if (jsonResp is Map && jsonResp.containsKey('message')) {
                    final aiMessage = jsonResp['message']?.toString() ?? '';
                    
                    if (!mounted) return;
                    updateState(() {
                      _aiReply = aiMessage.isEmpty
                          ? "Tiada jawapan dari AI."
                          : _sanitizeInput(aiMessage);
                      _loadingAi = false;
                    });
                  } else {
                    throw Exception('Invalid response format');
                  }
                } else {
                  throw Exception('Empty response');
                }
              } else {
                throw Exception('HTTP ${req.status}: ${req.statusText}');
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
          ..onTimeout.first.then((_) {
            debugPrint("❌ AI Request timeout");
            if (!mounted) return;
            updateState(() {
              _aiReply = "Permintaan tamat masa. Sila cuba lagi.";
              _loadingAi = false;
            });
          })
          ..send(jsonEncode({'message': sanitizedMessage}));
      } else {
        final response = await supabase.functions.invoke(
          'ai-support',
          body: {'message': sanitizedMessage},
        );

        if (!mounted) return;
        
        final aiMessage = response.data?['message']?.toString() ?? '';
        
        updateState(() {
          _aiReply = aiMessage.isEmpty
              ? "Tiada jawapan dari AI."
              : _sanitizeInput(aiMessage);
          _loadingAi = false;
        });
      }
    } catch (e) {
      debugPrint("❌ AI error: $e");
      if (!mounted) return;
      updateState(() {
        _aiReply = "Ralat berlaku: ${e.toString()}";
        _loadingAi = false;
      });
    }
  }

  void _openAiSupport() {
    // Reset state when opening dialog
    _aiController.clear();
    _aiReply = "";
    _loadingAi = false;

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
                    decoration: InputDecoration(
                      hintText: "Tanya soalan anda...",
                      border: const OutlineInputBorder(),
                      counterText: '${_aiController.text.length}/500',
                    ),
                    maxLines: 3,
                    maxLength: 500,
                    onChanged: (value) {
                      setDialogState(() {}); // Update character count
                    },
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
                onPressed: _loadingAi
                    ? null
                    : () {
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

  // ============ PASSWORD CHANGE WITH VALIDATION ============

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Tukar Kata Laluan"),
            content: SingleChildScrollView(
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: oldPasswordController,
                      obscureText: obscureOld,
                      decoration: InputDecoration(
                        labelText: "Kata Laluan Lama",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureOld ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureOld = !obscureOld;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Sila masukkan kata laluan lama';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: "Kata Laluan Baru",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                        helperText: 'Min 8 aksara, huruf besar/kecil, nombor',
                        helperMaxLines: 2,
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: "Sahkan Kata Laluan Baru",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Sila sahkan kata laluan baru';
                        }
                        if (value != newPasswordController.text) {
                          return 'Kata laluan tidak sepadan';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_passwordFormKey.currentState?.validate() != true) {
                    return;
                  }

                  final newPass = newPasswordController.text.trim();

                  try {
                    await supabase.auth.updateUser(
                      UserAttributes(password: newPass),
                    );
                    
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Kata laluan berjaya ditukar!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    debugPrint('Password change error: $e');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Ralat: ${e.toString()}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text("Tukar"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============ UI BUILD ============

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMsg != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMsg!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchProfile,
                child: const Text('Cuba Semula'),
              ),
            ],
          ),
        ),
      );
    }

    if (profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text("No student profile found"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchProfile,
                child: const Text('Cuba Semula'),
              ),
            ],
          ),
        ),
      );
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
                              ? const Icon(Icons.person,
                                  size: 70, color: Colors.white)
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
                    profile!['full_name']?.toString().toUpperCase() ??
                        "STUDENT NAME",
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
                    profile!['institution']?.toString().toUpperCase() ??
                        "PELAJAR",
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
