import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'student_task.dart';
import 'student_teaching_material.dart';
import 'student_pdf.dart';
import 'student_mcq.dart';
import 'student_chat.dart';
import 'student_profile.dart';
import 'activities_screen.dart';
import 'activity_hub.dart';
import 'login_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('activities')
          .select()
          .order('date', ascending: true);
      
      setState(() {
        _activities = List<Map<String, dynamic>>.from(data ?? []);
      });
    } catch (e) {
      debugPrint('Error loading activities: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout error: $e")),
      );
    }
  }

  void _showActivityForm() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final timeController = TextEditingController();
    String selectedCategory = 'Assignment';
    String selectedPriority = 'Medium';

    final categories = ['Assignment', 'Quiz', 'Lab', 'Project', 'Other'];
    final priorities = ['Low', 'Medium', 'High', 'Urgent'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Activity'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Activity Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time (HH:MM)',
                  border: OutlineInputBorder(),
                  hintText: '14:30',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  selectedCategory = value ?? 'Assignment';
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: priorities
                    .map((pri) => DropdownMenuItem(value: pri, child: Text(pri)))
                    .toList(),
                onChanged: (value) {
                  selectedPriority = value ?? 'Medium';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a title')),
                );
                return;
              }

              try {
                final user = supabase.auth.currentUser;
                if (user == null) return;

                await supabase.from('activities').insert({
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'category': selectedCategory,
                  'priority': selectedPriority,
                  'date': DateFormat('yyyy-MM-dd').format(_selectedDay),
                  'time': timeController.text,
                  'created_by': user.id,
                  'user_email': user.email,
                  'status': 'pending',
                  'created_at': DateTime.now().toIso8601String(),
                });

                Navigator.pop(ctx);
                await _loadActivities();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Activity created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getActivitiesForDay(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    return _activities.where((act) => act['date'] == dateStr).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cards = [
      {'title': "📌 Task", 'color': Colors.green[300]!, 'page': const StudentTask()},
      {'title': "📚 Teaching", 'color': Colors.green[400]!, 'page': const StudentTeachingMaterial()},
      {'title': "📄 PDF", 'color': Colors.green[300]!, 'page': const StudentPdf()},
      {'title': "❓ MCQ", 'color': Colors.green[400]!, 'page': const StudentMcq()},
      {'title': "💬 Chat", 'color': Colors.green[300]!, 'page': const StudentChat()},
      {'title': "👤 Profile", 'color': Colors.green[400]!, 'page': const StudentProfile()},
      {'title': "📋 Activity", 'color': Colors.green[400]!, 'page': const ActivityHub()},
    ];

    return Scaffold(
      backgroundColor: const Color(0xffdfeee7),
      appBar: AppBar(
        title: const Text("👩‍🎓 Student Dashboard"),
        backgroundColor: const Color(0xff4f7f67),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Welcome message
              FutureBuilder(
                future: Supabase.instance.client.auth.getUser(),
                builder: (context, snapshot) {
                  String username = "Student";
                  if (snapshot.hasData && snapshot.data != null) {
                    final user = snapshot.data!.user;
                    if (user != null && user.email != null) {
                      username = user.email!.split('@').first;
                    }
                  }
                  
                  return Container(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        Text(
                          "Welcome 👋, $username!",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2c4a3f),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "What would you like to do today?",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // Grid of Cards
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 85,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => card['page']),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: card['color'],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            card['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 30),
              
              // Calendar Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '📅 Activity Calendar',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2d3d38),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showActivityForm,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Activity'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff7a9e8f),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: const Color(0xff7a9e8f),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: const Color(0xffb8cfc5),
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Activities for selected day
                    Text(
                      'Activities for ${DateFormat('MMM d, yyyy').format(_selectedDay)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2d3d38),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: Stream.value(_getActivitiesForDay(_selectedDay)),
                      builder: (context, snapshot) {
                        final activities = _getActivitiesForDay(_selectedDay);
                        if (activities.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: const Text(
                              'No activities for this day',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activities.length,
                          itemBuilder: (context, index) {
                            final activity = activities[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(activity['title'] ?? 'Untitled'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(activity['description'] ?? ''),
                                    Text(
                                      'Time: ${activity['time'] ?? 'N/A'} | Category: ${activity['category'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(activity['priority'] ?? 'Medium'),
                                  backgroundColor: _getPriorityColor(activity['priority']),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Logout button
              SizedBox(
                width: 200,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Urgent':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }
}