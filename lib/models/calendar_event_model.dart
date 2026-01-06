// models/calendar_event_model.dart

import 'package:flutter/material.dart';

class CalendarEventModel {
  final String id;
  final String createdBy;
  final String title;
  final String? description;
  final DateTime eventDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isAllDay;
  final String color;
  final String eventType; // 'personal', 'student'
  final List<String> assignedTo;
  final List<String> assignedEmails;
  final int? reminderMinutes;
  final bool reminderSent;
  final DateTime createdAt;
  final DateTime updatedAt;

  CalendarEventModel({
    required this.id,
    required this.createdBy,
    required this.title,
    this.description,
    required this.eventDate,
    this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.color = '#6B9B7F',
    this.eventType = 'personal',
    this.assignedTo = const [],
    this.assignedEmails = const [],
    this.reminderMinutes,
    this.reminderSent = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] ?? '',
      createdBy: json['created_by'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      eventDate: json['event_date'] != null 
          ? DateTime.parse(json['event_date']) 
          : DateTime.now(),
      startTime: json['start_time'] != null 
          ? _parseTimeOfDay(json['start_time']) 
          : null,
      endTime: json['end_time'] != null 
          ? _parseTimeOfDay(json['end_time']) 
          : null,
      isAllDay: json['is_all_day'] ?? false,
      color: json['color'] ?? '#6B9B7F',
      eventType: json['event_type'] ?? 'personal',
      assignedTo: json['assigned_to'] != null 
          ? List<String>.from(json['assigned_to']) 
          : [],
      assignedEmails: json['assigned_emails'] != null 
          ? List<String>.from(json['assigned_emails']) 
          : [],
      reminderMinutes: json['reminder_minutes'],
      reminderSent: json['reminder_sent'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy,
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'start_time': startTime != null ? _formatTimeOfDay(startTime!) : null,
      'end_time': endTime != null ? _formatTimeOfDay(endTime!) : null,
      'is_all_day': isAllDay,
      'color': color,
      'event_type': eventType,
      'assigned_to': assignedTo,
      'assigned_emails': assignedEmails,
      'reminder_minutes': reminderMinutes,
      'reminder_sent': reminderSent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // For inserting new event (without id, timestamps)
  Map<String, dynamic> toInsertJson() {
    return {
      'created_by': createdBy,
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'start_time': startTime != null ? _formatTimeOfDay(startTime!) : null,
      'end_time': endTime != null ? _formatTimeOfDay(endTime!) : null,
      'is_all_day': isAllDay,
      'color': color,
      'event_type': eventType,
      'assigned_to': assignedTo,
      'assigned_emails': assignedEmails,
      'reminder_minutes': reminderMinutes,
    };
  }

  CalendarEventModel copyWith({
    String? id,
    String? createdBy,
    String? title,
    String? description,
    DateTime? eventDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isAllDay,
    String? color,
    String? eventType,
    List<String>? assignedTo,
    List<String>? assignedEmails,
    int? reminderMinutes,
    bool? reminderSent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      color: color ?? this.color,
      eventType: eventType ?? this.eventType,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedEmails: assignedEmails ?? this.assignedEmails,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      reminderSent: reminderSent ?? this.reminderSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Parse time string (HH:mm:ss) to TimeOfDay
  static TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // Format TimeOfDay to string (HH:mm:ss)
  static String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  // Get Color object from hex string
  Color get colorValue {
    final hex = color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  // Format time range for display
  String get timeRange {
    if (isAllDay) return 'All Day';
    if (startTime == null) return '';
    
    final start = _formatDisplayTime(startTime!);
    if (endTime == null) return start;
    
    final end = _formatDisplayTime(endTime!);
    return '$start - $end';
  }

  String _formatDisplayTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Check if event is today
  bool get isToday {
    final now = DateTime.now();
    return eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
  }

  // Check if event is upcoming (within next 7 days)
  bool get isUpcoming {
    final now = DateTime.now();
    final difference = eventDate.difference(now).inDays;
    return difference >= 0 && difference <= 7;
  }
}

// Preset colors for color picker
class EventColors {
  static const List<String> presets = [
    '#6B9B7F', // Green (default)
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#96CEB4', // Light Green
    '#FFEAA7', // Yellow
    '#DDA0DD', // Plum
    '#FF9F43', // Orange
    '#A29BFE', // Lavender
    '#FD79A8', // Pink
  ];

  static Color fromHex(String hex) {
    final cleanHex = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }
}