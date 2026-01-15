import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_models.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Matcha Green Color Palette
  static const Color matchaGreen = Color(0xFF87A96B);
  static const Color matchaLight = Color(0xFFC8D5B9);
  static const Color matchaDark = Color(0xFF5F7A4E);
  static const Color bgLight = Color(0xFFF8FAF6);

  Group? _group;
  bool _isAdmin = false;
  bool _isCreator = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
  }

  Future<void> _loadGroupInfo() async {
    try {
      final group = await _chatService.getGroupDetails(widget.groupId);
      final currentUserId = _chatService.currentUserId;

      if (currentUserId != null) {
        final isAdmin = await _chatService.isGroupAdmin(widget.groupId, currentUserId);
        final isCreator = await _chatService.isGroupCreator(widget.groupId, currentUserId);

        setState(() {
          _group = group;
          _isAdmin = isAdmin;
          _isCreator = isCreator;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ralat memuatkan maklumat kumpulan: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      await _chatService.sendGroupMessage(widget.groupId, message);
      _messageController.clear();

      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghantar mesej: $e'),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GroupInfoSheet(
        groupId: widget.groupId,
        isAdmin: _isAdmin,
        isCreator: _isCreator,
        onGroupUpdated: _loadGroupInfo,
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Hari Ini';
    } else if (messageDate == yesterday) {
      return 'Semalam';
    } else if (now.difference(date).inDays < 7) {
      const days = ['Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat', 'Sabtu', 'Ahad'];
      return days[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildDateSeparator(DateTime date) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: matchaLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _getDateSeparator(date),
          style: TextStyle(
            fontSize: 12,
            color: matchaDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMessagesWithDateSeparators(List<ChatMessage> messages) {
    List<Widget> widgets = [];
    DateTime? lastDate;

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final messageDate = DateTime(
        message.createdAt.year,
        message.createdAt.month,
        message.createdAt.day,
      );

      if (lastDate == null || messageDate != lastDate) {
        widgets.add(_buildDateSeparator(message.createdAt));
        lastDate = messageDate;
      }

      final isMe = message.senderId == _chatService.currentUserId;
      final isSystem = message.type == 'system';

      if (isSystem) {
        widgets.add(
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: matchaLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: matchaGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 14, color: matchaDark),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      message.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: matchaDark,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isMe ? matchaGreen : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && message.senderName != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName!,
                        style: TextStyle(
                          color: matchaDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.createdAt),
                    style: TextStyle(
                      color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgLight,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(matchaGreen),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: matchaDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: _showGroupInfo,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: matchaGreen,
                radius: 20,
                child: Icon(Icons.group, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _group?.name ?? 'Kumpulan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: matchaDark,
                      ),
                    ),
                    Text(
                      '${_group?.memberCount ?? 0} ahli',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: matchaDark),
            onPressed: _showGroupInfo,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 800;
          
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<ChatMessage>>(
                      stream: _chatService.getGroupMessages(widget.groupId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Ralat: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(matchaGreen),
                            ),
                          );
                        }

                        final messages = snapshot.data!;

                        if (messages.isEmpty) {
                          return Center(
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
                                  'Tiada mesej lagi',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: matchaDark,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Mulakan perbualan!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        });

                        return ListView(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: isWideScreen ? 32 : 16,
                            vertical: 16,
                          ),
                          children: _buildMessagesWithDateSeparators(messages),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(isWideScreen ? 20 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgLight,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Taip mesej...',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: bgLight,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [matchaGreen, matchaDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: matchaGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
class _GroupInfoSheet extends StatefulWidget {
  final String groupId;
  final bool isAdmin;
  final bool isCreator;
  final VoidCallback onGroupUpdated;

  const _GroupInfoSheet({
    required this.groupId,
    required this.isAdmin,
    required this.isCreator,
    required this.onGroupUpdated,
  });

  @override
  State<_GroupInfoSheet> createState() => _GroupInfoSheetState();
}

class _GroupInfoSheetState extends State<_GroupInfoSheet> {
  final ChatService _chatService = ChatService();
  
  // Matcha Green Color Palette
  static const Color matchaGreen = Color(0xFF87A96B);
  static const Color matchaLight = Color(0xFFC8D5B9);
  static const Color matchaDark = Color(0xFF5F7A4E);
  static const Color bgLight = Color(0xFFF8FAF6);
  
  Group? _group;
  List<GroupMember> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      final group = await _chatService.getGroupDetails(widget.groupId);
      final members = await _chatService.getGroupMembers(widget.groupId);

      setState(() {
        _group = group;
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      print('Ralat memuatkan data kumpulan: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _group?.name);
    final descController = TextEditingController(text: _group?.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: matchaGreen),
            SizedBox(width: 12),
            Text('Edit Kumpulan'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Kumpulan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: matchaGreen, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: matchaGreen, width: 2),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _chatService.updateGroupInfo(
                  widget.groupId,
                  nameController.text.trim(),
                  descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                _loadGroupData();
                widget.onGroupUpdated();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kumpulan berjaya dikemaskini'),
                    backgroundColor: matchaGreen,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ralat: $e'),
                    backgroundColor: Colors.red[400],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: matchaGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddMembersDialog() async {
    final searchController = TextEditingController();
    List<ChatUser> searchResults = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.person_add, color: matchaGreen),
                SizedBox(width: 12),
                Text('Tambah Ahli'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari menggunakan email...',
                      prefixIcon: Icon(Icons.search, color: matchaGreen),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: matchaGreen, width: 2),
                      ),
                    ),
                    onChanged: (query) async {
                      if (query.isEmpty) {
                        setDialogState(() {
                          searchResults = [];
                          isSearching = false;
                        });
                        return;
                      }

                      setDialogState(() => isSearching = true);

                      final results = await _chatService.searchUsers(query);
                      final currentMemberIds = _members.map((m) => m.userId).toList();
                      final filtered = results.where((u) => !currentMemberIds.contains(u.id)).toList();

                      setDialogState(() {
                        searchResults = filtered;
                        isSearching = false;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: isSearching
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(matchaGreen),
                            ),
                          )
                        : searchResults.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_search, size: 60, color: Colors.grey[400]),
                                    SizedBox(height: 16),
                                    Text(
                                      'Cari pengguna untuk ditambah',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  final user = searchResults[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: matchaGreen,
                                      child: Text(
                                        user.name[0].toUpperCase(),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(user.name),
                                    subtitle: Text(user.email),
                                    trailing: IconButton(
                                      icon: Icon(Icons.add_circle, color: matchaGreen),
                                      onPressed: () async {
                                        try {
                                          await _chatService.addGroupMembers(
                                            widget.groupId,
                                            [user.id],
                                          );
                                          if (!mounted) return;
                                          Navigator.pop(context);
                                          _loadGroupData();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Ahli berjaya ditambah'),
                                              backgroundColor: matchaGreen,
                                            ),
                                          );
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Ralat: $e'),
                                              backgroundColor: Colors.red[400],
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMemberOptions(GroupMember member) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: matchaGreen,
                child: Text(
                  member.userName?[0].toUpperCase() ?? '?',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                member.userName ?? 'Tidak Diketahui',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(member.userEmail ?? ''),
            ),
            Divider(),
            if ((widget.isAdmin || widget.isCreator) && member.userId != _group?.createdBy)
              ListTile(
                leading: Icon(
                  member.isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
                  color: matchaGreen,
                ),
                title: Text(member.isAdmin ? 'Buang sebagai Admin' : 'Jadikan Admin'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    if (member.isAdmin) {
                      await _chatService.demoteFromAdmin(widget.groupId, member.userId);
                    } else {
                      await _chatService.promoteToAdmin(widget.groupId, member.userId);
                    }
                    _loadGroupData();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(member.isAdmin ? 'Admin dibuang' : 'Admin ditambah'),
                        backgroundColor: matchaGreen,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ralat: $e'),
                        backgroundColor: Colors.red[400],
                      ),
                    );
                  }
                },
              ),
            if ((widget.isAdmin || widget.isCreator) && member.userId != _group?.createdBy)
              ListTile(
                leading: Icon(Icons.remove_circle, color: Colors.red[400]),
                title: Text('Keluarkan dari Kumpulan', style: TextStyle(color: Colors.red[400])),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _chatService.removeGroupMember(widget.groupId, member.userId);
                    _loadGroupData();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ahli dikeluarkan'),
                        backgroundColor: matchaGreen,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ralat: $e'),
                        backgroundColor: Colors.red[400],
                      ),
                    );
                  }
                },
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar dari Kumpulan'),
        content: Text('Adakah anda pasti mahu keluar dari kumpulan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _chatService.leaveGroup(widget.groupId);
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat: $e'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Padam Kumpulan'),
        content: Text('Adakah anda pasti? Ini akan memadam kumpulan untuk semua orang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Padam'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _chatService.deleteGroup(widget.groupId);
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat: $e'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(matchaGreen),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                CircleAvatar(
                  backgroundColor: matchaGreen,
                  radius: 40,
                  child: Icon(Icons.group, color: Colors.white, size: 40),
                ),
                SizedBox(height: 16),
                Text(
                  _group?.name ?? 'Kumpulan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: matchaDark,
                  ),
                ),
                if (_group?.description != null) ...[
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _group!.description!,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: matchaLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_members.length} ahli',
                    style: TextStyle(
                      color: matchaDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (widget.isAdmin || widget.isCreator) ...[
                  ListTile(
                    leading: Icon(Icons.edit, color: matchaGreen),
                    title: Text('Edit Kumpulan'),
                    onTap: _showEditDialog,
                  ),
                  ListTile(
                    leading: Icon(Icons.person_add, color: matchaGreen),
                    title: Text('Tambah Ahli'),
                    onTap: _showAddMembersDialog,
                  ),
                  Divider(height: 1),
                ],
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.people, color: matchaGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Senarai Ahli',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: matchaDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final isCreator = member.userId == _group?.createdBy;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: matchaGreen,
                          child: Text(
                            member.userName?[0].toUpperCase() ?? '?',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          member.userName ?? 'Tidak Diketahui',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(member.userEmail ?? '', style: TextStyle(fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCreator)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: matchaGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Pencipta',
                                  style: TextStyle(fontSize: 10, color: Colors.white),
                                ),
                              )
                            else if (member.isAdmin)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: matchaLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Admin',
                                  style: TextStyle(fontSize: 10, color: matchaDark),
                                ),
                              ),
                            if ((widget.isAdmin || widget.isCreator) &&
                                member.userId != _chatService.currentUserId)
                              IconButton(
                                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                                onPressed: () => _showMemberOptions(member),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Divider(height: 1),
                if (!widget.isCreator)
                  ListTile(
                    leading: Icon(Icons.exit_to_app, color: Colors.red[400]),
                    title: Text('Keluar dari Kumpulan', style: TextStyle(color: Colors.red[400])),
                    onTap: _leaveGroup,
                  ),
                if (widget.isCreator)
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red[400]),
                    title: Text('Padam Kumpulan', style: TextStyle(color: Colors.red[400])),
                    onTap: _deleteGroup,
                  ),
                SizedBox(height: 20),
              ],
            ),
    );
  }
}
