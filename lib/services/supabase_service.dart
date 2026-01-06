// lib/services/supabase_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/teaching_material.dart';

/// Only needed for Web downloading
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class SupabaseService {
  // ✅ CHANGE: Use getter instead of static final
  static SupabaseClient get _client => Supabase.instance.client;

  static final Uuid _uuid = const Uuid();

  // Get current user
  static User? get currentUser => _client.auth.currentUser;

  // Get user ID
  static String get userId => _client.auth.currentUser?.id ?? '';

  // Generate a v4 UUID
  static String newUuid() => _uuid.v4();

  // Simple UUID validation (v4-like)
  static bool _isValidUuid(String id) {
    final uuidRegEx = RegExp(
      r'^[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}$',
    );
    return uuidRegEx.hasMatch(id);
  }

  // ---------------------------------------------------------------------------
  // STORAGE FUNCTIONS
  // ---------------------------------------------------------------------------

  /// Upload bytes to the 'teaching-materials' bucket.
  /// Returns the public URL on success.
  static Future<String> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    required String teacherId,
    required String className,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeFileName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final storagePath = '$teacherId/$className/${timestamp}_$safeFileName';

      await _client.storage.from('teaching-materials').uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'application/octet-stream',
            ),
          );

      return _client.storage
          .from('teaching-materials')
          .getPublicUrl(storagePath);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Extract the storage path from any valid Supabase public URL
  static String _extractStoragePathFromPublicUrl(
    String url, {
    String bucket = 'teaching-materials',
  }) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;

      // Pattern 1: /storage/v1/object/public/<bucket>/
      final p1 = '/storage/v1/object/public/$bucket/';
      if (path.contains(p1)) {
        return path.split(p1).last;
      }

      // Pattern 2: /storage/v1/object/<bucket>/
      final p2 = '/storage/v1/object/$bucket/';
      if (path.contains(p2)) {
        return path.split(p2).last;
      }

      // Pattern 3: fallback: /<bucket>/
      final p3 = '/$bucket/';
      if (path.contains(p3)) {
        return path.split(p3).last;
      }

      // Last resort: full string match
      if (url.contains('/$bucket/')) {
        return url.split('/$bucket/').last.split('?').first;
      }

      throw Exception('Could not parse storage path from URL.');
    } catch (e) {
      throw Exception('Failed to extract storage path: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // DOWNLOAD (FULL CROSS-PLATFORM)
  // ---------------------------------------------------------------------------

  /// Downloads file from Supabase storage.
  ///
  /// MOBILE + DESKTOP:
  ///   → Saves to app documents → "/downloads/<fileName>"
  ///
  /// WEB:
  ///   → Uses AnchorElement to trigger browser download
  ///   → File does NOT get saved to app directory (web doesn't allow)
  ///
  /// Returns:
  ///   File (mobile/desktop)
  ///   null (web)
  static Future<File?> downloadFile(String fileUrl, String fileName) async {
    try {
      final storagePath = _extractStoragePathFromPublicUrl(fileUrl);
      final bytes = await _client.storage
          .from('teaching-materials')
          .download(storagePath);

      // ----------------------------
      // WEB DOWNLOAD HANDLING
      // ----------------------------
      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..target = 'blank'
          ..download = fileName;

        anchor.click();
        html.Url.revokeObjectUrl(url);

        debugPrint('⬇️ Web download triggered: $fileName');
        return null; // web cannot store locally
      }

      // ----------------------------
      // MOBILE + DESKTOP HANDLING
      // ----------------------------
      WidgetsFlutterBinding.ensureInitialized();

      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  /// Delete a file from storage by public URL or path.
  static Future<void> deleteFile(String fileUrlOrPath) async {
    try {
      final path = fileUrlOrPath.startsWith('http')
          ? _extractStoragePathFromPublicUrl(fileUrlOrPath)
          : fileUrlOrPath;

      await _client.storage.from('teaching-materials').remove([path]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // DATABASE FUNCTIONS
  // ---------------------------------------------------------------------------

  static Future<void> addMaterial(TeachingMaterial material) async {
    try {
      final Map<String, dynamic> payload = material.toJson();

      // Validate ID
      if (!payload.containsKey('id') || !_isValidUuid(payload['id'])) {
        payload['id'] = newUuid();
      }

      // Validate teacher_id
      if (!payload.containsKey('teacher_id') ||
          !_isValidUuid(payload['teacher_id'])) {
        final uid = currentUser?.id;
        if (uid != null && _isValidUuid(uid)) {
          payload['teacher_id'] = uid;
        } else {
          throw Exception('Invalid teacher_id for material insert.');
        }
      }

      // DateTime → ISO8601
      if (payload['created_at'] is DateTime) {
        payload['created_at'] =
            (payload['created_at'] as DateTime).toIso8601String();
      }
      if (payload['updated_at'] is DateTime) {
        payload['updated_at'] =
            (payload['updated_at'] as DateTime).toIso8601String();
      }

      await _client.from('teaching_materials').insert(payload);
      debugPrint('✔ Material inserted: ${payload['id']}');
    } catch (e) {
      debugPrint('❌ Failed to add material: $e');
      throw Exception('Failed to add material: $e');
    }
  }

  static Future<void> updateMaterial(TeachingMaterial material) async {
    try {
      if (!_isValidUuid(material.id)) {
        throw Exception('Invalid material id for update.');
      }

      final payload = material.toJson();

      payload['updated_at'] = (payload['updated_at'] is DateTime)
          ? (payload['updated_at'] as DateTime).toIso8601String()
          : DateTime.now().toIso8601String();

      await _client
          .from('teaching_materials')
          .update(payload)
          .eq('id', material.id);
    } catch (e) {
      throw Exception('Failed to update material: $e');
    }
  }

  static Future<void> deleteMaterial(String materialId) async {
    try {
      if (!_isValidUuid(materialId)) {
        throw Exception('Invalid material id for deletion.');
      }

      await _client
          .from('teaching_materials')
          .delete()
          .eq('id', materialId);
    } catch (e) {
      throw Exception('Failed to delete material: $e');
    }
  }

  static Future<List<TeachingMaterial>> getTeacherMaterials(
      String teacherId) async {
    try {
      if (!_isValidUuid(teacherId)) {
        throw Exception('Invalid teacher id for query.');
      }

      final response = await _client
          .from('teaching_materials')
          .select()
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => TeachingMaterial.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to get materials: $e');
    }
  }

  static Future<List<TeachingMaterial>> getPublishedMaterials() async {
    try {
      final response = await _client
          .from('teaching_materials')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => TeachingMaterial.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to get published materials: $e');
    }
  }

  static Future<TeachingMaterial?> getMaterialById(String materialId) async {
    try {
      if (!_isValidUuid(materialId)) return null;

      final response = await _client
          .from('teaching_materials')
          .select()
          .eq('id', materialId)
          .single();

      return TeachingMaterial.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  static Future<List<TeachingMaterial>> searchMaterials(
      String teacherId, String query) async {
    try {
      if (!_isValidUuid(teacherId)) {
        throw Exception('Invalid teacher id for search.');
      }

      final response = await _client
          .from('teaching_materials')
          .select()
          .eq('teacher_id', teacherId)
          .or('title.ilike.%$query%,description.ilike.%$query%');

      return (response as List)
          .map((item) => TeachingMaterial.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to search materials: $e');
    }
  }

  static Future<void> togglePublishStatus(
      String materialId, bool isPublished) async {
    try {
      if (!_isValidUuid(materialId)) {
        throw Exception('Invalid material id for toggling publish status.');
      }

      await _client.from('teaching_materials').update({
        'is_published': isPublished,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', materialId);
    } catch (e) {
      throw Exception('Failed to update publish status: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MCQ FUNCTIONS
  // ---------------------------------------------------------------------------

  /// Get all MCQ sets
  static Future<List<Map<String, dynamic>>> getMcqSets() async {
    try {
      final response = await _client
          .from('mcq_set')
          .select('*, mcq_question(count)')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get MCQ sets: $e');
    }
  }

  /// Get MCQ questions for a specific set
  static Future<List<Map<String, dynamic>>> getMcqQuestions(
      String mcqSetId) async {
    try {
      final response = await _client
          .from('mcq_question')
          .select('*')
          .eq('mcq_set_id', mcqSetId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get MCQ questions: $e');
    }
  }

  /// Create MCQ set
  static Future<void> createMcqSet({
    required String title,
    String? description,
  }) async {
    try {
      final mcqSetData = {
        'title': title.trim(),
        'description': description?.trim(),
      };

      await _client.from('mcq_set').insert(mcqSetData);
    } catch (e) {
      throw Exception('Failed to create MCQ set: $e');
    }
  }

  /// Update MCQ set
  static Future<void> updateMcqSet({
    required String id,
    required String title,
    String? description,
  }) async {
    try {
      final mcqSetData = {
        'title': title.trim(),
        'description': description?.trim(),
      };

      await _client.from('mcq_set').update(mcqSetData).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update MCQ set: $e');
    }
  }

  /// Delete MCQ set (and all its questions)
  static Future<void> deleteMcqSet(String id) async {
    try {
      // Delete all questions first
      await _client.from('mcq_question').delete().eq('mcq_set_id', id);

      // Delete the set
      await _client.from('mcq_set').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete MCQ set: $e');
    }
  }

  /// Create MCQ question
  static Future<void> createMcqQuestion({
    required String mcqSetId,
    required String questionText,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
    required String correctAnswer,
    String? explanation,
    int marks = 1,
  }) async {
    try {
      final questionData = {
        'mcq_set_id': mcqSetId,
        'question_text': questionText.trim(),
        'option_a': optionA.trim(),
        'option_b': optionB.trim(),
        'option_c': optionC.trim(),
        'option_d': optionD.trim(),
        'correct_answer': correctAnswer,
        'explanation': explanation?.trim(),
        'marks': marks,
      };

      await _client.from('mcq_question').insert(questionData);
    } catch (e) {
      throw Exception('Failed to create MCQ question: $e');
    }
  }

  /// Update MCQ question
  static Future<void> updateMcqQuestion({
    required String id,
    required String questionText,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
    required String correctAnswer,
    String? explanation,
    int marks = 1,
  }) async {
    try {
      final questionData = {
        'question_text': questionText.trim(),
        'option_a': optionA.trim(),
        'option_b': optionB.trim(),
        'option_c': optionC.trim(),
        'option_d': optionD.trim(),
        'correct_answer': correctAnswer,
        'explanation': explanation?.trim(),
        'marks': marks,
      };

      await _client.from('mcq_question').update(questionData).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update MCQ question: $e');
    }
  }

  /// Delete MCQ question
  static Future<void> deleteMcqQuestion(String id) async {
    try {
      await _client.from('mcq_question').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete MCQ question: $e');
    }
  }

  /// Get student MCQ attempts
  static Future<Map<String, dynamic>> getStudentMcqAttempts(
      String studentId) async {
    try {
      final response = await _client
          .from('student_mcq_attempts')
          .select('*')
          .eq('student_id', studentId);

      final Map<String, dynamic> attemptsMap = {};
      for (var attempt in response) {
        attemptsMap[attempt['mcq_set_id']] = attempt;
      }

      return attemptsMap;
    } catch (e) {
      throw Exception('Failed to get student MCQ attempts: $e');
    }
  }

  /// Submit MCQ attempt
  static Future<void> submitMcqAttempt({
    required String studentId,
    required String mcqSetId,
    required int score,
    required Map<String, dynamic> answers,
    required int totalQuestions,
    required int correctAnswers,
    String? studentName,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final attemptData = {
        'student_id': studentId,
        'mcq_set_id': mcqSetId,
        'score': score,
        'answers': answers,
        'total_questions': totalQuestions,
        'correct_answers': correctAnswers,
        'is_completed': true,
        'completed_at': now,
        'started_at': now,
        'submitted_at': now,
        if (studentName != null) 'student_name': studentName,
      };

      await _client.from('student_mcq_attempts').insert(attemptData);
    } catch (e) {
      throw Exception('Failed to submit MCQ attempt: $e');
    }
  }
}