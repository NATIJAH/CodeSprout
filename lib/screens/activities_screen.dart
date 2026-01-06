import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_activity_screen.dart';

class StudentActivitiesScreen extends StatefulWidget {
  const StudentActivitiesScreen({super.key});

  @override
  State<StudentActivitiesScreen> createState() => _StudentActivitiesScreenState();
}

class _StudentActivitiesScreenState extends State<StudentActivitiesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Upcoming', 'Completed', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _fetchStudentActivities();
  }

  Future<void> _fetchStudentActivities() async {
    try {
      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Fetch activities created by this student
      final data = await supabase
          .from('activities')
          .select('*')
          .eq('created_by', user.id) // Assuming you have created_by field
          .order('created_at', ascending: false);

      setState(() {
        _activities = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching student activities: $e");
      // If table doesn't exist or error, show sample data
      _loadSampleActivities();
    }
  }

  void _loadSampleActivities() {
    // Sample data for testing
    setState(() {
      _activities = [
        {
          'id': '1',
          'title': 'Group Project Meeting',
          'description': 'Meet with team to discuss final project',
          'category': 'Meeting',
          'priority': 'High',
          'date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
          'time': '14:00',
          'status': 'upcoming',
          'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': '2',
          'title': 'Math Assignment',
          'description': 'Complete chapter 5 exercises',
          'category': 'Assignment',
          'priority': 'Medium',
          'date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'time': '23:59',
          'status': 'upcoming',
          'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        },
        {
          'id': '3',
          'title': 'Study Session',
          'description': 'Review for upcoming exam',
          'category': 'Review',
          'priority': 'Medium',
          'date': DateTime.now().toIso8601String(),
          'time': '19:00',
          'status': 'completed',
          'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        },
        {
          'id': '4',
          'title': 'Science Quiz Preparation',
          'description': 'Prepare notes for quiz',
          'category': 'Quiz',
          'priority': 'Low',
          'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'time': '10:00',
          'status': 'overdue',
          'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
        },
      ];
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredActivities {
    if (_selectedFilter == 'All') return _activities;
    
    return _activities.where((activity) {
      final status = activity['status']?.toString().toLowerCase() ?? '';
      switch (_selectedFilter) {
        case 'Upcoming':
          return status == 'upcoming' || status == 'pending';
        case 'Completed':
          return status == 'completed' || status == 'done';
        case 'Overdue':
          return status == 'overdue' || status == 'late';
        default:
          return true;
      }
    }).toList();
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'meeting':
        return Icons.people;
      case 'quiz':
        return Icons.quiz;
      case 'assignment':
        return Icons.assignment;
      case 'lab':
        return Icons.science;
      case 'presentation':
        return Icons.slideshow;
      case 'review':
        return Icons.reviews;
      case 'planning':
        return Icons.event_note;
      case 'research':
        return Icons.search;
      default:
        return Icons.event;
    }
  }

  String _formatDateTime(String dateString, String time) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at $time';
    } catch (e) {
      return '$dateString at $time';
    }
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, int index) {
    final priorityColor = _getPriorityColor(activity['priority'] ?? 'Medium');
    final categoryIcon = _getCategoryIcon(activity['category'] ?? 'Activity');
    final status = activity['status']?.toString().toLowerCase() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(categoryIcon, color: priorityColor),
        ),
        title: Text(
          activity['title'] ?? 'Untitled Activity',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              activity['description'] ?? 'No description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    activity['category'] ?? 'General',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.grey[100],
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    activity['priority'] ?? 'Medium',
                    style: TextStyle(
                      fontSize: 12,
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: priorityColor.withOpacity(0.1),
                  side: BorderSide(color: priorityColor.withOpacity(0.3)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(activity['date'] ?? '', activity['time'] ?? ''),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: _buildStatusBadge(status),
        onTap: () {
          // Navigate to activity detail or edit screen
          _showActivityDetails(activity);
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusText = '✓ Done';
        break;
      case 'overdue':
        statusColor = Colors.red;
        statusText = '⚠ Overdue';
        break;
      case 'upcoming':
      case 'pending':
        statusColor = Colors.blue;
        statusText = '⏳ Pending';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    activity['title'] ?? 'Activity Details',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Category and Priority
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: _getCategoryIcon(activity['category'] ?? ''),
                      label: 'Category',
                      value: activity['category'] ?? 'Not specified',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.flag,
                      label: 'Priority',
                      value: activity['priority'] ?? 'Medium',
                      valueColor: _getPriorityColor(activity['priority'] ?? 'Medium'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Date and Time
              _buildDetailItem(
                icon: Icons.calendar_today,
                label: 'Date & Time',
                value: _formatDateTime(activity['date'] ?? '', activity['time'] ?? ''),
              ),
              
              const SizedBox(height: 20),
              
              // Description
              const Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                activity['description'] ?? 'No description provided',
                style: TextStyle(color: Colors.grey[700]),
              ),
              
              const SizedBox(height: 30),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _editActivity(activity);
                      },
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteActivity(activity['id']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: valueColor ?? Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _editActivity(Map<String, dynamic> activity) {
    // Navigate to edit screen (could use the same CreateActivityScreen with edit mode)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateActivityScreen(), // You might want to pass activity data for editing
      ),
    );
  }

  void _deleteActivity(String activityId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Delete from database
                await supabase
                    .from('activities')
                    .delete()
                    .eq('id', activityId);
                
                // Refresh the list
                _fetchStudentActivities();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Activity deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // Remove from local list if DB operation fails
                setState(() {
                  _activities.removeWhere((activity) => activity['id'] == activityId);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted locally: $e'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 My Activities'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.grey[50],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.blue[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      showCheckmark: false,
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Statistics Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(_activities.length, 'Total', Colors.blue),
                _buildStatItem(
                  _activities.where((a) => a['status']?.toString().toLowerCase() == 'upcoming').length,
                  'Upcoming',
                  Colors.green,
                ),
                _buildStatItem(
                  _activities.where((a) => a['status']?.toString().toLowerCase() == 'completed').length,
                  'Completed',
                  Colors.blue,
                ),
                _buildStatItem(
                  _activities.where((a) => a['status']?.toString().toLowerCase() == 'overdue').length,
                  'Overdue',
                  Colors.red,
                ),
              ],
            ),
          ),
          
          // Activities List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredActivities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.event_note,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No activities found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _selectedFilter == 'All'
                                  ? 'Create your first activity!'
                                  : 'No ${_selectedFilter.toLowerCase()} activities',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredActivities.length,
                        itemBuilder: (context, index) {
                          return _buildActivityCard(_filteredActivities[index], index);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateActivityScreen()),
          ).then((value) {
            // Refresh list when returning from create screen
            if (value == true) {
              _fetchStudentActivities();
            }
          });
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatItem(int count, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}