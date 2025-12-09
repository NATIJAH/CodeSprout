import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat_home_screen.dart';

class OpenTeacherChat extends StatefulWidget {
  const OpenTeacherChat({super.key});

  @override
  State<OpenTeacherChat> createState() => _OpenTeacherChatState();
}

class _OpenTeacherChatState extends State<OpenTeacherChat> {
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
        // Fetch teacher profile info
        final profile = await supabase
            .from('profile_teacher')
            .select('full_name')
            .eq('id', user.id)
            .single();

        setState(() {
          _userId = user.id;
          _userName = profile['full_name'] ?? 'Teacher';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
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
      userType: 'teacher',
      userId: _userId!,
      userName: _userName!,
    );
  }
}