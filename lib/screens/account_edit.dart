import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateAccountSettingsPage extends StatefulWidget {
  const UpdateAccountSettingsPage({super.key});

  @override
  State<UpdateAccountSettingsPage> createState() => _UpdateAccountSettingsPageState();
}

class _UpdateAccountSettingsPageState extends State<UpdateAccountSettingsPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final bioController = TextEditingController();
  final cityController = TextEditingController();
  final countryController = TextEditingController();

  String? selectedGender;
  DateTime? selectedDate;

  bool isLoading = true;
  bool isSaving = false;
  String? userId;

  // Modern color scheme
  final Color primaryColor = const Color(0xFF4F8E64);
  final Color accentColor = const Color(0xFF8BD7A2);
  final Color backgroundColor = const Color(0xFFF6F9F7);
  final Color dangerColor = const Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    bioController.dispose();
    cityController.dispose();
    countryController.dispose();
    super.dispose();
  }

  // Validation Methods
  String? validateBio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Bio is optional
    }
    if (value.trim().length < 10) {
      return 'Bio mestilah sekurang-kurangnya 10 aksara';
    }
    if (value.trim().length > 500) {
      return 'Bio tidak boleh melebihi 500 aksara';
    }
    return null;
  }

  String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // City is optional
    }
    if (value.trim().length < 2) {
      return 'Nama bandar mestilah sekurang-kurangnya 2 aksara';
    }
    if (value.trim().length > 50) {
      return 'Nama bandar tidak boleh melebihi 50 aksara';
    }
    // Check if contains only letters, spaces, and hyphens
    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value.trim())) {
      return 'Nama bandar hanya boleh mengandungi huruf, ruang dan tanda tolak';
    }
    return null;
  }

  String? validateCountry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Country is optional
    }
    if (value.trim().length < 2) {
      return 'Nama negara mestilah sekurang-kurangnya 2 aksara';
    }
    if (value.trim().length > 50) {
      return 'Nama negara tidak boleh melebihi 50 aksara';
    }
    // Check if contains only letters, spaces, and hyphens
    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value.trim())) {
      return 'Nama negara hanya boleh mengandungi huruf, ruang dan tanda tolak';
    }
    return null;
  }

  String? validateDateOfBirth() {
    if (selectedDate == null) {
      return null; // Date is optional
    }
    
    final now = DateTime.now();
    final age = now.year - selectedDate!.year;
    
    // Check if user is at least 13 years old
    if (age < 13) {
      return 'Anda mestilah sekurang-kurangnya 13 tahun';
    }
    
    // Check if date is not in the future
    if (selectedDate!.isAfter(now)) {
      return 'Tarikh lahir tidak boleh pada masa hadapan';
    }
    
    // Check if user is not too old (reasonable limit)
    if (age > 120) {
      return 'Sila masukkan tarikh lahir yang sah';
    }
    
    return null;
  }

  bool validateAllFields() {
    final bioError = validateBio(bioController.text);
    final cityError = validateCity(cityController.text);
    final countryError = validateCountry(countryController.text);
    final dateError = validateDateOfBirth();

    if (bioError != null) {
      _showSnackBar(bioError, isError: true);
      return false;
    }
    if (cityError != null) {
      _showSnackBar(cityError, isError: true);
      return false;
    }
    if (countryError != null) {
      _showSnackBar(countryError, isError: true);
      return false;
    }
    if (dateError != null) {
      _showSnackBar(dateError, isError: true);
      return false;
    }

    return true;
  }

  Future<void> loadData() async {
    try {
      final user = supabase.auth.currentUser;
      userId = user?.id;

      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      // Load account settings
      final accountSettings = await supabase
          .from('account_settings')
          .select()
          .eq('user_id', userId!)
          .maybeSingle();

      if (accountSettings != null) {
        bioController.text = accountSettings['bio'] ?? '';
        cityController.text = accountSettings['city'] ?? '';
        countryController.text = accountSettings['country'] ?? '';
        selectedGender = accountSettings['gender'];
        
        if (accountSettings['date_of_birth'] != null) {
          try {
            selectedDate = DateTime.parse(accountSettings['date_of_birth']);
          } catch (e) {
            print('Error parsing date: $e');
          }
        }
      }
    } catch (e) {
      print("Error loading data: $e");
      _showSnackBar("Ralat memuatkan data: $e", isError: true);
    }

    setState(() => isLoading = false);
  }

  Future<void> saveData() async {
    if (userId == null) return;

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validations
    if (!validateAllFields()) {
      return;
    }

    setState(() => isSaving = true);

    try {
      // Get username from profile_student or profile_teacher
      String? usernameFromProfile;
      try {
        final profileData = await supabase
            .from('profile_student')
            .select('full_name')
            .eq('id', userId!)
            .maybeSingle();
        
        if (profileData != null) {
          usernameFromProfile = profileData['full_name'];
        } else {
          // Try teacher profile
          final teacherProfile = await supabase
              .from('profile_teacher')
              .select('full_name')
              .eq('id', userId!)
              .maybeSingle();
          usernameFromProfile = teacherProfile?['full_name'];
        }
      } catch (e) {
        print("Could not get profile name: $e");
      }

      // Update account_settings with username from profile
      await supabase.from('account_settings').upsert({
        'user_id': userId,
        'username': usernameFromProfile ?? supabase.auth.currentUser?.email?.split('@')[0] ?? 'User',
        'bio': bioController.text.trim().isEmpty ? null : bioController.text.trim(),
        'date_of_birth': selectedDate?.toIso8601String(),
        'gender': selectedGender,
        'city': cityController.text.trim().isEmpty ? null : cityController.text.trim(),
        'country': countryController.text.trim().isEmpty ? null : countryController.text.trim(),
      }, onConflict: 'user_id');

      if (!mounted) return;

      _showSnackBar("Profil berjaya dikemas kini! 🎉", isError: false);

      // Wait a bit for user to see the success message
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      Navigator.pop(context, true);

    } catch (e) {
      print("Error saving data: $e");
      _showSnackBar("Gagal mengemaskini: $e", isError: true);
    }

    if (mounted) {
      setState(() => isSaving = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? dangerColor : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      // Validate date after selection
      final dateError = validateDateOfBirth();
      if (dateError != null) {
        _showSnackBar(dateError, isError: true);
        setState(() => selectedDate = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Edit Tetapan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info banner
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Untuk mengubah nama, telefon atau gambar, gunakan Edit Profile.",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[900],
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Bio Field
                            _buildCompactInputField(
                              controller: bioController,
                              label: "Bio",
                              hint: "Tulis tentang diri anda (10-500 aksara)",
                              icon: Icons.article_outlined,
                              maxLines: 3,
                              validator: validateBio,
                              counterText: '${bioController.text.length}/500',
                            ),
                            const SizedBox(height: 16),

                            // Date of Birth Selector
                            GestureDetector(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: validateDateOfBirth() != null 
                                        ? dangerColor 
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.cake_outlined, color: primaryColor, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Tarikh Lahir",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            selectedDate != null
                                                ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                                : "Pilih tarikh (min. 13 tahun)",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: selectedDate != null 
                                                  ? Colors.black87 
                                                  : Colors.grey[400],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.calendar_today, color: Colors.grey[400], size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Gender Selector
                            _buildCompactDropdownField(
                              label: "Jantina",
                              icon: Icons.wc_outlined,
                              value: selectedGender,
                              items: const ['Lelaki', 'Perempuan', 'Lain-lain'],
                              hint: "Pilih jantina",
                              onChanged: (value) => setState(() => selectedGender = value),
                            ),
                            const SizedBox(height: 16),

                            // City Field
                            _buildCompactInputField(
                              controller: cityController,
                              label: "Bandar",
                              hint: "Contoh: Kuala Lumpur",
                              icon: Icons.location_city_outlined,
                              validator: validateCity,
                              counterText: '${cityController.text.length}/50',
                            ),
                            const SizedBox(height: 16),

                            // Country Field
                            _buildCompactInputField(
                              controller: countryController,
                              label: "Negara",
                              hint: "Contoh: Malaysia",
                              icon: Icons.flag_outlined,
                              validator: validateCountry,
                              counterText: '${countryController.text.length}/50',
                            ),
                            const SizedBox(height: 20),

                            // Validation Guide
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber[200]!, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Panduan",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _compactValidationPoint("Bio: 10-500 aksara"),
                                  _compactValidationPoint("Umur: Min. 13 tahun"),
                                  _compactValidationPoint("Lokasi: 2-50 aksara, huruf sahaja"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Footer Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Simpan",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Widget _compactValidationPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.amber[700], size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber[900],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? counterText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Icon(icon, color: primaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                if (counterText != null)
                  Text(
                    counterText,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              validator: validator,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (value) => setState(() {}),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                errorStyle: TextStyle(
                  color: dangerColor,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    String? hint,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: value,
                hint: hint != null ? Text(hint, style: const TextStyle(fontSize: 14)) : null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                icon: Icon(Icons.arrow_drop_down, color: primaryColor, size: 20),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
