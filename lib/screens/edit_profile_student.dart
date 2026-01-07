import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditStudentProfilePage extends StatefulWidget {
  const EditStudentProfilePage({super.key});

  @override
  State<EditStudentProfilePage> createState() => _EditStudentProfilePageState();
}

class _EditStudentProfilePageState extends State<EditStudentProfilePage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();
  final studentClassController = TextEditingController();
  final institutionController = TextEditingController();

  File? newImage;
  String? imageUrl;
  bool isLoading = true;
  bool isSaving = false;
  
  String selectedState = 'Johor';
  String selectedTimezone = 'Asia/Kuala_Lumpur';

  final Color accentColor = const Color(0xFF0066CC);
  final Color backgroundColor = const Color(0xFFF5F5F5);

  // Malaysian states with their corresponding timezones
  final Map<String, String> stateTimezones = {
    'Johor': 'Asia/Kuala_Lumpur',
    'Kedah': 'Asia/Kuala_Lumpur',
    'Kelantan': 'Asia/Kuala_Lumpur',
    'Melaka': 'Asia/Kuala_Lumpur',
    'Negeri Sembilan': 'Asia/Kuala_Lumpur',
    'Pahang': 'Asia/Kuala_Lumpur',
    'Penang': 'Asia/Kuala_Lumpur',
    'Perak': 'Asia/Kuala_Lumpur',
    'Perlis': 'Asia/Kuala_Lumpur',
    'Sabah': 'Asia/Kuching',
    'Sarawak': 'Asia/Kuching',
    'Selangor': 'Asia/Kuala_Lumpur',
    'Terengganu': 'Asia/Kuala_Lumpur',
    'Kuala Lumpur': 'Asia/Kuala_Lumpur',
    'Labuan': 'Asia/Kuching',
    'Putrajaya': 'Asia/Kuala_Lumpur',
  };

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ============ DATA VALIDATION HELPERS ============

  /// Validates if a string is a valid email format
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email diperlukan';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak sah';
    }
    return null;
  }

  /// Validates if a string is a valid phone number (Malaysian format)
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nombor telefon diperlukan';
    }
    final cleanPhone = value.replaceAll(RegExp(r'[\s-]'), '');
    final phoneRegex = RegExp(r'^(\+?6?01)[0-46-9][0-9]{7,8}$');
    
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Nombor telefon tidak sah (contoh: 012-3456789)';
    }
    return null;
  }

  /// Validates full name
  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama penuh diperlukan';
    }
    if (value.trim().length < 3) {
      return 'Nama terlalu pendek (minimum 3 aksara)';
    }
    if (value.trim().length > 100) {
      return 'Nama terlalu panjang (maksimum 100 aksara)';
    }
    // Only allow letters, spaces, and common name characters
    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(value.trim())) {
      return 'Nama hanya boleh mengandungi huruf dan ruang';
    }
    return null;
  }

  /// Validates age
  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Umur diperlukan';
    }
    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Umur mesti nombor';
    }
    if (age < 5 || age > 100) {
      return 'Umur mesti antara 5 hingga 100 tahun';
    }
    return null;
  }

  /// Validates class name
  String? _validateClass(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kelas diperlukan';
    }
    if (value.trim().length < 1) {
      return 'Kelas terlalu pendek';
    }
    if (value.trim().length > 50) {
      return 'Kelas terlalu panjang (maksimum 50 aksara)';
    }
    return null;
  }

  /// Validates institution name
  String? _validateInstitution(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Institusi diperlukan';
    }
    if (value.trim().length < 5) {
      return 'Nama institusi terlalu pendek (minimum 5 aksara)';
    }
    if (value.trim().length > 200) {
      return 'Nama institusi terlalu panjang (maksimum 200 aksara)';
    }
    return null;
  }

  /// Sanitizes user input to prevent XSS and injection
  String _sanitizeInput(String? input) {
    if (input == null) return '';
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[<>{}[\]\\]'), ''); // Remove dangerous characters
  }

  /// Validates image file
  bool _validateImageFile(File file) {
    try {
      // Check file size (max 5MB)
      final fileSize = file.lengthSync();
      if (fileSize > 5 * 1024 * 1024) {
        _showError('Saiz gambar terlalu besar (maksimum 5MB)');
        return false;
      }

      // Check file extension
      final extension = file.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        _showError('Format gambar tidak disokong (gunakan jpg, png, atau gif)');
        return false;
      }

      return true;
    } catch (e) {
      _showError('Ralat mengesahkan gambar');
      return false;
    }
  }

  /// Formats phone number for display
  String _formatPhoneNumber(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s-]'), '');
    if (clean.length >= 10) {
      // Format as 01X-XXXXXXX
      return '${clean.substring(0, 3)}-${clean.substring(3)}';
    }
    return clean;
  }

  // ============ DATA LOADING WITH VALIDATION ============

  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showError('Tiada pengguna log masuk');
        if (mounted) Navigator.pop(context);
        return;
      }

      final data = await supabase
          .from('profile_student')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        // Validate and sanitize data before populating fields
        fullNameController.text = _sanitizeInput(data['full_name']) ?? '';
        emailController.text = _sanitizeInput(data['email']) ?? '';
        phoneController.text = _sanitizeInput(data['phone']) ?? '';
        
        // Validate age data
        final ageValue = data['age'];
        if (ageValue != null) {
          final age = int.tryParse(ageValue.toString());
          if (age != null && age >= 5 && age <= 100) {
            ageController.text = age.toString();
          }
        }
        
        studentClassController.text = _sanitizeInput(data['class']) ?? '';
        institutionController.text = _sanitizeInput(data['institution']) ?? 
            'PELAJAR UNIVERSITI TEKNOLOGI MALAYSIA';
        
        // Validate state
        final stateValue = data['state']?.toString();
        if (stateValue != null && stateTimezones.containsKey(stateValue)) {
          selectedState = stateValue;
        } else {
          selectedState = 'Johor';
        }
        
        // Validate timezone
        final timezoneValue = data['timezone']?.toString();
        if (timezoneValue != null && 
            (timezoneValue == 'Asia/Kuala_Lumpur' || timezoneValue == 'Asia/Kuching')) {
          selectedTimezone = timezoneValue;
        } else {
          selectedTimezone = stateTimezones[selectedState]!;
        }
        
        // Validate avatar URL
        final avatarUrl = data['avatar_url']?.toString();
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
            imageUrl = avatarUrl;
          }
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Profile load error: $e');
      _showError('Ralat memuatkan profil: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (picked != null) {
        final file = File(picked.path);
        
        // Validate image file
        if (_validateImageFile(file)) {
          setState(() => newImage = file);
        }
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      _showError('Ralat memilih gambar: $e');
    }
  }

  Future<String?> uploadProfileImage(File file) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User ID tidak sah');
      }

      final bytes = await file.readAsBytes();
      
      // Validate file size again
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('Saiz fail terlalu besar');
      }

      final String path = "profiles/$userId-${DateTime.now().millisecondsSinceEpoch}.jpg";

      await supabase.storage.from('profile-images').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          contentType: "image/jpeg",
          upsert: true,
        ),
      );

      final url = supabase.storage.from('profile-images').getPublicUrl(path);
      
      // Validate returned URL
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        throw Exception('URL gambar tidak sah');
      }

      return url;
    } catch (e) {
      debugPrint('Image upload error: $e');
      _showError('Ralat memuat naik gambar: $e');
      return null;
    }
  }

  Future<void> saveProfile() async {
    // Validate form
    if (_formKey.currentState?.validate() != true) {
      _showError('Sila betulkan ralat dalam borang');
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      _showError('Tiada pengguna log masuk');
      return;
    }

    setState(() => isSaving = true);

    try {
      String? finalImage = imageUrl;

      // Upload new image if selected
      if (newImage != null) {
        final uploadedUrl = await uploadProfileImage(newImage!);
        if (uploadedUrl != null) {
          finalImage = uploadedUrl;
        } else {
          // Upload failed, but continue with old image
          _showError('Gagal memuat naik gambar, tetapi menyimpan profil lain');
        }
      }

      // Sanitize all inputs before saving
      final sanitizedData = {
        'id': user.id,
        'full_name': _sanitizeInput(fullNameController.text),
        'email': _sanitizeInput(emailController.text),
        'phone': _sanitizeInput(phoneController.text),
        'age': int.tryParse(ageController.text.trim()) ?? 0,
        'class': _sanitizeInput(studentClassController.text),
        'institution': _sanitizeInput(institutionController.text),
        'state': selectedState,
        'timezone': selectedTimezone,
        'avatar_url': finalImage,
      };

      // Additional validation before upsert
      if (sanitizedData['full_name'].toString().isEmpty) {
        throw Exception('Nama penuh tidak boleh kosong');
      }
      if (sanitizedData['email'].toString().isEmpty) {
        throw Exception('Email tidak boleh kosong');
      }

      await supabase.from('profile_student').upsert(sanitizedData);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berjaya dikemas kini!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Return success result
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Profile save error: $e');
      if (!mounted) return;
      
      _showError('Ralat menyimpan profil: $e');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============ UI BUILD - DIALOG BASED ============

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Edit Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Picture
                            Center(
                              child: GestureDetector(
                                onTap: pickImage,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: accentColor,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.grey[300],
                                        backgroundImage: newImage != null
                                            ? FileImage(newImage!)
                                            : (imageUrl != null &&
                                                    imageUrl!.isNotEmpty
                                                ? NetworkImage(imageUrl!)
                                                : null),
                                        child: newImage == null &&
                                                (imageUrl == null ||
                                                    imageUrl!.isEmpty)
                                            ? Icon(Icons.person,
                                                size: 50,
                                                color: Colors.grey[600])
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: accentColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Form Fields
                            _buildValidatedInput(
                              "Nama Penuh",
                              fullNameController,
                              Icons.person_outline,
                              validator: _validateFullName,
                            ),

                            _buildValidatedInput(
                              "Email",
                              emailController,
                              Icons.email_outlined,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            _buildValidatedInput(
                              "Nombor Telefon",
                              phoneController,
                              Icons.phone_outlined,
                              validator: _validatePhone,
                              keyboardType: TextInputType.phone,
                            ),

                            _buildValidatedInput(
                              "Umur",
                              ageController,
                              Icons.cake_outlined,
                              validator: _validateAge,
                              keyboardType: TextInputType.number,
                            ),

                            _buildValidatedInput(
                              "Kelas",
                              studentClassController,
                              Icons.school_outlined,
                              validator: _validateClass,
                            ),

                            _buildValidatedInput(
                              "Institusi",
                              institutionController,
                              Icons.school,
                              validator: _validateInstitution,
                              maxLines: 2,
                            ),

                            // State Dropdown
                            const SizedBox(height: 8),
                            const Text(
                              "Negeri",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedState,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.location_on_outlined,
                                    size: 20),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: accentColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: stateTimezones.keys.map((String state) {
                                return DropdownMenuItem<String>(
                                  value: state,
                                  child: Text(
                                    state,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedState = newValue;
                                    selectedTimezone = stateTimezones[newValue]!;
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            // Timezone Display (Read-only)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_outlined,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Zon Masa',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          selectedTimezone,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
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
            ),

            // Footer Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[400]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Simpan",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
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

  Widget _buildValidatedInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20),
              hintText: "Masukkan $label",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: accentColor, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              errorStyle: const TextStyle(fontSize: 11),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    ageController.dispose();
    studentClassController.dispose();
    institutionController.dispose();
    super.dispose();
  }
}
