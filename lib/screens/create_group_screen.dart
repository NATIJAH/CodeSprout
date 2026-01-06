import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_models.dart';
import 'group_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Matcha Green Color Palette
  static const Color matchaGreen = Color(0xFF87A96B);
  static const Color matchaLight = Color(0xFFC8D5B9);
  static const Color matchaDark = Color(0xFF5F7A4E);
  static const Color bgLight = Color(0xFFF8FAF6);

  List<ChatUser> _searchResults = [];
  List<ChatUser> _selectedMembers = [];
  bool _isSearching = false;
  bool _isCreating = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _chatService.searchUsers(query);
      
      final filteredResults = results.where((user) {
        return !_selectedMembers.any((selected) => selected.id == user.id);
      }).toList();

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ralat mencari: $e'),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  void _toggleMember(ChatUser user) {
    setState(() {
      final index = _selectedMembers.indexWhere((m) => m.id == user.id);
      if (index >= 0) {
        _selectedMembers.removeAt(index);
      } else {
        if (_selectedMembers.length >= 99) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maksimum 99 ahli sahaja'),
              backgroundColor: Colors.orange[400],
            ),
          );
          return;
        }
        _selectedMembers.add(user);
      }
      _searchUsers(_searchController.text);
    });
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sila masukkan nama kumpulan'),
          backgroundColor: Colors.orange[400],
        ),
      );
      return;
    }

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sila tambah sekurang-kurangnya seorang ahli'),
          backgroundColor: Colors.orange[400],
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final memberIds = _selectedMembers.map((m) => m.id).toList();
      final groupId = await _chatService.createGroup(
        groupName,
        _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        memberIds,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GroupChatScreen(groupId: groupId),
        ),
      );
    } catch (e) {
      setState(() => _isCreating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ralat mencipta kumpulan: $e'),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  Widget _buildStepOne() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [matchaGreen, matchaDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: matchaGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.group_add, color: Colors.white, size: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Butiran Kumpulan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Masukkan nama dan keterangan',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Kumpulan *',
                    hintText: 'Contoh: Kelas 5A, Kumpulan Belajar',
                    prefixIcon: Icon(Icons.group, color: matchaGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: matchaLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: matchaLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: matchaGreen, width: 2),
                    ),
                    filled: true,
                    fillColor: bgLight,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Keterangan (Pilihan)',
                    hintText: 'Tentang kumpulan ini...',
                    prefixIcon: Icon(Icons.description, color: matchaGreen),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: matchaLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: matchaLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: matchaGreen, width: 2),
                    ),
                    filled: true,
                    fillColor: bgLight,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_groupNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sila masukkan nama kumpulan'),
                      backgroundColor: Colors.orange[400],
                    ),
                  );
                  return;
                }
                setState(() => _currentStep = 1);
              },
              icon: Icon(Icons.arrow_forward, size: 20),
              label: Text(
                'Seterusnya: Tambah Ahli',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: matchaGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTwo() {
    return Column(
      children: [
        if (_selectedMembers.isNotEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: matchaGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Dipilih: ${_selectedMembers.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: matchaDark,
                      ),
                    ),
                    Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _selectedMembers.clear());
                        _searchUsers(_searchController.text);
                      },
                      icon: Icon(Icons.clear_all, size: 18),
                      label: Text('Kosongkan'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[400],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedMembers.map((user) {
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: matchaGreen,
                        child: Text(
                          user.name[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      label: Text(user.name),
                      deleteIcon: Icon(Icons.close, size: 18),
                      onDeleted: () => _toggleMember(user),
                      backgroundColor: matchaLight.withOpacity(0.3),
                      deleteIconColor: matchaDark,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        Padding(
          padding: EdgeInsets.all(16),
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
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari menggunakan email...',
                prefixIcon: Icon(Icons.search, color: matchaGreen),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _searchUsers,
            ),
          ),
        ),

        Expanded(
          child: _isSearching
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(matchaGreen),
                  ),
                )
              : _searchResults.isEmpty
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
                              Icons.person_search,
                              size: 80,
                              color: matchaGreen,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Cari pengguna menggunakan email'
                                : 'Tiada pengguna dijumpai',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 135, 182, 106),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Taip email untuk cari ahli'
                                : 'Cuba cari dengan email lain',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final isSelected = _selectedMembers.any((m) => m.id == user.id);

                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? matchaGreen 
                                  : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: matchaGreen,
                              child: Text(
                                user.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: const Color.fromARGB(255, 135, 182, 106),
                              ),
                            ),
                            subtitle: Text(
                              user.email,
                              style: TextStyle(fontSize: 13),
                            ),
                            trailing: Icon(
                              isSelected ? Icons.check_circle : Icons.add_circle_outline,
                              color: isSelected ? matchaGreen : Colors.grey,
                              size: 28,
                            ),
                            onTap: () => _toggleMember(user),
                          ),
                        );
                      },
                    ),
        ),

        Container(
          padding: EdgeInsets.all(16),
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
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createGroup,
                icon: _isCreating
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.check_circle, size: 22),
                label: Text(
                  _isCreating
                      ? 'Mencipta...'
                      : 'Cipta Kumpulan (${_selectedMembers.length + 1} ahli)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: matchaGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 135, 182, 106)),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _currentStep == 0 ? 'Cipta Kumpulan' : 'Tambah Ahli',
          style: TextStyle(
            color: const Color.fromARGB(255, 161, 196, 139),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _currentStep == 0 ? _buildStepOne() : _buildStepTwo(),
    );
  }
}