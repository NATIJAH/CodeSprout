import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;
import '../models/teaching_material.dart';
import '../services/supabase_service.dart';

class MaterialsProvider with ChangeNotifier {
  List<TeachingMaterial> _materials = [];
  List<TeachingMaterial> _filteredMaterials = [];
  TeachingMaterial? _selectedMaterial;
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Getters
  List<TeachingMaterial> get materials => _filteredMaterials;
  TeachingMaterial? get selectedMaterial => _selectedMaterial;
  PlatformFile? get selectedFile => _selectedFile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Set selected material
  void setSelectedMaterial(TeachingMaterial material) {
    _selectedMaterial = material;
    notifyListeners();
  }

  // Clear selected material
  void clearSelectedMaterial() {
    _selectedMaterial = null;
    notifyListeners();
  }

  // Load teacher's materials
  Future<void> loadTeacherMaterials() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final teacherId = SupabaseService.userId;
      if (teacherId.isEmpty) {
        throw Exception('User not logged in');
      }

      _materials = await SupabaseService.getTeacherMaterials(teacherId);
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Failed to load materials: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load published materials for students
  Future<void> loadPublishedMaterials() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _materials = await SupabaseService.getPublishedMaterials();
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Failed to load materials: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Pick file from device
  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'jpg', 'jpeg', 'png', 'gif', 'mp4', 'doc', 'docx',
          'xls', 'xlsx', 'ppt', 'pptx'
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        _selectedFile = result.files.first;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick file: $e';
      notifyListeners();
    }
  }

  // Clear selected file
  void clearSelectedFile() {
    _selectedFile = null;
    notifyListeners();
  }

  // Upload material
  Future<bool> uploadMaterial({
    required String title,
    required String description,
    required String className,
    required List<String> tags,
  }) async {
    if (_selectedFile == null) {
      _errorMessage = 'Please select a file first';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      if (_selectedFile!.bytes == null) {
        throw Exception(
            'File bytes not available. Please try selecting the file again.');
      }

      final fileBytes = _selectedFile!.bytes!;
      final fileName = _selectedFile!.name;

      final downloadUrl = await SupabaseService.uploadFile(
        fileBytes: fileBytes,
        fileName: fileName,
        teacherId: user.id,
        className: className,
      );

      // Determine file type
      final ext = fileName.toLowerCase().split('.').last;
      String fileType = 'other';
      if (ext == 'pdf') fileType = 'pdf';
      else if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) fileType = 'image';
      else if (ext == 'mp4') fileType = 'video';
      else if (['doc', 'docx'].contains(ext)) fileType = 'word';
      else if (['xls', 'xlsx'].contains(ext)) fileType = 'excel';
      else if (['ppt', 'pptx'].contains(ext)) fileType = 'powerpoint';

      final material = TeachingMaterial(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        fileUrl: downloadUrl,
        fileName: fileName,
        fileType: fileType,
        fileSize: fileBytes.length / 1024,
        className: className,
        teacherId: user.id,
        teacherName: user.email?.split('@').first ?? 'Teacher',
        tags: tags,
        isPublished: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await SupabaseService.addMaterial(material);
      await loadTeacherMaterials();
      _selectedFile = null;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Upload failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update existing material
  Future<bool> updateMaterial({
    required String title,
    required String description,
    required String className,
    required List<String> tags,
  }) async {
    if (_selectedMaterial == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedMaterial = TeachingMaterial(
        id: _selectedMaterial!.id,
        title: title,
        description: description,
        fileUrl: _selectedMaterial!.fileUrl,
        fileName: _selectedMaterial!.fileName,
        fileType: _selectedMaterial!.fileType,
        fileSize: _selectedMaterial!.fileSize,
        className: className,
        teacherId: _selectedMaterial!.teacherId,
        teacherName: _selectedMaterial!.teacherName,
        tags: tags,
        isPublished: _selectedMaterial!.isPublished,
        createdAt: _selectedMaterial!.createdAt,
        updatedAt: DateTime.now(),
      );

      await SupabaseService.updateMaterial(updatedMaterial);
      await loadTeacherMaterials();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update material: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete material
  Future<bool> deleteMaterial(String materialId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final material = await SupabaseService.getMaterialById(materialId);
      if (material != null) {
        await SupabaseService.deleteFile(material.fileUrl);
        await SupabaseService.deleteMaterial(materialId);
        await loadTeacherMaterials();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete material: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Download material
  Future<io.File?> downloadMaterial(TeachingMaterial material) async {
    _isLoading = true;
    notifyListeners();

    try {
      final file = await SupabaseService.downloadFile(
        material.fileUrl,
        material.fileName,
      );

      _isLoading = false;
      notifyListeners();
      return file; // File? (null on web)
    } catch (e) {
      _errorMessage = 'Failed to download material: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Toggle publish status
  Future<void> togglePublishStatus(String materialId, bool isPublished) async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.togglePublishStatus(materialId, isPublished);
      await loadTeacherMaterials();
    } catch (e) {
      _errorMessage = 'Failed to toggle publish status: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Search
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters
  void _applyFilters() {
    List<TeachingMaterial> filtered = _materials;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((material) {
        final q = _searchQuery.toLowerCase();
        return material.title.toLowerCase().contains(q) ||
            material.description.toLowerCase().contains(q);
      }).toList();
    }

    _filteredMaterials = filtered;
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}