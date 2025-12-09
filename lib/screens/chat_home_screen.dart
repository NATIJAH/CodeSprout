import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  // Add these optional parameters
  final String? userType;
  final String? userId;
  final String? userName;

  const ChatHomeScreen({
    Key? key,
    this.userType,
    this.userId,
    this.userName,
  }) : super(key: key);

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  late TabController _tabController;
  List<Map<String, dynamic>> _individualChats = [];
  List<Map<String, dynamic>> _groupChats = [];
  bool _loading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
    });

    _currentUser = _chatService.currentUser;
    
    // Log the user info (remove in production)
    print('Current user: ${_currentUser?.email}');
    if (widget.userType != null) {
      print('User type from params: ${widget.userType}');
    }
    if (widget.userName != null) {
      print('User name from params: ${widget.userName}');
    }
    
    await _loadChats();

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadChats() async {
    final individual = await _chatService.getIndividualChats();
    final groups = await _chatService.getGroupChats();

    setState(() {
      _individualChats = individual;
      _groupChats = groups;
    });
  }

  void _navigateToChat(Map<String, dynamic> chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatData: chat),
      ),
    );
  }

  void _createNewIndividualChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Enter email address',
                hintText: 'user@example.com',
              ),
              onSubmitted: (email) async {
                if (email.isNotEmpty) {
                  Navigator.pop(context);
                  final chat = await _chatService.createIndividualChat(email);
                  if (chat != null) {
                    _loadChats();
                    _navigateToChat(chat);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create chat')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _createNewGroupChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GroupChatScreen(),
      ),
    ).then((_) => _loadChats());
  }

  String _getDisplayName() {
    // Use provided userName, or current user's email, or default
    return widget.userName ?? _currentUser?.email?.split('@').first ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_getDisplayName()}\'s Chats'),
            if (widget.userType != null)
              Text(
                '(${widget.userType})',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Individual'),
            Tab(text: 'Groups'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChats,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Individual Chats Tab
                _individualChats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No individual chats yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _createNewIndividualChat,
                              child: const Text('Start New Chat'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _individualChats.length,
                        itemBuilder: (context, index) {
                          final chat = _individualChats[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(chat['name'] ?? 'Unnamed Chat'),
                            subtitle: const Text('Tap to open chat'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _navigateToChat(chat),
                          );
                        },
                      ),

                // Group Chats Tab
                _groupChats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.group_outlined,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No group chats yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _createNewGroupChat,
                              child: const Text('Create Group'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _groupChats.length,
                        itemBuilder: (context, index) {
                          final chat = _groupChats[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.group),
                            ),
                            title: Text(chat['name'] ?? 'Unnamed Group'),
                            subtitle: const Text('Group chat'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _navigateToChat(chat),
                          );
                        },
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _createNewIndividualChat();
          } else {
            _createNewGroupChat();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}