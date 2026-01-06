// services/calendar_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calendar_event_model.dart';

class CalendarService {
  final _supabase = Supabase.instance.client;

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ============= EVENT CRUD FUNCTIONS =============

  // Get events stream for realtime updates
  Stream<List<CalendarEventModel>> getEventsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    print('📅 Setting up calendar events stream for user: $userId');

    return _supabase
        .from('calendar_events')
        .stream(primaryKey: ['id'])
        .order('event_date', ascending: true)
        .map((data) {
      print('📨 Calendar stream data: ${data.length} events');
      
      // Filter events that user can see
      final filtered = data.where((event) {
        // User created the event
        if (event['created_by'] == userId) return true;
        
        // User is assigned to the event
        final assignedTo = event['assigned_to'] as List<dynamic>? ?? [];
        if (assignedTo.contains(userId)) return true;
        
        return false;
      }).toList();

      return filtered.map((json) => CalendarEventModel.fromJson(json)).toList();
    });
  }

  // Get events for specific date
  Future<List<CalendarEventModel>> getEventsByDate(DateTime date) async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final dateStr = date.toIso8601String().split('T')[0];
      print('📅 Getting events for date: $dateStr');

      // Get events created by user
      final ownEvents = await _supabase
          .from('calendar_events')
          .select('*')
          .eq('created_by', userId)
          .eq('event_date', dateStr)
          .order('start_time', ascending: true);

      // Get events assigned to user
      final assignedEvents = await _supabase
          .from('calendar_events')
          .select('*')
          .contains('assigned_to', [userId])
          .eq('event_date', dateStr)
          .order('start_time', ascending: true);

      // Combine and remove duplicates
      final allEvents = <String, Map<String, dynamic>>{};
      for (var event in [...ownEvents, ...assignedEvents]) {
        allEvents[event['id']] = event;
      }

      final events = allEvents.values
          .map((json) => CalendarEventModel.fromJson(json))
          .toList();

      print('📅 Found ${events.length} events');
      return events;
    } catch (e) {
      print('❌ Error getting events by date: $e');
      return [];
    }
  }

  // Get events for date range (for calendar month view)
  Future<List<CalendarEventModel>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];
      print('📅 Getting events from $startStr to $endStr');

      // Get events created by user
      final ownEvents = await _supabase
          .from('calendar_events')
          .select('*')
          .eq('created_by', userId)
          .gte('event_date', startStr)
          .lte('event_date', endStr)
          .order('event_date', ascending: true);

      // Get events assigned to user
      final assignedEvents = await _supabase
          .from('calendar_events')
          .select('*')
          .contains('assigned_to', [userId])
          .gte('event_date', startStr)
          .lte('event_date', endStr)
          .order('event_date', ascending: true);

      // Combine and remove duplicates
      final allEvents = <String, Map<String, dynamic>>{};
      for (var event in [...ownEvents, ...assignedEvents]) {
        allEvents[event['id']] = event;
      }

      final events = allEvents.values
          .map((json) => CalendarEventModel.fromJson(json))
          .toList();

      print('📅 Found ${events.length} events in range');
      return events;
    } catch (e) {
      print('❌ Error getting events by date range: $e');
      return [];
    }
  }

  // Get upcoming events (next 7 days)
  Future<List<CalendarEventModel>> getUpcomingEvents({int days = 7}) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));
    return getEventsByDateRange(now, endDate);
  }

  // Create new event
  Future<CalendarEventModel?> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool isAllDay = false,
    String color = '#6B9B7F',
    String eventType = 'personal',
    List<String> assignedTo = const [],
    List<String> assignedEmails = const [],
    int? reminderMinutes,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Not logged in');

      print('📅 Creating event: $title');
      print('   Date: ${eventDate.toIso8601String().split('T')[0]}');
      print('   Type: $eventType');

      // If assignedEmails provided, convert to user IDs
      List<String> finalAssignedTo = [...assignedTo];
      if (assignedEmails.isNotEmpty) {
        final userIds = await _getUserIdsByEmails(assignedEmails);
        finalAssignedTo.addAll(userIds);
      }

      final eventData = {
        'created_by': userId,
        'title': title,
        'description': description,
        'event_date': eventDate.toIso8601String().split('T')[0],
        'start_time': startTime != null ? _formatTimeOfDay(startTime) : null,
        'end_time': endTime != null ? _formatTimeOfDay(endTime) : null,
        'is_all_day': isAllDay,
        'color': color,
        'event_type': eventType,
        'assigned_to': finalAssignedTo,
        'assigned_emails': assignedEmails,
        'reminder_minutes': reminderMinutes,
      };

      final response = await _supabase
          .from('calendar_events')
          .insert(eventData)
          .select()
          .single();

      print('✅ Event created: ${response['id']}');
      return CalendarEventModel.fromJson(response);
    } catch (e) {
      print('❌ Error creating event: $e');
      return null;
    }
  }

  // Update event
  Future<CalendarEventModel?> updateEvent({
    required String eventId,
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
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Not logged in');

      print('✏️ Updating event: $eventId');

      // Build update data (only include non-null values)
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (eventDate != null) {
        updateData['event_date'] = eventDate.toIso8601String().split('T')[0];
      }
      if (startTime != null) {
        updateData['start_time'] = _formatTimeOfDay(startTime);
      }
      if (endTime != null) {
        updateData['end_time'] = _formatTimeOfDay(endTime);
      }
      if (isAllDay != null) updateData['is_all_day'] = isAllDay;
      if (color != null) updateData['color'] = color;
      if (eventType != null) updateData['event_type'] = eventType;
      if (assignedTo != null) updateData['assigned_to'] = assignedTo;
      if (assignedEmails != null) {
        updateData['assigned_emails'] = assignedEmails;
        // Also convert emails to user IDs
        final userIds = await _getUserIdsByEmails(assignedEmails);
        updateData['assigned_to'] = [...(assignedTo ?? []), ...userIds];
      }
      if (reminderMinutes != null) {
        updateData['reminder_minutes'] = reminderMinutes;
      }

      final response = await _supabase
          .from('calendar_events')
          .update(updateData)
          .eq('id', eventId)
          .eq('created_by', userId)
          .select()
          .single();

      print('✅ Event updated');
      return CalendarEventModel.fromJson(response);
    } catch (e) {
      print('❌ Error updating event: $e');
      return null;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String eventId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Not logged in');

      print('🗑️ Deleting event: $eventId');

      await _supabase
          .from('calendar_events')
          .delete()
          .eq('id', eventId)
          .eq('created_by', userId);

      print('✅ Event deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting event: $e');
      return false;
    }
  }

  // ============= STUDENT ASSIGNMENT FUNCTIONS (Teacher only) =============

  // Get all students (for teacher to assign events)
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      print('👥 Getting all students');

      final response = await _supabase
          .from('profile_student')
          .select('id, email, full_name')
          .order('full_name', ascending: true);

      print('👥 Found ${response.length} students');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting students: $e');
      return [];
    }
  }

  // Search students by email
  Future<List<Map<String, dynamic>>> searchStudentsByEmail(String email) async {
    try {
      print('🔍 Searching students by email: $email');

      final response = await _supabase
          .from('profile_student')
          .select('id, email, full_name')
          .ilike('email', '%$email%')
          .limit(10);

      print('🔍 Found ${response.length} students');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error searching students: $e');
      return [];
    }
  }

  // Get user IDs by emails
  Future<List<String>> _getUserIdsByEmails(List<String> emails) async {
    try {
      if (emails.isEmpty) return [];

      List<String> userIds = [];

      for (var email in emails) {
        // Check in student profiles
        final studentResponse = await _supabase
            .from('profile_student')
            .select('id')
            .eq('email', email.trim().toLowerCase())
            .maybeSingle();

        if (studentResponse != null) {
          userIds.add(studentResponse['id']);
          continue;
        }

        // Check in teacher profiles
        final teacherResponse = await _supabase
            .from('profile_teacher')
            .select('id')
            .eq('email', email.trim().toLowerCase())
            .maybeSingle();

        if (teacherResponse != null) {
          userIds.add(teacherResponse['id']);
        }
      }

      return userIds;
    } catch (e) {
      print('❌ Error getting user IDs by emails: $e');
      return [];
    }
  }

  // ============= HELPER FUNCTIONS =============

  // Format TimeOfDay to string (HH:mm:ss)
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  // Get events grouped by date (for calendar markers)
  Future<Map<DateTime, List<CalendarEventModel>>> getEventsGroupedByDate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final events = await getEventsByDateRange(startDate, endDate);
    
    final grouped = <DateTime, List<CalendarEventModel>>{};
    for (var event in events) {
      final dateKey = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(event);
    }
    
    return grouped;
  }

  // Check if date has events
  Future<bool> dateHasEvents(DateTime date) async {
    final events = await getEventsByDate(date);
    return events.isNotEmpty;
  }
}