import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({Key? key}) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _memberEmailController = TextEditingController();
  final List<String> _memberEmails = [];
  bool _loading = false;

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila masukkan nama kumpulan')),
      );
      return;
    }

    if (_memberEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila tambah sekurang-kurangnya satu ahli')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    final chat = await _chatService.createGroupChat(groupName, _memberEmails);
    
    setState(() {
      _loading = false;
    });

    if (chat != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kumpulan berjaya dicipta!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mencipta kumpulan')),
      );
    }
  }

  void _addMember() {
    final email = _memberEmailController.text.trim();
    if (email.isEmpty) return;

    final currentUserEmail = _chatService.currentUser?.email;
    if (email == currentUserEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda ditambah secara automatik sebagai pentadbir')),
      );
      _memberEmailController.clear();
      return;
    }

    if (_memberEmails.contains(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengguna ini sudah ditambah')),
      );
      return;
    }

    setState(() {
      _memberEmails.add(email);
      _memberEmailController.clear();
    });
  }

  void _removeMember(int index) {
    setState(() {
      _memberEmails.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cipta Sembang Kumpulan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kumpulan',
                hintText: 'Masukkan nama kumpulan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tambah Ahli',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _memberEmailController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan e-mel ahli',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (_) => _addMember(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addMember,
                  child: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Ahli:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_memberEmails.length}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _memberEmails.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada ahli ditambah',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _memberEmails.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                _memberEmails[index][0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(_memberEmails[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeMember(index),
                              tooltip: 'Buang',
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _createGroup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Cipta Kumpulan',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _memberEmailController.dispose();
    super.dispose();
  }
}