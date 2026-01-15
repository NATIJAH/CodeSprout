import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_models.dart';
import 'chat_screen.dart';
import 'search_user_screen.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  List<Conversation> _conversations = [];
  List<Group> _groups = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Matcha Green Color Palette
  static const Color matchaGreen = Color(0xFF87A96B);
  static const Color matchaLight = Color(0xFFC8D5B9);
  static const Color matchaDark = Color(0xFF5F7A4E);
  static const Color bgLight = Color(0xFFF8FAF6);

  @override
  void initState() {
    super.initState();
    _loadAllChats();
  }

  Future<void> _loadAllChats() async {
    print('🔄 Memuatkan semua chat...');
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _chatService.getConversations(),
        _chatService.getGroups(),
      ]);

      final conversations = results[0] as List<Conversation>;
      final groups = results[1] as List<Group>;

      print('✅ Dimuat ${conversations.length} perbualan');
      print('✅ Dimuat ${groups.length} kumpulan');

      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Ralat memuatkan chat: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _getOtherUserName(Conversation conv) {
    final myId = _chatService.currentUserId;
    if (conv.user1Id == myId) {
      return conv.user2Name ?? conv.user2Email ?? 'Tidak Diketahui';
    } else {
      return conv.user1Name ?? conv.user1Email ?? 'Tidak Diketahui';
    }
  }

  String _getOtherUserId(Conversation conv) {
    final myId = _chatService.currentUserId;
    if (conv.user1Id == myId) {
      return conv.user2Id;
    } else {
      return conv.user1Id;
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Semalam';
    } else if (diff.inDays < 7) {
      const days = ['Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat', 'Sabtu', 'Ahad'];
      return days[time.weekday - 1];
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  List<_ChatItem> _getCombinedList() {
    List<_ChatItem> items = [];

    for (var conv in _conversations) {
      final name = _getOtherUserName(conv);
      if (_searchQuery.isEmpty || 
          name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (conv.lastMessage?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)) {
        items.add(_ChatItem(
          type: _ChatItemType.conversation,
          conversation: conv,
          lastMessageTime: conv.lastMessageTime,
        ));
      }
    }

    for (var group in _groups) {
      if (_searchQuery.isEmpty || 
          group.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        items.add(_ChatItem(
          type: _ChatItemType.group,
          group: group,
          lastMessageTime: group.lastMessageTime,
        ));
      }
    }

    items.sort((a, b) {
      final aTime = a.lastMessageTime ?? DateTime(2000);
      final bTime = b.lastMessageTime ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUserId;
    final combinedList = _getCombinedList();

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Mesej',
          style: TextStyle(
            color: matchaDark,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          if (currentUserId != null)
            StreamBuilder<int>(
              stream: _chatService.getTotalUnreadCount(currentUserId),
              builder: (context, snapshot) {
                final totalUnread = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.group_add, color: matchaDark),
                      tooltip: 'Cipta Kumpulan',
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateGroupScreen(),
                          ),
                        );
                        if (result == true) _loadAllChats();
                      },
                    ),
                    if (totalUnread > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            totalUnread > 99 ? '99+' : '$totalUnread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.person_add, color: matchaDark),
            tooltip: 'Chat Baru',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchUserScreen(),
                ),
              );
              if (result == true) _loadAllChats();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 800;
          
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 1000),
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: EdgeInsets.all(isWideScreen ? 24 : 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Cari chat atau kumpulan...',
                          prefixIcon: Icon(Icons.search, color: matchaGreen),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(matchaGreen),
                            ),
                          )
                        : combinedList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: matchaLight.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline,
                                        size: 80,
                                        color: matchaGreen,
                                      ),
                                    ),
                                    SizedBox(height: 24),
                                    Text(
                                      _searchQuery.isEmpty 
                                          ? 'Tiada perbualan lagi'
                                          : 'Tiada hasil carian',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: matchaDark,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _searchQuery.isEmpty
                                          ? 'Mulakan chat dengan kawan anda'
                                          : 'Cuba cari dengan kata kunci lain',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadAllChats,
                                color: matchaGreen,
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isWideScreen ? 24 : 16,
                                    vertical: 8,
                                  ),
                                  itemCount: combinedList.length,
                                  itemBuilder: (context, index) {
                                    final item = combinedList[index];

                                    if (item.type == _ChatItemType.conversation) {
                                      final conv = item.conversation!;
                                      final otherUserName = _getOtherUserName(conv);
                                      final otherUserId = _getOtherUserId(conv);

                                      return Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 5,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          leading: CircleAvatar(
                                            backgroundColor: matchaGreen,
                                            radius: 28,
                                            child: Text(
                                              otherUserName[0].toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            otherUserName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: matchaDark,
                                            ),
                                          ),
                                          subtitle: Padding(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Text(
                                              conv.lastMessage ?? 'Tiada mesej',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _formatTime(conv.lastMessageTime),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              if (currentUserId != null)
                                                StreamBuilder<int>(
                                                  stream: _chatService.getUnreadCountFromUser(
                                                    currentUserId,
                                                    otherUserId,
                                                  ),
                                                  builder: (context, snapshot) {
                                                    final unreadCount = snapshot.data ?? 0;
                                                    if (unreadCount == 0) {
                                                      return const SizedBox.shrink();
                                                    }
                                                    return Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: matchaGreen,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      constraints: BoxConstraints(minWidth: 22),
                                                      child: Text(
                                                        unreadCount > 99 ? '99+' : '$unreadCount',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ],
                                          ),
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ChatScreen(
                                                  conversationId: conv.id,
                                                  otherUserId: otherUserId,
                                                  otherUserName: otherUserName,
                                                ),
                                              ),
                                            );
                                            _loadAllChats();
                                          },
                                        ),
                                      );
                                    } else {
                                      final group = item.group!;

                                      return Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 5,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          leading: CircleAvatar(
                                            backgroundColor: matchaGreen,
                                            radius: 28,
                                            child: Icon(
                                              Icons.group,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  group.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: matchaDark,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: matchaLight.withOpacity(0.3),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.people,
                                                      size: 12,
                                                      color: matchaDark,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '${group.memberCount}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: matchaDark,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Padding(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Text(
                                              group.lastMessage ?? 'Tiada mesej lagi',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          trailing: Text(
                                            _formatTime(group.lastMessageTime),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => GroupChatScreen(
                                                  groupId: group.id,
                                                ),
                                              ),
                                            );
                                            _loadAllChats();
                                          },
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _ChatItemType { conversation, group }

class _ChatItem {
  final _ChatItemType type;
  final Conversation? conversation;
  final Group? group;
  final DateTime? lastMessageTime;

  _ChatItem({
    required this.type,
    this.conversation,
    this.group,
    this.lastMessageTime,
  });
}