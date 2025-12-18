import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateNotificationScreen extends StatefulWidget {
  const CreateNotificationScreen({super.key});

  @override
  State<CreateNotificationScreen> createState() => _CreateNotificationScreenState();
}

class _CreateNotificationScreenState extends State<CreateNotificationScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  List<Map<String, dynamic>> _students = [];
  String? _selectedStudentId;
  bool _broadcastToAll = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final students = await Supabase.instance.client
          .from('profiles') // Adjust table name if different (e.g., 'users', 'students')
          .select('id, email, full_name')
          .eq('role', 'student'); // Filter for students only; adjust if column name differs

      setState(() => _students = List<Map<String, dynamic>>.from(students ?? []));
    } catch (e) {
      debugPrint('Error fetching students: $e');
      setState(() => _students = []);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and message')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Insert notification into notifications table
      final notificationResponse = await Supabase.instance.client
          .from('notifications')
          .insert({
            'title': _titleController.text.trim(),
            'message': _messageController.text.trim(),
            'created_by': currentUser.id,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select();

      if (notificationResponse.isEmpty) {
        throw Exception('Failed to create notification');
      }

      final notificationId = notificationResponse.first['id'];

      // If a specific student is selected, add to notification_recipients table
      if (!_broadcastToAll && _selectedStudentId != null) {
        await Supabase.instance.client.from('notification_recipients').insert({
          'notification_id': notificationId,
          'recipient_id': _selectedStudentId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      // If broadcast: don't insert any row in notification_recipients (empty recipient list = broadcast)

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _titleController.clear();
      _messageController.clear();
      setState(() {
        _broadcastToAll = true;
        _selectedStudentId = null;
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Notification'),
        backgroundColor: const Color(0xff4f7f67),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text('Recipients', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Broadcast to all students'),
              value: _broadcastToAll,
              onChanged: (value) => setState(() => _broadcastToAll = value ?? true),
            ),
            if (!_broadcastToAll) ...[
              const SizedBox(height: 12),
              DropdownButton<String>(
                hint: const Text('Select a student'),
                value: _selectedStudentId,
                items: _students.map((student) {
                  final name = student['full_name'] ?? student['email'] ?? student['id'];
                  return DropdownMenuItem(value: student['id'] as String, child: Text(name));
                }).toList(),
                onChanged: (value) => setState(() => _selectedStudentId = value),
                isExpanded: true,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendNotification,
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Send Notification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}