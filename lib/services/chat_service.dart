import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_models.dart';

class ChatService {
  final _supabase = Supabase.instance.client;

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ============= NOTIFICATION FUNCTIONS START =============

  // Count total unread messages for current user
  Stream<int> getTotalUnreadCount(String userId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((messages) {
      return messages.where((msg) {
        return msg['receiver_id'] == userId && msg['is_read'] == false;
      }).length;
    });
  }

  // Count unread messages from specific user in a conversation
  Stream<int> getUnreadCountFromUser(String currentUserId, String otherUserId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((messages) {
      return messages.where((msg) {
        return msg['receiver_id'] == currentUserId &&
            msg['sender_id'] == otherUserId &&
            msg['is_read'] == false;
      }).length;
    });
  }

  // Mark all messages as read in a conversation
  Future<void> markMessagesAsRead(String conversationId, String currentUserId) async {
    try {
      print('📖 Marking messages as read in conversation: $conversationId');

      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .eq('receiver_id', currentUserId)
          .eq('is_read', false);

      print('✅ Messages marked as read');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  // ============= NOTIFICATION FUNCTIONS END =============

  // ============= 1-TO-1 CHAT FUNCTIONS START =============

  // Search users by email
  Future<List<ChatUser>> searchUsers(String email) async {
    try {
      print('🔍 Searching for: $email');

      final studentResponse = await _supabase
          .from('profile_student')
          .select('id, email, full_name')
          .ilike('email', '%$email%')
          .limit(10);

      print('Students found: ${studentResponse.length}');

      final teacherResponse = await _supabase
          .from('profile_teacher')
          .select('id, email, full_name')
          .ilike('email', '%$email%')
          .limit(10);

      print('Teachers found: ${teacherResponse.length}');

      List<ChatUser> users = [];

      for (var student in studentResponse) {
        users.add(ChatUser(
          id: student['id'],
          email: student['email'],
          name: student['full_name'] ?? student['email'],
          role: 'student',
        ));
      }

      for (var teacher in teacherResponse) {
        users.add(ChatUser(
          id: teacher['id'],
          email: teacher['email'],
          name: teacher['full_name'] ?? teacher['email'],
          role: 'teacher',
        ));
      }

      users.removeWhere((user) => user.id == currentUserId);

      print('Total users found (excluding self): ${users.length}');
      return users;
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }

  // Create or get existing conversation
  Future<String> createOrGetConversation(String otherUserId) async {
    try {
      final myId = currentUserId;
      if (myId == null) throw Exception('Not logged in');

      print('🔄 Creating/getting conversation');
      print('   My ID: $myId');
      print('   Other ID: $otherUserId');

      final existing = await _supabase
          .from('conversations')
          .select('id')
          .or('and(user1_id.eq.$myId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$myId)')
          .maybeSingle();

      if (existing != null) {
        print('✅ Found existing conversation: ${existing['id']}');
        return existing['id'];
      }

      final response = await _supabase
          .from('conversations')
          .insert({
        'user1_id': myId,
        'user2_id': otherUserId,
      })
          .select('id')
          .single();

      print('✅ Created new conversation: ${response['id']}');
      return response['id'];
    } catch (e) {
      print('❌ Error creating conversation: $e');
      rethrow;
    }
  }

  // Get all conversations for current user
  Future<List<Conversation>> getConversations() async {
    try {
      final myId = currentUserId;
      if (myId == null) return [];

      print('📋 Getting conversations for user: $myId');

      final response = await _supabase
          .from('conversations')
          .select('*')
          .or('user1_id.eq.$myId,user2_id.eq.$myId')
          .order('last_message_time', ascending: false);

      print('📋 Found ${response.length} conversations from database');

      List<Conversation> conversations = [];

      for (var data in response) {
        print('   Processing conversation: ${data['id']}');

        final user1Info = await getUserInfo(data['user1_id']);
        print('   User1 info: ${user1Info?.email}');

        final user2Info = await getUserInfo(data['user2_id']);
        print('   User2 info: ${user2Info?.email}');

        conversations.add(Conversation(
          id: data['id'],
          user1Id: data['user1_id'],
          user2Id: data['user2_id'],
          lastMessage: data['last_message'],
          lastMessageTime: data['last_message_time'] != null
              ? DateTime.parse(data['last_message_time'])
              : null,
          user1Email: user1Info?.email,
          user1Name: user1Info?.name,
          user2Email: user2Info?.email,
          user2Name: user2Info?.name,
        ));
      }

      print('📋 Returning ${conversations.length} conversations');
      return conversations;
    } catch (e) {
      print('❌ Error getting conversations: $e');
      print('   Error details: ${e.toString()}');
      return [];
    }
  }

  // Send message (1-to-1)
  Future<void> sendMessage(String conversationId, String message) async {
    try {
      final myId = currentUserId;
      if (myId == null) throw Exception('Not logged in');

      print('📤 Sending message...');
      print('   Conversation ID: $conversationId');
      print('   Sender ID: $myId');
      print('   Message: $message');

      final convResponse = await _supabase
          .from('conversations')
          .select('user1_id, user2_id')
          .eq('id', conversationId)
          .single();

      final receiverId = convResponse['user1_id'] == myId
          ? convResponse['user2_id']
          : convResponse['user1_id'];

      final insertResponse = await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': myId,
        'receiver_id': receiverId,
        'message': message,
        'is_read': false,
        'type': 'personal',
      }).select();

      print('✅ Message inserted: $insertResponse');

      final updateResponse = await _supabase.from('conversations').update({
        'last_message': message,
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('id', conversationId).select();

      print('✅ Conversation updated: $updateResponse');
    } catch (e) {
      print('❌ Error sending message: $e');
      print('   Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('   Code: ${e.code}');
        print('   Details: ${e.details}');
        print('   Hint: ${e.hint}');
        print('   Message: ${e.message}');
      }
      rethrow;
    }
  }

  // Get messages for a conversation
  Stream<List<ChatMessage>> getMessages(String conversationId) {
    print('📥 Setting up message stream for conversation: $conversationId');

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) {
      print('📨 Stream data received: ${data.length} messages');
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    });
  }

  // Get user info by ID
  Future<ChatUser?> getUserInfo(String userId) async {
    try {
      final studentResponse = await _supabase
          .from('profile_student')
          .select('id, email, full_name')
          .eq('id', userId)
          .maybeSingle();

      if (studentResponse != null) {
        return ChatUser(
          id: studentResponse['id'],
          email: studentResponse['email'],
          name: studentResponse['full_name'] ?? studentResponse['email'],
          role: 'student',
        );
      }

      final teacherResponse = await _supabase
          .from('profile_teacher')
          .select('id, email, full_name')
          .eq('id', userId)
          .maybeSingle();

      if (teacherResponse != null) {
        return ChatUser(
          id: teacherResponse['id'],
          email: teacherResponse['email'],
          name: teacherResponse['full_name'] ?? teacherResponse['email'],
          role: 'teacher',
        );
      }

      return null;
    } catch (e) {
      print('❌ Error getting user info: $e');
      return null;
    }
  }

  // ============= 1-TO-1 CHAT FUNCTIONS END =============

  // ============= GROUP CHAT FUNCTIONS START =============

  // Create new group
  Future<String> createGroup(String name, String? description, List<String> memberIds) async {
    try {
      final myId = currentUserId;
      if (myId == null) throw Exception('Not logged in');

      print('🎉 Creating group: $name');
      print('   Creator: $myId');
      print('   Members: $memberIds');

      // Check member limit
      if (memberIds.length >= 100) {
        throw Exception('Maximum 100 members allowed');
      }

      // Create group
      final groupResponse = await _supabase.from('groups').insert({
        'name': name,
        'description': description,
        'created_by': myId,
      }).select().single();

      final groupId = groupResponse['id'];
      print('✅ Group created: $groupId');

      // Add creator as admin
      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': myId,
        'is_admin': true,
      });

      // Add other members
      for (var memberId in memberIds) {
        if (memberId != myId) {
          await _supabase.from('group_members').insert({
            'group_id': groupId,
            'user_id': memberId,
            'is_admin': false,
          });
        }
      }

      // Send system message
      final creatorInfo = await getUserInfo(myId);
      await _sendGroupSystemMessage(
        groupId,
        '${creatorInfo?.name ?? 'Someone'} created the group',
      );

      print('✅ Group setup complete');
      return groupId;
    } catch (e) {
      print('❌ Error creating group: $e');
      rethrow;
    }
  }

  // Get all groups for current user
  Future<List<Group>> getGroups() async {
    try {
      final myId = currentUserId;
      if (myId == null) return [];

      print('📋 Getting groups for user: $myId');

      // Get groups where user is a member
      final memberResponse = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', myId);

      final groupIds = memberResponse.map((m) => m['group_id'] as String).toList();

      if (groupIds.isEmpty) {
        print('📋 No groups found');
        return [];
      }

      // Get group details
      final groupsResponse = await _supabase
          .from('groups')
          .select('*')
          .in_('id', groupIds)
          .order('created_at', ascending: false);

      List<Group> groups = [];

      for (var data in groupsResponse) {
        // Count members
        final memberCount = await _supabase
            .from('group_members')
            .select('id', const FetchOptions(count: CountOption.exact))
            .eq('group_id', data['id']);

        // Get last message
        final lastMsg = await _supabase
            .from('messages')
            .select('message, created_at')
            .eq('group_id', data['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        groups.add(Group(
          id: data['id'],
          name: data['name'],
          description: data['description'],
          createdBy: data['created_by'],
          createdAt: DateTime.parse(data['created_at']),
          lastMessage: lastMsg?['message'],
          lastMessageTime: lastMsg?['created_at'] != null
              ? DateTime.parse(lastMsg['created_at'])
              : null,
          memberCount: memberCount.count ?? 0,
        ));
      }

      print('📋 Found ${groups.length} groups');
      return groups;
    } catch (e) {
      print('❌ Error getting groups: $e');
      return [];
    }
  }

  // Get group details
  Future<Group?> getGroupDetails(String groupId) async {
    try {
      final response = await _supabase
          .from('groups')
          .select('*')
          .eq('id', groupId)
          .single();

      final memberCount = await _supabase
          .from('group_members')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('group_id', groupId);

      return Group(
        id: response['id'],
        name: response['name'],
        description: response['description'],
        createdBy: response['created_by'],
        createdAt: DateTime.parse(response['created_at']),
        memberCount: memberCount.count ?? 0,
      );
    } catch (e) {
      print('❌ Error getting group details: $e');
      return null;
    }
  }

  // Get group members
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      print('👥 Getting members for group: $groupId');

      final response = await _supabase
          .from('group_members')
          .select('*')
          .eq('group_id', groupId)
          .order('joined_at', ascending: true);

      List<GroupMember> members = [];

      for (var data in response) {
        final userInfo = await getUserInfo(data['user_id']);
        members.add(GroupMember(
          id: data['id'],
          groupId: data['group_id'],
          userId: data['user_id'],
          isAdmin: data['is_admin'],
          joinedAt: DateTime.parse(data['joined_at']),
          userName: userInfo?.name,
          userEmail: userInfo?.email,
          userRole: userInfo?.role,
        ));
      }

      print('👥 Found ${members.length} members');
      return members;
    } catch (e) {
      print('❌ Error getting group members: $e');
      return [];
    }
  }

  // Check if user is admin
  Future<bool> isGroupAdmin(String groupId, String userId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select('is_admin')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .single();

      return response['is_admin'] == true;
    } catch (e) {
      return false;
    }
  }

  // Check if user is creator
  Future<bool> isGroupCreator(String groupId, String userId) async {
    try {
      final response = await _supabase
          .from('groups')
          .select('created_by')
          .eq('id', groupId)
          .single();

      return response['created_by'] == userId;
    } catch (e) {
      return false;
    }
  }

  // Add members to group
  Future<void> addGroupMembers(String groupId, List<String> memberIds) async {
    try {
      final myId = currentUserId;
      if (myId == null) throw Exception('Not logged in');

      print('➕ Adding members to group: $groupId');

      // Check if current user is admin or creator
      final isAdmin = await isGroupAdmin(groupId, myId);
      final isCreator = await isGroupCreator(groupId, myId);

      if (!isAdmin && !isCreator) {
        throw Exception('Only admins can add members');
      }

      // Check member limit
      final currentMembers = await getGroupMembers(groupId);
      if (currentMembers.length + memberIds.length > 100) {
        throw Exception('Cannot exceed 100 members');
      }

      final myInfo = await getUserInfo(myId);

      for (var memberId in memberIds) {
        // Check if already member
        final existing = await _supabase
            .from('group_members')
            .select('id')
            .eq('group_id', groupId)
            .eq('user_id', memberId)
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('group_members').insert({
            'group_id': groupId,
            'user_id': memberId,
            'is_admin': false,
          });

          final memberInfo = await getUserInfo(memberId);
          await _sendGroupSystemMessage(
            groupId,
            '${myInfo?.name ?? 'Someone'} added ${memberInfo?.name ?? 'someone'}',
          );
        }
      }

      print('✅ Members added successfully');
    } catch (e) {
      print('❌ Error adding members: $e');
      rethrow;
    }
  }

  // Remove member from group
  Future<void> removeGroupMember(String groupId, String memberId) async {
    try {
      final myId = currentUserId;
      if (myId == null) throw Exception('Not logged in');

      print('➖ Removing member from group: $groupId');

      // Check if trying to remove creator
      final isCreator = await isGroupCreator(groupId, memberId);
      if (isCreator) {
        throw Exception('Cannot remove group creator');
      }

      // Check if current user has permission
      final isMyAdmin = await isGroupAdmin(groupId, myId);
      final isMyCreator = await isGroupCreator(groupId, myId);

      if (!isMyAdmin && !isMyCreator) {
        throw Exception('Only admins can remove members');
      }

      final myInfo = await getUserInfo(myId);
      final memberInfo = await getUserInfo(memberId);

      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', memberId);

      await _sendGroupSystemMessage(
        groupId,
        '${myInfo?.name ?? 'Someone'} removed ${memberInfo?.name ?? 'someone'}',
      );

      print('✅ Member removed successfully');
    } catch (e) {
      print('❌ Error removing member: $e');
      rethrow;
    }
  }

  // Leave group
  Future<void> leaveGroup(String groupId) async {
    try {
      final myId = currentUserId;
      if (myId == null) throw Exception('Not logged in');

      print('🚪 Leaving group: $groupId');

      final isCreator = await isGroupCreator(groupId, myId);
      if (isCreator) {
        throw Exception('Creator cannot leave. Please delete the group or transfer ownership.');
      }

      final myInfo = await getUserInfo(myId);

      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', myId);

      await _sendGroupSystemMessage(
        groupId,
        '${myInfo?.name ?? 'Someone'} left the group',
      );

      print('✅ Left group successfully');
    } catch (e) {
      print('❌ Error leaving group: $e');
      rethrow;
    }
  }

  // Promote to admin
  Future<void> promoteToAdmin(String groupId, String memberId) async {
    try {
      final myId = currentUserId;
      if (myId == null) throw Exception('Not logged in');

      print('⬆️ Promoting to admin: $memberId');

      final isMyAdmin = await isGroupAdmin(groupId, myId);
      final isMyCreator = await isGroupCreator(groupId, myId);

      if (!isMyAdmin && !isMyCreator) {
        throw Exception('Only admins can promote members');
      }

      await _supabase
          .from('group_members')
          .update({'is_admin': true})
          .eq('group_id', groupId)
          .eq('user_id', memberId);

      final myInfo = await getUserInfo(myId);
      final memberInfo = await getUserInfo(memberId);

      await _sendGroupSystemMessage(
        groupId,
        '${myInfo?.name ?? 'Someone'} made ${memberInfo?.name ?? 'someone'} an admin',
      );

      print('✅ Member promoted successfully');
    } catch (e) {
      print('❌ Error promoting member: $e');
      rethrow;
    }
  }

  // Demote from admin
  Future<void> demoteFromAdmin(String groupId, String memberId) async {
    try {
      final myId = currentUserId;
      if (myId == null) throw Exception('Not logged in');

      print('⬇️ Demoting from admin: $memberId');

      final isCreator = await isGroupCreator(groupId, memberId);
      if (isCreator) {
        throw Exception('Cannot demote group creator');
      }

      final isMyAdmin = await isGroupAdmin(groupId, myId);
      final isMyCreator = await isGroupCreator(groupId, myId);

      if (!isMyAdmin && !isMyCreator) {
        throw Exception('Only admins can demote members');
      }

      await _supabase
          .from('group_members')
          .update({'is_admin': false})
          .eq('group_id', groupId)
          .eq('user_id', memberId);

      final myInfo = await getUserInfo(myId);
      final memberInfo = await getUserInfo(memberId);

      await _sendGroupSystemMessage(
        groupId,
        '${myInfo?.name ?? 'Someone'} removed ${memberInfo?.name ?? 'someone'} as admin',
      );

      print('✅ Member demoted successfully');
    } catch (e) {
      print('❌ Error demoting member: $e');
      rethrow;
    }
  }

  // Update group info
  Future<void> updateGroupInfo(String groupId, String name, String? description) async {
    try {
      final myId = currentUserId;
      if (myId == null) throw Exception('Not logged in');

      print('✏️ Updating group info: $groupId');

      final isAdmin = await isGroupAdmin(groupId, myId);
      final isCreator = await isGroupCreator(groupId, myId);

      if (!isAdmin && !isCreator) {
        throw Exception('Only admins can update group info');
      }

      // Get old name for notification
      final oldGroup = await getGroupDetails(groupId);

      await _supabase.from('groups').update({
        'name': name,
        'description': description,
      }).eq('id', groupId);

      if (oldGroup != null && oldGroup.name != name) {
        final myInfo = await getUserInfo(myId);
        await _sendGroupSystemMessage(
          groupId,
          '${myInfo?.name ?? 'Someone'} changed group name to "$name"',
        );
      }

      print('✅ Group info updated successfully');
    } catch (e) {
      print('❌ Error updating group info: $e');
      rethrow;
    }
  }

  // Delete group (creator only)
  Future<void> deleteGroup(String groupId) async {
    try {
      final myId = currentUserId;
      if (myId == null) throw Exception('Not logged in');

      print('🗑️ Deleting group: $groupId');

      final isCreator = await isGroupCreator(groupId, myId);
      if (!isCreator) {
        throw Exception('Only creator can delete the group');
      }

      await _supabase.from('groups').delete().eq('id', groupId);

      print('✅ Group deleted successfully');
    } catch (e) {
      print('❌ Error deleting group: $e');
      rethrow;
    }
  }

  // Send group message
  Future<void> sendGroupMessage(String groupId, String message) async {
    try {
      final myId = currentUserId;
      if (myId == null) throw Exception('Not logged in');

      print('📤 Sending group message...');
      print('   Group ID: $groupId');
      print('   Sender ID: $myId');

      await _supabase.from('messages').insert({
        'group_id': groupId,
        'sender_id': myId,
        'message': message,
        'type': 'group',
      });

      print('✅ Group message sent');
    } catch (e) {
      print('❌ Error sending group message: $e');
      rethrow;
    }
  }

  // Get group messages stream
  Stream<List<ChatMessage>> getGroupMessages(String groupId) {
    print('📥 Setting up group message stream: $groupId');

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: true)
        .asyncMap((data) async {
      print('📨 Group stream data received: ${data.length} messages');
      
      List<ChatMessage> messages = [];
      for (var json in data) {
        // Get sender info for ALL messages (including system messages)
        ChatUser? senderInfo;
        if (json['sender_id'] != null && json['sender_id'].toString().isNotEmpty) {
          senderInfo = await getUserInfo(json['sender_id']);
        }
        
        messages.add(ChatMessage(
          id: json['id'] ?? '',
          conversationId: json['conversation_id'] ?? '',
          senderId: json['sender_id'] ?? '',
          message: json['message'] ?? '',
          createdAt: DateTime.parse(json['created_at']),
          senderEmail: senderInfo?.email,
          senderName: senderInfo?.name,
          type: json['type'] ?? 'text',
          groupId: json['group_id'],
        ));
      }
      
      return messages;
    });
  }

  // Send system message (internal use)
  Future<void> _sendGroupSystemMessage(String groupId, String message) async {
    try {
      await _supabase.from('messages').insert({
        'group_id': groupId,
        'sender_id': currentUserId ?? '',
        'message': message,
        'type': 'system',
      });
    } catch (e) {
      print('❌ Error sending system message: $e');
    }
  }

  // ============= GROUP CHAT FUNCTIONS END =============
}