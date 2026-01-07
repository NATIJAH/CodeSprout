import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account_edit.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  final supabase = Supabase.instance.client;
  
  Map<String, dynamic>? accountData;
  Map<String, dynamic>? profileData;
  bool loading = true;
  String? errorMsg;

  // Modern color scheme
  final Color primaryColor = const Color(0xFF4F8E64);
  final Color accentColor = const Color(0xFF8BD7A2);
  final Color backgroundColor = const Color(0xFFF6F9F7);
  final Color dangerColor = const Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    fetchAccountData();
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
    if (!password.contains(RegExp(r'[@$!%*?&]'))) {
      return 'Kata laluan mesti mengandungi aksara khas (@\$!%*?&)';
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

  /// Validates account data before displaying
  Map<String, dynamic> _validateAccountData(Map<String, dynamic>? data) {
    if (data == null) return {};

    return {
      'user_id': data['user_id'],
      'bio': data['bio']?.toString().trim() ?? '',
      'date_of_birth': data['date_of_birth']?.toString().trim() ?? '',
      'gender': data['gender']?.toString().trim() ?? '',
      'country': data['country']?.toString().trim() ?? '',
      'city': data['city']?.toString().trim() ?? '',
      'email_notifications': data['email_notifications'] == true,
      'push_notifications': data['push_notifications'] == true,
      'sms_notifications': data['sms_notifications'] == true,
      'two_factor_enabled': data['two_factor_enabled'] == true,
    };
  }

  /// Validates profile data before displaying
  Map<String, dynamic> _validateProfileData(Map<String, dynamic>? data) {
    if (data == null) return {};

    return {
      'id': data['id'],
      'full_name': data['full_name']?.toString().trim() ?? '',
      'email': _isValidEmail(data['email']?.toString())
          ? data['email']
          : 'Invalid Email',
      'phone': data['phone']?.toString().trim() ?? '',
      'avatar_url': data['avatar_url']?.toString().isNotEmpty == true
          ? data['avatar_url']
          : null,
    };
  }

  /// Validates date string
  bool _isValidDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      
      // Date should not be in the future
      if (date.isAfter(now)) return false;
      
      // Date should not be unreasonably old (e.g., before 1900)
      if (date.year < 1900) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validates delete confirmation input
  bool _validateDeleteConfirmation(String input) {
    return input.trim().toUpperCase() == "PADAM";
  }

  // ============ DATA FETCHING WITH VALIDATION ============

  Future<void> fetchAccountData() async {
    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          loading = false;
          errorMsg = "Tiada pengguna log masuk";
        });
        return;
      }

      // Validate user ID
      if (user.id.isEmpty) {
        throw Exception('Invalid user ID');
      }

      // Fetch from account_settings table
      final accountSettings = await supabase
          .from("account_settings")
          .select()
          .eq("user_id", user.id)
          .maybeSingle();

      // Fetch from profile_student table to get name, phone, and image
      final profile = await supabase
          .from("profile_student")
          .select()
          .eq("id", user.id)
          .maybeSingle();

      // Validate and sanitize data
      final validatedAccount = _validateAccountData(
        accountSettings ?? {
          'user_id': user.id,
          'bio': '',
          'date_of_birth': '',
          'gender': '',
          'country': '',
          'city': '',
          'email_notifications': true,
          'push_notifications': true,
          'sms_notifications': false,
          'two_factor_enabled': false,
        },
      );

      final validatedProfile = _validateProfileData(profile);

      setState(() {
        accountData = validatedAccount;
        profileData = validatedProfile;
        loading = false;
        errorMsg = null;
      });
    } catch (e) {
      debugPrint('Account fetch error: $e');
      setState(() {
        loading = false;
        errorMsg = "Error loading account: ${e.toString()}";
      });
    }
  }

  // ============ DELETE ACCOUNT WITH VALIDATION ============

  Future<void> showDeleteAccountDialog() async {
    final confirmController = TextEditingController();
    final emailController = TextEditingController();
    final _deleteFormKey = GlobalKey<FormState>();
    bool isDeleting = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: dangerColor, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Padam Akaun",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ],
          ),
          content: Form(
            key: _deleteFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dangerColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tindakan ini TIDAK DAPAT DIBALIKKAN:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _dangerPoint("Padamkan semua data profil anda"),
                        _dangerPoint("Alih keluar semua entri dan siaran blog"),
                        _dangerPoint("Padamkan rancangan pembelajaran dan gred"),
                        _dangerPoint("Tutup akaun anda secara kekal"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Email verification
                  const Text(
                    'Sahkan email anda:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: supabase.auth.currentUser?.email ?? "Email anda",
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: Icon(Icons.email_outlined, color: dangerColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: dangerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: dangerColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email diperlukan';
                      }
                      if (!_isValidEmail(value)) {
                        return 'Format email tidak sah';
                      }
                      if (value.trim().toLowerCase() != 
                          supabase.auth.currentUser?.email?.toLowerCase()) {
                        return 'Email tidak sepadan dengan akaun anda';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),
                  
                  const Text(
                    'Taip "PADAM" untuk mengesahkan:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: confirmController,
                    decoration: InputDecoration(
                      hintText: "PADAM",
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: Icon(Icons.warning_outlined, color: dangerColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: dangerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: dangerColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      counterText: '${confirmController.text.length}/5',
                    ),
                    maxLength: 5,
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Sila masukkan pengesahan';
                      }
                      if (!_validateDeleteConfirmation(value)) {
                        return 'Mesti taip "PADAM" dengan huruf besar';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setDialogState(() {}); // Update counter
                    },
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, 
                          color: Colors.orange[900], 
                          size: 20
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Data akan dipadamkan dalam masa 5 saat selepas pengesahan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text("Batal", style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      // Validate form
                      if (_deleteFormKey.currentState?.validate() != true) {
                        return;
                      }

                      // Additional confirmation
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Pengesahan Akhir'),
                          content: const Text(
                            'Adakah anda benar-benar pasti mahu memadam akaun ini? '
                            'Tindakan ini tidak boleh dibalikkan.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Tidak'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: dangerColor,
                              ),
                              child: const Text('Ya, Padam'),
                            ),
                          ],
                        ),
                      );

                      if (shouldDelete != true) return;

                      setDialogState(() => isDeleting = true);
                      
                      Navigator.pop(context);
                      await deleteAccount();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Padam Akaun", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dangerPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cancel, color: dangerColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> deleteAccount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Tiada pengguna log masuk');
      }

      // Validate user ID
      if (user.id.isEmpty) {
        throw Exception('User ID tidak sah');
      }

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 20),
                  const Text(
                    'Memadam akaun...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sila tunggu...',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Count records to delete (for validation)
      int deletedRecords = 0;

      // Delete all related data with validation
      try {
        final blogEntries = await supabase
            .from('blog_entries')
            .delete()
            .eq('student_id', user.id)
            .select();
        deletedRecords += (blogEntries as List?)?.length ?? 0;
      } catch (e) {
        debugPrint('Error deleting blog entries: $e');
      }

      try {
        final forumPosts = await supabase
            .from('forum_posts')
            .delete()
            .eq('student_id', user.id)
            .select();
        deletedRecords += (forumPosts as List?)?.length ?? 0;
      } catch (e) {
        debugPrint('Error deleting forum posts: $e');
      }

      try {
        final forumDiscussions = await supabase
            .from('forum_discussions')
            .delete()
            .eq('student_id', user.id)
            .select();
        deletedRecords += (forumDiscussions as List?)?.length ?? 0;
      } catch (e) {
        debugPrint('Error deleting forum discussions: $e');
      }

      try {
        final learningPlans = await supabase
            .from('learning_plans')
            .delete()
            .eq('student_id', user.id)
            .select();
        deletedRecords += (learningPlans as List?)?.length ?? 0;
      } catch (e) {
        debugPrint('Error deleting learning plans: $e');
      }

      try {
        final browserSessions = await supabase
            .from('browser_sessions')
            .delete()
            .eq('student_id', user.id)
            .select();
        deletedRecords += (browserSessions as List?)?.length ?? 0;
      } catch (e) {
        debugPrint('Error deleting browser sessions: $e');
      }

      try {
        final grades = await supabase
            .from('grades')
            .delete()
            .eq('student_id', user.id)
            .select();
        deletedRecords += (grades as List?)?.length ?? 0;
      } catch (e) {
        debugPrint('Error deleting grades: $e');
      }

      try {
        await supabase
            .from('profile_student')
            .delete()
            .eq('id', user.id);
        deletedRecords++;
      } catch (e) {
        debugPrint('Error deleting profile: $e');
      }

      try {
        await supabase
            .from('account_settings')
            .delete()
            .eq('user_id', user.id);
        deletedRecords++;
      } catch (e) {
        debugPrint('Error deleting account settings: $e');
      }

      debugPrint('Total records deleted: $deletedRecords');

      // Sign out
      await supabase.auth.signOut();

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Navigate to login
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

      // Show success message
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Akaun berjaya dipadamkan ($deletedRecords rekod)'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Delete account error: $e');
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ralat memadam akaun: ${e.toString()}'),
          backgroundColor: dangerColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Cuba Lagi',
            textColor: Colors.white,
            onPressed: () => showDeleteAccountDialog(),
          ),
        ),
      );
    }
  }

  // ============ PASSWORD CHANGE WITH VALIDATION ============

  Future<void> changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final _passwordFormKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.lock_outline, color: primaryColor),
              ),
              const SizedBox(width: 12),
              const Text(
                "Tukar Kata Laluan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: Form(
            key: _passwordFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: "Kata laluan semasa",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.lock, color: primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setDialogState(
                            () => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kata laluan semasa diperlukan';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: "Kata laluan baru",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kata laluan mesti mengandungi:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 6),
                        _passwordRequirement('Min 8 aksara'),
                        _passwordRequirement('Huruf besar'),
                        _passwordRequirement('Huruf kecil'),
                        _passwordRequirement('Nombor'),
                        _passwordRequirement('Aksara khas (@\$!%*?&)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: "Sahkan kata laluan",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          Icon(Icons.check_circle_outline, color: primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm),
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
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text("Batal", style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate form
                if (_passwordFormKey.currentState?.validate() != true) {
                  return;
                }

                try {
                  await supabase.auth.updateUser(
                    UserAttributes(password: newPasswordController.text),
                  );

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Kata laluan berjaya ditukar! 🎉'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } catch (e) {
                  debugPrint('Password change error: $e');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ralat: ${e.toString()}'),
                      backgroundColor: dangerColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Tukar", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.blue[900]),
          ),
        ],
      ),
    );
  }

  // ============ UI BUILD ============

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (errorMsg != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: dangerColor),
              const SizedBox(height: 20),
              Text(
                errorMsg!,
                style: TextStyle(color: dangerColor, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchAccountData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: const Text('Cuba Semula'),
              ),
            ],
          ),
        ),
      );
    }

    if (accountData == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle_outlined,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 20),
              const Text("Tiada data akaun"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchAccountData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: const Text('Muat Semula'),
              ),
            ],
          ),
        ),
      );
    }

    final user = supabase.auth.currentUser;
    final username = profileData?['full_name']?.isNotEmpty == true
        ? profileData!['full_name']
        : user?.email?.split('@')[0] ?? 'User';
    final phone = profileData?['phone']?.isNotEmpty == true
        ? profileData!['phone']
        : '-';
    final imageUrl = profileData?['avatar_url'];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, accentColor],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          backgroundImage: imageUrl != null &&
                                  imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl == null || imageUrl.isEmpty
                              ? Text(
                                  username[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '✓ Aktif',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Info banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Nama, telefon dan gambar diambil dari profil anda. Untuk mengubahnya, sila Edit Profile.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Personal Information Section (Read-only from Profile)
                _buildModernSection(
                  title: "Maklumat Dari Profil",
                  icon: Icons.person_outline,
                  children: [
                    _modernInfoTile(
                      icon: Icons.badge_outlined,
                      label: "Nama Pengguna",
                      value: username,
                      isReadOnly: true,
                    ),
                    _modernInfoTile(
                      icon: Icons.email_outlined,
                      label: "Email",
                      value: user?.email ?? '-',
                      isReadOnly: true,
                    ),
                    _modernInfoTile(
                      icon: Icons.phone_outlined,
                      label: "Nombor Telefon",
                      value: phone,
                      isReadOnly: true,
                    ),
                  ],
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 14, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          "Tetap",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Personal Details Section (Editable)
                _buildModernSection(
                  title: "Butiran Peribadi",
                  icon: Icons.edit_outlined,
                  children: [
                    _modernInfoTile(
                      icon: Icons.article_outlined,
                      label: "Bio",
                      value: accountData!['bio']?.isEmpty ?? true
                          ? 'Belum ditetapkan'
                          : accountData!['bio'],
                    ),
                    _modernInfoTile(
                      icon: Icons.cake_outlined,
                      label: "Tarikh Lahir",
                      value: _isValidDate(accountData!['date_of_birth'])
                          ? _formatDate(accountData!['date_of_birth'])
                          : 'Belum ditetapkan',
                    ),
                    _modernInfoTile(
                      icon: Icons.wc_outlined,
                      label: "Jantina",
                      value: accountData!['gender'] ?? 'Belum ditetapkan',
                    ),
                    _modernInfoTile(
                      icon: Icons.location_city_outlined,
                      label: "Bandar",
                      value: accountData!['city'] ?? 'Belum ditetapkan',
                    ),
                    _modernInfoTile(
                      icon: Icons.flag_outlined,
                      label: "Negara",
                      value: accountData!['country'] ?? 'Belum ditetapkan',
                    ),
                  ],
                  actionButton: _buildEditButton(),
                ),

                // Account Information Section
                _buildModernSection(
                  title: "Maklumat Akaun",
                  icon: Icons.security_outlined,
                  children: [
                    _modernInfoTile(
                      icon: Icons.fingerprint,
                      label: "ID Pengguna",
                      value: user?.id.substring(0, 20) ?? '-',
                      isSmall: true,
                    ),
                    _modernInfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: "Tarikh Cipta",
                      value: _formatDate(user?.createdAt),
                    ),
                    _modernInfoTile(
                      icon: Icons.update_outlined,
                      label: "Kemas Kini Terakhir",
                      value: _formatDate(user?.updatedAt),
                    ),
                  ],
                ),

                // Security Section
                _buildModernSection(
                  title: "Keselamatan & Privasi",
                  icon: Icons.shield_outlined,
                  children: [
                    _modernActionTile(
                      icon: Icons.lock_outline,
                      label: "Tukar Kata Laluan",
                      onTap: changePassword,
                      color: primaryColor,
                    ),
                    _modernSwitchTile(
                      icon: Icons.verified_user_outlined,
                      label: "Pengesahan Dua Faktor",
                      value: accountData!['two_factor_enabled'] ?? false,
                      onChanged: (value) async {
                        try {
                          await supabase.from('account_settings').upsert({
                            'user_id': user?.id,
                            'two_factor_enabled': value,
                          });
                          await fetchAccountData();
                        } catch (e) {
                          debugPrint('2FA toggle error: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ralat: ${e.toString()}'),
                                backgroundColor: dangerColor,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),

                // Notifications Section
                _buildModernSection(
                  title: "Pemberitahuan",
                  icon: Icons.notifications_outlined,
                  children: [
                    _modernSwitchTile(
                      icon: Icons.email_outlined,
                      label: "Pemberitahuan Email",
                      value: accountData!['email_notifications'] ?? true,
                      onChanged: (value) async {
                        try {
                          await supabase.from('account_settings').upsert({
                            'user_id': user?.id,
                            'email_notifications': value,
                          });
                          await fetchAccountData();
                        } catch (e) {
                          debugPrint('Email notification toggle error: $e');
                        }
                      },
                    ),
                    _modernSwitchTile(
                      icon: Icons.phone_android_outlined,
                      label: "Pemberitahuan Push",
                      value: accountData!['push_notifications'] ?? true,
                      onChanged: (value) async {
                        try {
                          await supabase.from('account_settings').upsert({
                            'user_id': user?.id,
                            'push_notifications': value,
                          });
                          await fetchAccountData();
                        } catch (e) {
                          debugPrint('Push notification toggle error: $e');
                        }
                      },
                    ),
                    _modernSwitchTile(
                      icon: Icons.sms_outlined,
                      label: "Pemberitahuan SMS",
                      value: accountData!['sms_notifications'] ?? false,
                      onChanged: (value) async {
                        try {
                          await supabase.from('account_settings').upsert({
                            'user_id': user?.id,
                            'sms_notifications': value,
                          });
                          await fetchAccountData();
                        } catch (e) {
                          debugPrint('SMS notification toggle error: $e');
                        }
                      },
                    ),
                  ],
                ),

                // Danger Zone
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          dangerColor.withOpacity(0.1),
                          dangerColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: dangerColor.withOpacity(0.3), width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: dangerColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.warning_rounded,
                                  color: dangerColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Zon Bahaya",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Sebaik sahaja anda memadamkan akaun anda, tiada cara untuk memulihkannya. Semua data anda akan hilang secara kekal.",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: showDeleteAccountDialog,
                              icon: const Icon(Icons.delete_forever, size: 22),
                              label: const Text(
                                "Padam Akaun Secara Kekal",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: dangerColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? actionButton,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (actionButton != null) actionButton,
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UpdateAccountSettingsPage(),
            ),
          );
          fetchAccountData();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                "Edit",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernInfoTile({
    required IconData icon,
    required String label,
    required String value,
    bool isSmall = false,
    bool isReadOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isReadOnly
                  ? Colors.grey[200]
                  : accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isReadOnly ? Colors.grey[600] : primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isReadOnly) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.lock_outline,
                          size: 12, color: Colors.grey[500]),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 15,
                    color: isReadOnly ? Colors.grey[600] : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
            activeTrackColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _modernActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || !_isValidDate(dateStr)) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '-';
    }
  }
}
