import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_activity_screen.dart';
import 'notification_list.dart';
import 'create_notification.dart';
import 'activities_screen.dart';
import 'performance_screen.dart';

class ActivityHub extends StatefulWidget {
  const ActivityHub({super.key});

  @override
  State<ActivityHub> createState() => _ActivityHubState();
}

class _ActivityHubState extends State<ActivityHub> {
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final teacherData = await Supabase.instance.client
          .from('profile_teacher')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      setState(() => _isTeacher = teacherData != null);
    } catch (e) {
      setState(() => _isTeacher = false);
    }
  }

  Widget _buildTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Aktiviti'),
        backgroundColor: const Color(0xff4f7f67),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tindakan Pantas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 110,
                ),
                children: [
                  // Notifikasi Tile
                  GestureDetector(
                    onTap: () {
                      if (_isTeacher) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Notifikasi'),
                            content: const Text('Apa yang anda ingin lakukan?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationListPage()));
                                },
                                child: const Text('Lihat Notifikasi'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => CreateNotificationScreen()));
                                },
                                child: const Text('Buat Notifikasi'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationListPage()));
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[400],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications, color: Colors.white, size: 24),
                          const SizedBox(height: 6),
                          Text(
                            '🔔 Notifikasi',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Buat Aktiviti (Teacher only)
                  if (_isTeacher) ...[
                    _buildTile(
                      context,
                      '➕ Tambah Aktiviti',
                      Icons.add_circle_outline,
                      Colors.green[400]!,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateActivityScreen())),
                    ),
                  ],
                  
                  // Lihat Aktiviti
                  _buildTile(
                    context,
                    '📋 Lihat Aktiviti',
                    Icons.event_note,
                    Colors.teal[400]!,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentActivitiesScreen())),
                  ),
                  
                  // Prestasi Tile (Conditional based on role)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => PerformanceScreen())
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.purple[400],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isTeacher ? Icons.show_chart : Icons.assessment,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isTeacher ? '📊 Pantau Prestasi Murid' : '📈 Prestasi Saya',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Optional: Add an extra tile for students when teacher has "Buat Aktiviti"
                  if (!_isTeacher) ...[
                    _buildTile(
                      context,
                      '🏆 Pencapaian Saya',
                      Icons.emoji_events,
                      Colors.orange[400]!,
                      () {
                        // Navigate to student achievements page
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => StudentAchievementsScreen()));
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
