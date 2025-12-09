import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => supabase.auth.currentUser;

  // ========== USER HELPER METHODS ==========

  // Find user in either login_student or login_teacher table
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      // Search in login_student first
      final studentResponse = await supabase
          .from('login_student')
          .select('id, email, name, user_type')
          .eq('email', email)
          .limit(1);

      if (studentResponse.isNotEmpty) {
        return {
          ...studentResponse.first,
          'user_type': 'student',
        };
      }

      // Search in login_teacher
      final teacherResponse = await supabase
          .from('login_teacher')
          .select('id, email, name, user_type')
          .eq('email', email)
          .limit(1);

      if (teacherResponse.isNotEmpty) {
        return {
          ...teacherResponse.first,
          'user_type': 'teacher',
        };
      }

      // Also check auth.users as fallback
      try {
        final authResponse = await supabase
            .from('auth.users')
            .select('id, email')
            .eq('email', email)
            .single();

        if (authResponse.isNotEmpty) {
          return {
            'id': authResponse['id'],
            'email': authResponse['email'],
            'name': authResponse['email'].split('@').first,
            'user_type': 'unknown',
          };
        }
      } catch (_) {
        // Ignore auth table errors
      }

      print('❌ User not found in any table: $email');
      return null;
    } catch (e) {
      print('❌ Error finding user: $e');
      return null;
    }
  }

  // Get user by ID (check both tables)
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      // Search in login_student
      final studentResponse = await supabase
          .from('login_student')
          .select('id, email, name')
          .eq('id', userId)
          .limit(1);

      if (studentResponse.isNotEmpty) {
        return {
          ...studentResponse.first,
          'user_type': 'student',
        };
      }

      // Search in login_teacher
      final teacherResponse = await supabase
          .from('login_teacher')
          .select('id, email, name')
          .eq('id', userId)
          .limit(1);

      if (teacherResponse.isNotEmpty) {
        return {
          ...teacherResponse.first,
          'user_type': 'teacher',
        };
      }

      return null;
    } catch (e) {
      print('❌ Error getting user by ID: $e');
      return null;
    }
  }

  // ========== CHAT OPERATIONS ==========

  // Get all chats for current user
  Future<List<Map<String, dynamic>>> getUserChats() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      print('🔍 Getting chats for user: ${user.email}');

      // First, get chat IDs where user is a member
      final memberResponse = await supabase
          .from('chat_member')
          .select('chat_id')
          .eq('user_id', user.id);

      print('📊 User is in ${memberResponse.length} chats');

      if (memberResponse.isEmpty) return [];

      final chatIds = memberResponse.map((m) => m['chat_id'] as String).toList();

      // Then get those chats
      final chatResponse = await supabase
          .from('chat')
          .select('*')
          .in_('id', chatIds)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(chatResponse);
    } catch (e) {
      print('❌ Error in getUserChats: $e');
      return [];
    }
  }

  // Get individual chats (not groups)
  Future<List<Map<String, dynamic>>> getIndividualChats() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      // Get individual chat IDs where user is a member
      final memberResponse = await supabase
          .from('chat_member')
          .select('chat_id')
          .eq('user_id', user.id);

      if (memberResponse.isEmpty) return [];

      final chatIds = memberResponse.map((m) => m['chat_id'] as String).toList();

      // Get those individual chats
      final chatResponse = await supabase
          .from('chat')
          .select('*')
          .in_('id', chatIds)
          .eq('is_group', false)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(chatResponse);
    } catch (e) {
      print('❌ Error in getIndividualChats: $e');
      return [];
    }
  }

  // Get group chats
  Future<List<Map<String, dynamic>>> getGroupChats() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      // Get group chat IDs where user is a member
      final memberResponse = await supabase
          .from('chat_member')
          .select('chat_id')
          .eq('user_id', user.id);

      if (memberResponse.isEmpty) return [];

      final chatIds = memberResponse.map((m) => m['chat_id'] as String).toList();

      // Get those group chats
      final chatResponse = await supabase
          .from('chat')
          .select('*')
          .in_('id', chatIds)
          .eq('is_group', true)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(chatResponse);
    } catch (e) {
      print('❌ Error in getGroupChats: $e');
      return [];
    }
  }

  // Create individual chat
  Future<Map<String, dynamic>?> createIndividualChat(String otherUserEmail) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      print('🔄 Creating chat with: $otherUserEmail');

      // 1. Find the other user in your tables
      final otherUser = await findUserByEmail(otherUserEmail);
      if (otherUser == null) {
        print('❌ User not found: $otherUserEmail');
        return null;
      }

      print('✅ Found user: ${otherUser['email']} (${otherUser['user_type']})');

      // 2. Check if chat already exists (simplified check)
      final existingChats = await supabase
          .from('chat')
          .select('id, name')
          .eq('is_group', false)
          .ilike('name', '%${user.email}%')
          .ilike('name', '%${otherUser['email']}%');

      if (existingChats.isNotEmpty) {
        print('✅ Chat already exists');
        return existingChats.first;
      }

      // 3. Create new chat
      final chatResponse = await supabase
          .from('chat')
          .insert({
            'name': '${user.email} & ${otherUser['email']}',
            'is_group': false,
            'created_by': user.id,
          })
          .select();

      if (chatResponse.isEmpty) {
        print('❌ Chat creation failed');
        return null;
      }

      final chat = chatResponse.first;
      final chatId = chat['id'];
      print('✅ Created chat with ID: $chatId');

      // 4. Add both users as members
      await supabase.from('chat_member').insert([
        {
          'chat_id': chatId,
          'user_id': user.id,
          'role': 'member',
          'is_admin': true,
        },
        {
          'chat_id': chatId,
          'user_id': otherUser['id'],
          'role': 'member',
          'is_admin': false,
        },
      ]);

      print('✅ Added both users as members');

      // 5. Add welcome message
      await supabase.from('messages').insert({
        'chat_id': chatId,
        'user_id': user.id,
        'content': 'Chat started!',
      });

      print('✅ Added welcome message');
      return chat;
    } catch (e) {
      print('❌ Error creating individual chat: $e');
      return null;
    }
  }

  // Create group chat
  Future<Map<String, dynamic>?> createGroupChat(String groupName, List<String> memberEmails) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      print('🔄 Creating group: $groupName');

      // 1. Create chat
      final chatResponse = await supabase
          .from('chat')
          .insert({
            'name': groupName,
            'is_group': true,
            'created_by': user.id,
          })
          .select();

      if (chatResponse.isEmpty) {
        print('❌ Group creation failed');
        return null;
      }

      final chat = chatResponse.first;
      final chatId = chat['id'];
      print('✅ Created group with ID: $chatId');

      // 2. Add creator as admin
      await supabase.from('chat_member').insert({
        'chat_id': chatId,
        'user_id': user.id,
        'role': 'admin',
        'is_admin': true,
      });

      print('✅ Added creator as admin');

      // 3. Add other members
      int addedCount = 0;
      for (final email in memberEmails) {
        if (email.isNotEmpty && email != user.email) {
          final member = await findUserByEmail(email);
          if (member != null) {
            await supabase.from('chat_member').insert({
              'chat_id': chatId,
              'user_id': member['id'],
              'role': 'member',
              'is_admin': false,
            });
            addedCount++;
            print('✅ Added member: $email');
          } else {
            print('⚠️ Could not find member: $email');
          }
        }
      }

      print('✅ Added $addedCount members');

      // 4. Add welcome message
      await supabase.from('messages').insert({
        'chat_id': chatId,
        'user_id': user.id,
        'content': 'Group "$groupName" created!',
      });

      print('✅ Added welcome message');
      return chat;
    } catch (e) {
      print('❌ Error creating group chat: $e');
      return null;
    }
  }

  // ========== MESSAGE OPERATIONS ==========

  // Get messages for a chat
  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    try {
      final response = await supabase
          .from('messages')
          .select('*')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error in getMessages: $e');
      return [];
    }
  }

  // Get messages with sender info
  Future<List<Map<String, dynamic>>> getMessagesWithSender(String chatId) async {
    try {
      final messages = await getMessages(chatId);
      
      // Enrich each message with sender info
      final enrichedMessages = <Map<String, dynamic>>[];
      
      for (final message in messages) {
        final sender = await getUserById(message['user_id'].toString());
        
        enrichedMessages.add({
          ...message,
          'sender': sender ?? {
            'id': message['user_id'],
            'email': 'Unknown User',
            'name': 'Unknown',
            'user_type': 'unknown',
          },
        });
      }
      
      return enrichedMessages;
    } catch (e) {
      print('❌ Error in getMessagesWithSender: $e');
      return await getMessages(chatId);
    }
  }

  // Send a message
  Future<bool> sendMessage(String chatId, String content) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await supabase.from('messages').insert({
        'chat_id': chatId,
        'user_id': user.id,
        'content': content,
      });

      // Update chat's updated_at timestamp
      await supabase
          .from('chat')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);

      print('✅ Message sent successfully');
      return true;
    } catch (e) {
      print('❌ Error sending message: $e');
      return false;
    }
  }

  // ========== UTILITY METHODS ==========

  // Search users by email (in both tables)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final results = <Map<String, dynamic>>[];

      // Search in login_student
      final studentResponse = await supabase
          .from('login_student')
          .select('id, email, name')
          .ilike('email', '%$query%')
          .limit(5);

      for (final student in studentResponse) {
        results.add({
          ...student,
          'user_type': 'student',
        });
      }

      // Search in login_teacher
      final teacherResponse = await supabase
          .from('login_teacher')
          .select('id, email, name')
          .ilike('email', '%$query%')
          .limit(5);

      for (final teacher in teacherResponse) {
        results.add({
          ...teacher,
          'user_type': 'teacher',
        });
      }

      // Remove duplicates (by email)
      final uniqueResults = <String, Map<String, dynamic>>{};
      for (final user in results) {
        uniqueResults[user['email']] = user;
      }

      return uniqueResults.values.toList();
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }

  // Test database connection
  Future<void> testConnection() async {
    try {
      print('🔌 Testing database connection...');
      print('Current user: ${currentUser?.email}');
      
      // Test if tables exist
      final tables = ['chat', 'chat_member', 'messages', 'login_student', 'login_teacher'];
      
      for (final table in tables) {
        try {
          final test = await supabase.from(table).select('count').limit(1);
          print('✅ $table table: OK (found ${test.length} rows)');
        } catch (e) {
          print('❌ $table table: Error - $e');
        }
      }
      
    } catch (e) {
      print('❌ Connection test failed: $e');
    }
  }

  // Get current user's info from your tables
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    final user = currentUser;
    if (user == null) return null;

    return await findUserByEmail(user.email!);
  }
}