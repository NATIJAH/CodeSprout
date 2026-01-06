import 'package:flutter/material.dart';

class TeachingMaterial {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final double fileSize;
  final String className;  // Changed from subject + grade to single className
  final String teacherId;
  final String teacherName;
  final List<String> tags;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeachingMaterial({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    List<String>? tags,
    this.isPublished = true,
    required this.createdAt,
    required this.updatedAt,
  }) : tags = tags ?? [];

  // Convert to Map for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'class_name': className,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'tags': tags,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from Supabase response
  factory TeachingMaterial.fromJson(Map<String, dynamic> json) {
    return TeachingMaterial(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fileUrl: json['file_url'] ?? '',
      fileName: json['file_name'] ?? '',
      fileType: json['file_type'] ?? '',
      fileSize: (json['file_size'] ?? 0).toDouble(),
      className: json['class_name'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      teacherName: json['teacher_name'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      isPublished: json['is_published'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Helper methods
  String get fileIcon {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'image':
        return '🖼️';
      case 'video':
        return '🎬';
      case 'word':
        return '📝';
      case 'excel':
        return '📊';
      case 'powerpoint':
        return '📽️';
      default:
        return '📎';
    }
  }

  String get readableFileSize {
    if (fileSize < 1024) {
      return '${fileSize.toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / 1024).toStringAsFixed(1)} MB';
    }
  }

  Color get fileColor {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'image':
        return Colors.green;
      case 'video':
        return Colors.blue;
      case 'word':
        return Colors.blue[800]!;
      case 'excel':
        return const Color(0xff2c4a3f);
      case 'powerpoint':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  bool get isImage => fileType.toLowerCase() == 'image';
  bool get isPdf => fileType.toLowerCase() == 'pdf';
  bool get isVideo => fileType.toLowerCase() == 'video';
}