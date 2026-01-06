import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherCompletedTask extends StatefulWidget {
  const TeacherCompletedTask({super.key});

  @override
  _TeacherCompletedTaskState createState() => _TeacherCompletedTaskState();
}

class _TeacherCompletedTaskState extends State<TeacherCompletedTask> {
  final supabase = Supabase.instance.client;
  Map<String, String> studentNames = {};
  
  // Matcha Green Color Palette
  static const Color matchaGreen = Color(0xFF87A96B);
  static const Color matchaLight = Color(0xFFC8D5B9);
  static const Color matchaDark = Color(0xFF5F7A4E);
  static const Color matchaAccent = Color(0xFFA4C2A5);
  static const Color bgLight = Color(0xFFF8FAF6);
  
  String sortBy = 'due_date';
  bool ascending = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      // FIXED: Changed 'uid' to 'id' to match actual column name
      final data = await supabase.from('profile_student').select('id, name');
      final Map<String, String> map = {};
      for (var s in data) {
        // FIXED: Use 'id' instead of 'uid'
        final id = s['id'];
        final name = s['name'];
        if (id != null) {
          map[id.toString()] = name?.toString() ?? 'Unknown';
        }
      }
      setState(() {
        studentNames = map;
      });
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCompletedTasks() async {
    try {
      final data = await supabase
          .from('Tasks')
          .select()
          .eq('status_text', 'completed');
      
      List<Map<String, dynamic>> tasks = List<Map<String, dynamic>>.from(data);
      
      tasks.sort((a, b) {
        int comparison = 0;
        
        switch (sortBy) {
          case 'due_date':
            final aDate = DateTime.tryParse(a['due_date']?.toString() ?? '') ?? DateTime(1970);
            final bDate = DateTime.tryParse(b['due_date']?.toString() ?? '') ?? DateTime(1970);
            comparison = aDate.compareTo(bDate);
            break;
          case 'title':
            final aTitle = a['title']?.toString() ?? '';
            final bTitle = b['title']?.toString() ?? '';
            comparison = aTitle.compareTo(bTitle);
            break;
          case 'completed_timestamp':
            final aDate = DateTime.tryParse(a['completed_timestamp']?.toString() ?? '') ?? DateTime(1970);
            final bDate = DateTime.tryParse(b['completed_timestamp']?.toString() ?? '') ?? DateTime(1970);
            comparison = aDate.compareTo(bDate);
            break;
        }
        
        return ascending ? comparison : -comparison;
      });
      
      return tasks;
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  String _getSortLabel() {
    switch (sortBy) {
      case 'due_date':
        return 'Tarikh Akhir';
      case 'completed_timestamp':
        return 'Tarikh Selesai';
      case 'title':
        return 'Tajuk';
      default:
        return 'Tarikh Akhir';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: matchaDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tugasan Selesai',
          style: TextStyle(
            color: matchaDark,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 800;
          
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 1200),
              padding: EdgeInsets.all(isWideScreen ? 32 : 16),
              child: Column(
                children: [
                  // Stats and Filter Header
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
                        Expanded(
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: fetchCompletedTasks(),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.length ?? 0;
                              return Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.task_alt,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$count Tugasan',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Telah Diselesaikan',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PopupMenuButton<String>(
                            icon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sort, color: matchaDark),
                                SizedBox(width: 8),
                                Text(
                                  'Isih',
                                  style: TextStyle(
                                    color: matchaDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              setState(() {
                                if (value == 'toggle_order') {
                                  ascending = !ascending;
                                } else {
                                  sortBy = value;
                                }
                              });
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'due_date',
                                child: Row(
                                  children: [
                                    Icon(
                                      sortBy == 'due_date' ? Icons.check : Icons.calendar_today,
                                      size: 20,
                                      color: sortBy == 'due_date' ? matchaGreen : Colors.grey,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Isih mengikut Tarikh Akhir'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'completed_timestamp',
                                child: Row(
                                  children: [
                                    Icon(
                                      sortBy == 'completed_timestamp' ? Icons.check : Icons.check_circle,
                                      size: 20,
                                      color: sortBy == 'completed_timestamp' ? matchaGreen : Colors.grey,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Isih mengikut Tarikh Selesai'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'title',
                                child: Row(
                                  children: [
                                    Icon(
                                      sortBy == 'title' ? Icons.check : Icons.title,
                                      size: 20,
                                      color: sortBy == 'title' ? matchaGreen : Colors.grey,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Isih mengikut Tajuk'),
                                  ],
                                ),
                              ),
                              PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'toggle_order',
                                child: Row(
                                  children: [
                                    Icon(
                                      ascending ? Icons.arrow_upward : Icons.arrow_downward,
                                      size: 20,
                                      color: matchaGreen,
                                    ),
                                    SizedBox(width: 12),
                                    Text(ascending ? 'Menaik' : 'Menurun'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Filter Chips
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ascending ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 16,
                              color: matchaDark,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${_getSortLabel()} - ${ascending ? "Menaik" : "Menurun"}',
                              style: TextStyle(
                                color: matchaDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Search Bar
                  Container(
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
                        hintText: 'Cari tugasan atau pelajar...',
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
                  SizedBox(height: 24),
                  
                  // Tasks Grid
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchCompletedTasks(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(matchaGreen),
                            ),
                          );
                        }

                        var tasks = snapshot.data!;
                        
                        // Apply search filter
                        if (_searchQuery.isNotEmpty) {
                          tasks = tasks.where((task) {
                            final title = task['title']?.toString().toLowerCase() ?? '';
                            final studentUid = task['student_uid']?.toString() ?? '';
                            final studentName = studentNames[studentUid]?.toLowerCase() ?? '';
                            return title.contains(_searchQuery.toLowerCase()) ||
                                   studentName.contains(_searchQuery.toLowerCase());
                          }).toList();
                        }

                        if (tasks.isEmpty) {
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
                                    Icons.task_alt,
                                    size: 80,
                                    color: matchaGreen,
                                  ),
                                ),
                                SizedBox(height: 24),
                                Text(
                                  _searchQuery.isEmpty 
                                      ? 'Tiada tugasan selesai lagi'
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
                                      ? 'Tugasan yang diselesaikan akan dipaparkan di sini'
                                      : 'Cuba cari dengan kata kunci lain',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isWideScreen ? 3 : (constraints.maxWidth > 600 ? 2 : 1),
                            childAspectRatio: 1.3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            // FIXED: Safe null handling for student_uid
                            final studentUid = task['student_uid']?.toString() ?? '';
                            Supabase.instance.client;
                            
                            final completedDate = task['completed_timestamp'] != null
                                ? DateTime.tryParse(task['completed_timestamp'].toString())
                                : null;
                            
                            final dueDate = task['due_date'] != null
                                ? DateTime.tryParse(task['due_date'].toString())
                                : null;

                            return InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Container(
                                      constraints: BoxConstraints(maxWidth: 500),
                                      padding: EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: matchaLight,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.task_alt,
                                                  color: matchaDark,
                                                  size: 28,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  task['title']?.toString() ?? 'Tanpa Tajuk',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: matchaDark,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 24),
                                          _buildDetailRow(
                                            Icons.person,
                                            'Pelajar',
                                            studentUid,
                                          ),
                                          SizedBox(height: 12),
                                          _buildDetailRow(
                                            Icons.description,
                                            'Keterangan',
                                            task['description_text']?.toString() ?? 'Tiada keterangan',
                                          ),
                                          SizedBox(height: 12),
                                          if (dueDate != null)
                                            _buildDetailRow(
                                              Icons.calendar_today,
                                              'Tarikh Akhir',
                                              '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                                            ),
                                          SizedBox(height: 12),
                                          if (completedDate != null)
                                            _buildDetailRow(
                                              Icons.check_circle,
                                              'Tarikh Selesai',
                                              '${completedDate.day}/${completedDate.month}/${completedDate.year}',
                                              color: matchaGreen,
                                            ),
                                          SizedBox(height: 24),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton(
                                              onPressed: () => Navigator.pop(context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: matchaGreen,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 24,
                                                  vertical: 16,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text('Tutup'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: matchaLight.withOpacity(0.5),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: matchaGreen.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Green check indicator
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: matchaGreen,
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(14),
                                            bottomLeft: Radius.circular(14),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: matchaLight.withOpacity(0.3),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  Icons.assignment_turned_in,
                                                  color: matchaDark,
                                                  size: 24,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  task['title']?.toString() ?? 'Tanpa Tajuk',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: matchaDark,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Spacer(),
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: bgLight,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      size: 16,
                                                      color: matchaDark,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        studentUid,
                                                        style: TextStyle(
                                                          color: matchaDark,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (dueDate != null) ...[
                                                  SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.calendar_today,
                                                        size: 16,
                                                        color: Colors.grey[600],
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Akhir: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                                                        style: TextStyle(
                                                          color: Colors.grey[700],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                if (completedDate != null) ...[
                                                  SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.check_circle,
                                                        size: 16,
                                                        color: matchaGreen,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          'Selesai: ${completedDate.day}/${completedDate.month}/${completedDate.year}',
                                                          style: TextStyle(
                                                            color: matchaGreen,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
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
                        );
                      },
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

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? matchaGreen).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color ?? matchaDark),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: matchaDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}