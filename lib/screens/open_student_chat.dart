import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat_home_screen.dart';

class OpenStudentChat extends StatefulWidget {
  const OpenStudentChat({super.key});

  @override
  State<OpenStudentChat> createState() => _OpenStudentChatState();
}

class _OpenStudentChatState extends State<OpenStudentChat> {
  final supabase = Supabase.instance.client;
  String? _userId;
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Fetch student profile info
        final profile = await supabase
            .from('profile_student')
            .select('full_name')
            .eq('id', user.id)
            .single();

        setState(() {
          _userId = user.id;
          _userName = profile['full_name'] ?? 'Student';
          _isLoading = false;
        });
      } else {
        // If no user is logged in, show loading and redirect
        setState(() {
          _isLoading = false;
        });
        // You might want to redirect to login here
      }
    } catch (e) {
      print('Error getting user info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userId == null || _userName == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Unable to load chat',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Please log in to continue',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ChatHomeScreen(
      userType: 'student',
      userId: _userId!,
      userName: _userName!,
    );
  }
}