import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';

class ChatHomeScreen extends StatefulWidget {
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
  Map<String, dynamic>? _userProfile;

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
    
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sila log masuk untuk menggunakan sembang')),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }

    _userProfile = await _chatService.getCurrentUserProfile();
    
    print('=== PERMULAAN SEMBANG ===');
    print('ID pengguna semasa: ${_currentUser?.id}');
    print('E-mel pengguna semasa: ${_currentUser?.email}');
    print('Profil pengguna: $_userProfile');
    
    await _loadChats();

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadChats() async {
    try {
      final individual = await _chatService.getIndividualChats();
      final groups = await _chatService.getGroupChats();

      print('Dimuatkan ${individual.length} sembang individu');
      print('Dimuatkan ${groups.length} sembang kumpulan');

      setState(() {
        _individualChats = individual;
        _groupChats = groups;
      });
    } catch (e) {
      print('Ralat memuatkan sembang: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ralat memuatkan sembang: $e')),
      );
    }
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
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sembang Baharu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Masukkan alamat e-mel',
                hintText: 'pengguna@contoh.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sila masukkan e-mel')),
                );
                return;
              }

              if (email == _currentUser?.email) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tidak boleh sembang dengan diri sendiri')),
                );
                return;
              }

              Navigator.pop(context);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              final chat = await _chatService.createIndividualChat(email);
              
              Navigator.pop(context);

              if (chat != null) {
                await _loadChats();
                _navigateToChat(chat);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal mencipta sembang. Pengguna mungkin tidak wujud.'),
                  ),
                );
              }
            },
            child: const Text('Cipta'),
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
    if (_userProfile != null && _userProfile!['name'] != null) {
      return _userProfile!['name'];
    }
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      return widget.userName!;
    }
    return _currentUser?.email?.split('@').first ?? 'Pengguna';
  }

  String _getUserType() {
    if (_userProfile != null && _userProfile!['user_type'] != null) {
      final type = _userProfile!['user_type'];
      return type == 'student' ? 'Pelajar' : type == 'teacher' ? 'Guru' : 'Pengguna';
    }
    if (widget.userType != null) {
      final type = widget.userType!.toLowerCase();
      return type == 'student' ? 'Pelajar' : type == 'teacher' ? 'Guru' : widget.userType!;
    }
    return 'Pengguna';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sembang ${_getDisplayName()}'),
            Text(
              '(${_getUserType()})',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Individu'),
            Tab(text: 'Kumpulan'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChats,
            tooltip: 'Muat Semula',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildIndividualChatsTab(),
                _buildGroupChatsTab(),
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
        tooltip: _tabController.index == 0 ? 'Sembang Baharu' : 'Cipta Kumpulan',
      ),
    );
  }

  Widget _buildIndividualChatsTab() {
    if (_individualChats.isEmpty) {
      return Center(
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
              'Tiada sembang individu lagi',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _createNewIndividualChat,
              icon: const Icon(Icons.add),
              label: const Text('Mulakan Sembang Baharu'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _individualChats.length,
      itemBuilder: (context, index) {
        final chat = _individualChats[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            title: Text(
              chat['name'] ?? 'Sembang Tanpa Nama',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Ketik untuk buka sembang'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToChat(chat),
          ),
        );
      },
    );
  }

  Widget _buildGroupChatsTab() {
    if (_groupChats.isEmpty) {
      return Center(
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
              'Tiada sembang kumpulan lagi',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _createNewGroupChat,
              icon: const Icon(Icons.group_add),
              label: const Text('Cipta Kumpulan'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _groupChats.length,
      itemBuilder: (context, index) {
        final chat = _groupChats[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.group, color: Colors.green),
            ),
            title: Text(
              chat['name'] ?? 'Kumpulan Tanpa Nama',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Sembang kumpulan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToChat(chat),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
