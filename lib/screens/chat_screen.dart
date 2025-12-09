import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> chatData;

  const ChatScreen({Key? key, required this.chatData}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startAutoRefresh();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
    });

    final messages = await _chatService.getMessagesWithSender(widget.chatData['id']);
    
    setState(() {
      _messages = messages;
      _loading = false;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadMessages();
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final success = await _chatService.sendMessage(widget.chatData['id'], message);
    
    if (success) {
      _messageController.clear();
      _loadMessages();
    }
  }

  String _getChatName() {
    final chat = widget.chatData;
    if (chat['is_group'] == true) {
      return chat['name'] ?? 'Group Chat';
    } else {
      final currentUserEmail = _chatService.currentUser?.email ?? '';
      final chatName = chat['name'] ?? '';
      final parts = chatName.split(' & ');
      if (parts.length == 2) {
        return parts[0] == currentUserEmail ? parts[1] : parts[0];
      }
      return chatName;
    }
  }

  String _getSenderName(Map<String, dynamic> message) {
    // Get sender info from enriched message
    if (message['sender'] != null) {
      final sender = message['sender'];
      if (sender['name'] != null && sender['name'].toString().isNotEmpty) {
        return sender['name'].toString();
      }
      if (sender['email'] != null) {
        return sender['email'].toString().split('@').first;
      }
    }
    
    // Fallback
    return 'User ${message['user_id'].toString().substring(0, 8)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getChatName()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            Text(
                              'Start the conversation!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message['user_id'] == _chatService.currentUser?.id;
                          
                          return ChatBubble(
                            message: message['content'],
                            isMe: isMe,
                            senderName: _getSenderName(message),
                            timestamp: DateTime.parse(message['created_at']),
                          );
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8.0),
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}