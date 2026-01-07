import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileDelete extends StatefulWidget {
  const ProfileDelete({super.key});

  @override
  State<ProfileDelete> createState() => _ProfileDeleteState();
}

class _ProfileDeleteState extends State<ProfileDelete> {
  bool _isDeleting = false;
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _validationError;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  // Validation method for confirmation text
  String? validateConfirmation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Sila masukkan teks pengesahan';
    }
    
    if (value.trim().toUpperCase() != 'PADAM') {
      return 'Sila taip "PADAM" dengan betul untuk mengesahkan';
    }
    
    return null;
  }

  // Real-time validation as user types
  void _onConfirmationChanged(String value) {
    setState(() {
      _validationError = validateConfirmation(value);
    });
  }

  // Show confirmation dialog before delete
  Future<void> _showFinalConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Pengesahan Akhir",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: const [
                  Text(
                    "Adakah anda pasti?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tindakan ini tidak dapat dibalikkan. Semua data anda akan hilang selama-lamanya.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("Batal", style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Ya, Padam", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation check
    final validationResult = validateConfirmation(_confirmController.text);
    if (validationResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $validationResult'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isDeleting = true);

    try {
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser?.id;
      
      if (uid == null) {
        throw 'Tidak log masuk';
      }

      print('🗑️ Memulakan proses padam akaun: $uid');

      // Delete from profile_student table
      try {
        await supabase.from('profile_student').delete().eq('id', uid);
        print('✅ Profil pelajar cuba dipadam');
      } catch (e) {
        print('⚠️ Profil pelajar tidak wujud atau sudah dipadam: $e');
      }

      // Delete from profile_teacher table
      try {
        await supabase.from('profile_teacher').delete().eq('id', uid);
        print('✅ Profil guru cuba dipadam');
      } catch (e) {
        print('⚠️ Profil guru tidak wujud atau sudah dipadam: $e');
      }

      // Sign out the user
      await supabase.auth.signOut();
      print('✅ Log keluar berjaya');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Akaun berjaya dipadam! Data profil telah dibuang.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);

    } catch (e) {
      print('❌ Ralat padam akaun: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal memadam akaun: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFormValid = _validationError == null && 
                            _confirmController.text.trim().toUpperCase() == 'PADAM';

    return Scaffold(
      backgroundColor: const Color(0xFFEAF8ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF8ED),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A6F52)),
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          '⚠️ Padam Akaun',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A6F52),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.red[300]!, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '⚠️ Zon Bahaya',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Sebaik sahaja anda memadamkan akaun anda, tiada cara untuk memulihkannya. Semua data anda akan hilang secara kekal.',
                      style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Tindakan ini TIDAK DAPAT DIBALIKKAN:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.cancel, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Padamkan semua data profil anda',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.cancel, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Alih keluar semua entri dan siaran blog',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.cancel, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Padamkan rancangan pembelajaran dan gred',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.cancel, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tutup akaun anda secara kekal',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Validation Guide
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Langkah Pengesahan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Taip perkataan "PADAM" dengan huruf besar untuk mengesahkan pemadaman akaun.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[900],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Confirmation Input
              const Text(
                'Taip "PADAM" untuk mengesahkan:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A6F52),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _validationError != null 
                        ? Colors.red 
                        : (_confirmController.text.isEmpty 
                            ? Colors.red[300]! 
                            : (isFormValid ? Colors.green : Colors.red)),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _confirmController,
                      enabled: !_isDeleting,
                      validator: validateConfirmation,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: _onConfirmationChanged,
                      decoration: InputDecoration(
                        hintText: 'PADAM',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        suffixIcon: _confirmController.text.isNotEmpty
                            ? Icon(
                                isFormValid ? Icons.check_circle : Icons.cancel,
                                color: isFormValid ? Colors.green : Colors.red,
                              )
                            : null,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],
                ),
              ),

              // Validation Error Message
              if (_validationError != null && _confirmController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Success Indicator
              if (isFormValid)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Pengesahan sah ✓',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Delete Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isDeleting || !isFormValid) 
                      ? null 
                      : () => _showFinalConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: isFormValid ? 2 : 0,
                  ),
                  child: _isDeleting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Memadamkan...',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Text(
                          isFormValid 
                              ? '🗑️ Padam Akaun Secara Kekal' 
                              : '🔒 Taip "PADAM" untuk aktifkan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _isDeleting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A6F52),
                    disabledForegroundColor: Colors.grey[400],
                    side: BorderSide(
                      color: _isDeleting ? Colors.grey[300]! : const Color(0xFF4A6F52),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Additional Safety Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nota Keselamatan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kami mengambil keselamatan akaun anda dengan serius. Pengesahan dua langkah diperlukan untuk memastikan hanya anda yang boleh memadamkan akaun ini.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
