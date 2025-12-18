// chat_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  // Get user profile from either student_profile or teacher_profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      // First try student_profile
      final studentResponse = await _supabase
          .from('student_profile')
          .select('id, name, email, user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (studentResponse != null) {
        return {
          ...studentResponse,
          'user_type': 'student',
        };
      }

      // If not found, try teacher_profile
      final teacherResponse = await _supabase
          .from('teacher_profile')
          .select('id, name, email, user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (teacherResponse != null) {
        return {
          ...teacherResponse,
          'user_type': 'teacher',
        };
      }

      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get current user's profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (currentUser == null) return null;
    return await getUserProfile(currentUser!.id);
  }

  // Create individual chat (1-on-1)
  Future<Map<String, dynamic>?> createIndividualChat(String otherUserEmail) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) {
        print('Error: No current user');
        return null;
      }

      // Get other user's ID by searching both profile tables
      String? otherUserId;
      
      // Try student_profile
      final studentUser = await _supabase
          .from('student_profile')
          .select('user_id')
          .eq('email', otherUserEmail)
          .maybeSingle();
      
      if (studentUser != null) {
        otherUserId = studentUser['user_id'];
      } else {
        // Try teacher_profile
        final teacherUser = await _supabase
            .from('teacher_profile')
            .select('user_id')
            .eq('email', otherUserEmail)
            .maybeSingle();
        
        if (teacherUser != null) {
          otherUserId = teacherUser['user_id'];
        }
      }

      if (otherUserId == null) {
        print('Error: User not found with email $otherUserEmail');
        return null;
      }

      // Check if chat already exists between these two users
      final existingChats = await _supabase
          .from('chat_member')
          .select('chat_id')
          .eq('user_id', currentUserId);

      for (final membership in existingChats) {
        final chatId = membership['chat_id'];
        
        // Check if other user is also in this chat
        final otherUserInChat = await _supabase
            .from('chat_member')
            .select('chat_id')
            .eq('chat_id', chatId)
            .eq('user_id', otherUserId)
            .maybeSingle();

        if (otherUserInChat != null) {
          // Get the full chat details
          final chat = await _supabase
              .from('chat')
              .select()
              .eq('id', chatId)
              .eq('is_group', false)
              .maybeSingle();
          
          if (chat != null) {
            print('Chat already exists: $chatId');
            return chat;
          }
        }
      }

      // Get profiles for both users
      final currentProfile = await getCurrentUserProfile();
      final otherProfile = await getUserProfile(otherUserId);

      final currentUserName = currentProfile?['name'] ?? currentUser?.email?.split('@').first ?? 'User';
      final otherUserName = otherProfile?['name'] ?? otherUserEmail.split('@').first;

      // Create new chat
      final chatData = {
        'is_group': false,
        'name': '$currentUserName & $otherUserName',
        'created_by': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final chatResponse = await _supabase
          .from('chat')
          .insert(chatData)
          .select()
          .single();

      final chatId = chatResponse['id'];

      // Add both users as members
      await _supabase.from('chat_member').insert([
        {
          'chat_id': chatId,
          'user_id': currentUserId,
          'role': 'admin',
          'joined_at': DateTime.now().toIso8601String(),
        },
        {
          'chat_id': chatId,
          'user_id': otherUserId,
          'role': 'member',
          'joined_at': DateTime.now().toIso8601String(),
        },
      ]);

      print('Individual chat created: $chatId');
      return chatResponse;
    } catch (e) {
      print('Error creating individual chat: $e');
      return null;
    }
  }

  // Create group chat
  Future<Map<String, dynamic>?> createGroupChat(
    String groupName,
    List<String> memberEmails,
  ) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) {
        print('Error: No current user');
        return null;
      }

      // Create chat
      final chatData = {
        'name': groupName,
        'is_group': true,
        'created_by': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final chatResponse = await _supabase
          .from('chat')
          .insert(chatData)
          .select()
          .single();

      final chatId = chatResponse['id'];

      // Add creator as admin
      await _supabase.from('chat_member').insert({
        'chat_id': chatId,
        'user_id': currentUserId,
        'role': 'admin',
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Add other members
      for (final email in memberEmails) {
        // Get user ID from profile tables
        String? userId;
        
        final studentUser = await _supabase
            .from('student_profile')
            .select('user_id')
            .eq('email', email)
            .maybeSingle();
        
        if (studentUser != null) {
          userId = studentUser['user_id'];
        } else {
          final teacherUser = await _supabase
              .from('teacher_profile')
              .select('user_id')
              .eq('email', email)
              .maybeSingle();
          
          if (teacherUser != null) {
            userId = teacherUser['user_id'];
          }
        }

        if (userId != null) {
          await _supabase.from('chat_member').insert({
            'chat_id': chatId,
            'user_id': userId,
            'role': 'member',
            'joined_at': DateTime.now().toIso8601String(),
          });
        } else {
          print('Warning: User not found with email $email');
        }
      }

      print('Group chat created: $chatId');
      return chatResponse;
    } catch (e) {
      print('Error creating group chat: $e');
      return null;
    }
  }

  // Get individual chats for current user
  Future<List<Map<String, dynamic>>> getIndividualChats() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      // Get all chat IDs where user is a member
      final memberships = await _supabase
          .from('chat_member')
          .select('chat_id')
          .eq('user_id', userId);

      if (memberships.isEmpty) return [];

      final chatIds = memberships.map((m) => m['chat_id'] as String).toList();

      // Get individual chats - fetch one by one to avoid 'in' filter
      final List<Map<String, dynamic>> chats = [];
      for (final chatId in chatIds) {
        final chat = await _supabase
            .from('chat')
            .select()
            .eq('id', chatId)
            .eq('is_group', false)
            .maybeSingle();
        
        if (chat != null) {
          chats.add(chat);
        }
      }

      // Sort by created_at
      chats.sort((a, b) {
        final aTime = DateTime.parse(a['created_at']);
        final bTime = DateTime.parse(b['created_at']);
        return bTime.compareTo(aTime);
      });

      return chats;
    } catch (e) {
      print('Error getting individual chats: $e');
      return [];
    }
  }

  // Get group chats for current user
  Future<List<Map<String, dynamic>>> getGroupChats() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      // Get chat IDs where user is a member
      final memberships = await _supabase
          .from('chat_member')
          .select('chat_id')
          .eq('user_id', userId);

      if (memberships.isEmpty) return [];

      final chatIds = memberships.map((m) => m['chat_id'] as String).toList();

      // Get group chats - fetch one by one to avoid 'in' filter
      final List<Map<String, dynamic>> chats = [];
      for (final chatId in chatIds) {
        final chat = await _supabase
            .from('chat')
            .select()
            .eq('id', chatId)
            .eq('is_group', true)
            .maybeSingle();
        
        if (chat != null) {
          chats.add(chat);
        }
      }

      // Sort by created_at
      chats.sort((a, b) {
        final aTime = DateTime.parse(a['created_at']);
        final bTime = DateTime.parse(b['created_at']);
        return bTime.compareTo(aTime);
      });

      return chats;
    } catch (e) {
      print('Error getting group chats: $e');
      return [];
    }
  }

  // Send message (TEMPORARY: No membership check for testing)
  Future<bool> sendMessage(String chatId, String content) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        print('Error: No current user ID');
        return false;
      }

      print('Sending message - User ID: $userId, Chat ID: $chatId');

      final messageData = {
        'chat_id': chatId,
        'user_id': userId,
        'content': content,
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      print('Message data: $messageData');

      final response = await _supabase
          .from('message')
          .insert(messageData)
          .select();

      print('Message sent successfully: $response');
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Get messages with sender information
  Future<List<Map<String, dynamic>>> getMessagesWithSender(String chatId) async {
    try {
      final messages = await _supabase
          .from('message')
          .select('*')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      print('Fetched ${messages.length} messages for chat $chatId');

      // Enrich messages with sender info
      final enrichedMessages = <Map<String, dynamic>>[];
      
      for (final message in messages) {
        final userId = message['user_id'];
        final profile = await getUserProfile(userId);
        
        enrichedMessages.add({
          ...message,
          'sender': profile ?? {
            'name': 'Unknown User',
            'email': 'unknown@example.com',
            'user_type': 'unknown',
          },
        });
      }

      return enrichedMessages;
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Get unread message count
  Future<int> getUnreadCount(String chatId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('message')
          .select('id')
          .eq('chat_id', chatId)
          .neq('user_id', userId)
          .eq('read', false);

      return response.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String chatId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('message')
          .update({'read': true})
          .eq('chat_id', chatId)
          .neq('user_id', userId);
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // Subscribe to new messages in a chat - SIMPLIFIED (No realtime for now)
  // Use polling instead by calling getMessagesWithSender periodically
  void subscribeToChat(String chatId, Function(Map<String, dynamic>) onMessage) {
    // Note: This is a placeholder. The actual realtime subscription
    // depends on your supabase_flutter version.
    // For now, use periodic polling in the UI with Timer.periodic
    print('Realtime subscription placeholder for chat: $chatId');
  }

  // Unsubscribe from chat
  void unsubscribeFromChat(dynamic channel) {
    // Placeholder
  }

  // Get chat members
  Future<List<Map<String, dynamic>>> getChatMembers(String chatId) async {
    try {
      final members = await _supabase
          .from('chat_member')
          .select('user_id, role, joined_at')
          .eq('chat_id', chatId);

      // Enrich with profile data
      final enrichedMembers = <Map<String, dynamic>>[];
      
      for (final member in members) {
        final profile = await getUserProfile(member['user_id']);
        enrichedMembers.add({
          ...member,
          'profile': profile,
        });
      }

      return enrichedMembers;
    } catch (e) {
      print('Error getting chat members: $e');
      return [];
    }
  }

  // Add member to chat (admin only)
  Future<bool> addMemberToChat(String chatId, String memberEmail) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return false;

      // Check if current user is admin
      final membership = await _supabase
          .from('chat_member')
          .select('role')
          .eq('chat_id', chatId)
          .eq('user_id', userId)
          .single();

      if (membership['role'] != 'admin') {
        print('Error: Only admins can add members');
        return false;
      }

      // Find new member's user_id
      String? newMemberId;
      
      final studentUser = await _supabase
          .from('student_profile')
          .select('user_id')
          .eq('email', memberEmail)
          .maybeSingle();
      
      if (studentUser != null) {
        newMemberId = studentUser['user_id'];
      } else {
        final teacherUser = await _supabase
            .from('teacher_profile')
            .select('user_id')
            .eq('email', memberEmail)
            .maybeSingle();
        
        if (teacherUser != null) {
          newMemberId = teacherUser['user_id'];
        }
      }

      if (newMemberId == null) {
        print('Error: User not found');
        return false;
      }

      // Add member
      await _supabase.from('chat_member').insert({
        'chat_id': chatId,
        'user_id': newMemberId,
        'role': 'member',
        'joined_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error adding member: $e');
      return false;
    }
  }

  // Remove member from chat (admin only or self)
  Future<bool> removeMemberFromChat(String chatId, String memberUserId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return false;

      // Allow if removing self or if admin
      if (userId == memberUserId) {
        // Removing self
        await _supabase
            .from('chat_member')
            .delete()
            .eq('chat_id', chatId)
            .eq('user_id', memberUserId);
        return true;
      } else {
        // Check if admin
        final membership = await _supabase
            .from('chat_member')
            .select('role')
            .eq('chat_id', chatId)
            .eq('user_id', userId)
            .single();

        if (membership['role'] == 'admin') {
          await _supabase
              .from('chat_member')
              .delete()
              .eq('chat_id', chatId)
              .eq('user_id', memberUserId);
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }
}