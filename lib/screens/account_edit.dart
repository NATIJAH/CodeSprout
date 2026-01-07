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
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
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
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Untuk mengubah nama, telefon atau gambar profil, sila gunakan halaman Edit Profile.",
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
                    const SizedBox(height: 24),

                    // Personal Information Section
                    _buildSectionHeader(
                      icon: Icons.person_outline,
                      title: "Maklumat Peribadi",
                    ),
                    const SizedBox(height: 16),

                    _buildModernInputField(
                      controller: bioController,
                      label: "Bio",
                      hint: "Tulis sesuatu tentang diri anda (min. 10 aksara)",
                      icon: Icons.article_outlined,
                      maxLines: 4,
                      validator: validateBio,
                      counterText: '${bioController.text.length}/500',
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth Selector
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: validateDateOfBirth() != null 
                                ? dangerColor 
                                : Colors.transparent,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.cake_outlined,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Tarikh Lahir",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    selectedDate != null
                                        ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                        : "Pilih tarikh lahir (min. umur 13 tahun)",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: selectedDate != null 
                                          ? Colors.black87 
                                          : Colors.grey[400],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.calendar_today, color: Colors.grey[400], size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gender Selector
                    _buildDropdownField(
                      label: "Jantina",
                      icon: Icons.wc_outlined,
                      value: selectedGender,
                      items: const ['Lelaki', 'Perempuan', 'Lain-lain'],
                      hint: "Pilih jantina",
                      onChanged: (value) => setState(() => selectedGender = value),
                    ),

                    const SizedBox(height: 32),

                    // Location Section
                    _buildSectionHeader(
                      icon: Icons.location_on_outlined,
                      title: "Lokasi",
                    ),
                    const SizedBox(height: 16),

                    _buildModernInputField(
                      controller: cityController,
                      label: "Bandar",
                      hint: "Contoh: Kuala Lumpur (min. 2 aksara)",
                      icon: Icons.location_city_outlined,
                      validator: validateCity,
                      counterText: '${cityController.text.length}/50',
                    ),
                    const SizedBox(height: 16),

                    _buildModernInputField(
                      controller: countryController,
                      label: "Negara",
                      hint: "Contoh: Malaysia (min. 2 aksara)",
                      icon: Icons.flag_outlined,
                      validator: validateCountry,
                      counterText: '${countryController.text.length}/50',
                    ),

                    const SizedBox(height: 32),

                    // Validation Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Panduan Pengisian",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _validationPoint("Bio: 10-500 aksara (opsional)"),
                          _validationPoint("Tarikh lahir: Min. umur 13 tahun (opsional)"),
                          _validationPoint("Bandar/Negara: 2-50 aksara, huruf sahaja (opsional)"),
                          _validationPoint("Jantina: Pilih dari senarai (opsional)"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Menyimpan...",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check_circle_outline, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    "Simpan Perubahan",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Batal",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _validationPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.amber[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber[900],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildModernInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
    String? Function(String?)? validator,
    String? counterText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                if (required) ...[
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ],
                if (counterText != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    counterText,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              validator: validator,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (value) {
                setState(() {}); // Update counter
              },
              style: const TextStyle(
                fontSize: 15,
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
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: DropdownButtonFormField<String>(
              value: value,
              hint: hint != null ? Text(hint) : null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              icon: Icon(Icons.arrow_drop_down, color: primaryColor),
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
    );
  }
}
