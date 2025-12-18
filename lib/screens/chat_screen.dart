import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';

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
  bool _sending = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    if (_chatService.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sila log masuk untuk menggunakan sembang')),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }

    await _loadMessages();
    _startPolling();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    
    setState(() {
      _loading = true;
    });

    try {
      final messages = await _chatService.getMessagesWithSender(widget.chatData['id']);
      
      print('=== MESEJ DIMUATKAN ===');
      print('ID Sembang: ${widget.chatData['id']}');
      print('Bilangan mesej: ${messages.length}');
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _loading = false;
        });

        _scrollToBottom();
      }
    } catch (e) {
      print('Ralat memuatkan mesej: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat memuatkan mesej: $e')),
        );
      }
    }
  }

  void _startPolling() {
    // Poll for new messages every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _loadMessages();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _sending) return;

    if (_chatService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila log masuk untuk menghantar mesej')),
      );
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      print('=== MENGHANTAR MESEJ ===');
      print('ID Sembang: ${widget.chatData['id']}');
      print('ID Pengguna: ${_chatService.currentUser?.id}');
      print('Mesej: $message');

      final success = await _chatService.sendMessage(
        widget.chatData['id'],
        message,
      );

      if (success) {
        _messageController.clear();
        print('Mesej berjaya dihantar');
        await _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghantar mesej')),
        );
      }
    } catch (e) {
      print('Ralat dalam _sendMessage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ralat menghantar mesej: $e')),
      );
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  String _getChatName() {
    final chat = widget.chatData;
    if (chat['is_group'] == true) {
      return chat['name'] ?? 'Sembang Kumpulan';
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
    if (message['sender'] != null) {
      final sender = message['sender'];
      if (sender['name'] != null && sender['name'].toString().isNotEmpty) {
        return sender['name'].toString();
      }
      if (sender['email'] != null) {
        return sender['email'].toString().split('@').first;
      }
    }
    
    return 'Pengguna';
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Semalam';
    } else if (difference.inDays < 7) {
      final days = ['Ahad', 'Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat', 'Sabtu'];
      return days[timestamp.weekday % 7];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
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
            tooltip: 'Muat Semula',
          ),
          if (widget.chatData['is_group'] == true)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Maklumat Kumpulan'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nama: ${widget.chatData['name']}'),
                        const SizedBox(height: 8),
                        Text('Dicipta: ${_formatTime(DateTime.parse(widget.chatData['created_at']))}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Maklumat',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Tiada mesej lagi',
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mulakan perbualan!',
                              style: TextStyle(color: Colors.grey.shade500),
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
                          final timestamp = DateTime.parse(message['created_at']);
                          
                          return _buildMessageBubble(
                            content: message['content'] ?? '',
                            isMe: isMe,
                            senderName: _getSenderName(message),
                            timestamp: timestamp,
                          );
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String content,
    required bool isMe,
    required String senderName,
    required DateTime timestamp,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue.shade500 : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe && widget.chatData['is_group'] == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            Text(
              content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Taip mesej...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
                enabled: !_sending,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8.0),
            _sending
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                      tooltip: 'Hantar',
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }
}
