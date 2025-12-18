// Pakai code asal StudentDashboard
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_task.dart';
import 'student_teaching_material.dart';
import 'student_exercise.dart';
import 'student_mcq.dart';
import 'open_student_chat.dart';
import 'student_profile.dart';
import 'activity_hub.dart';
import 'account_view.dart';
import 'login_screen.dart';
import 'student_support_page.dart'; // <--- import StudentSupportPage

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('SignOut error: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7f8),
      appBar: AppBar(
        title: const Text(
          "Papan Pemuka Murid",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff4f7f67),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivityHub()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewProfilePage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xff4f7f67)),
              child: Center(
                child: Text(
                  "Menu Murid",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _drawerTile(Icons.dashboard, "Papan Pemuka", context, null),
            _drawerTile(Icons.task, "Tugasan", context, const StudentTask()),
            _drawerTile(
              Icons.menu_book,
              "Bahan-bahan Pengajaran",
              context,
              const StudentTeachingMaterial(),
            ),
            _drawerTile(
              Icons.picture_as_pdf,
              "Latihan",
              context,
              StudentExercise(),
            ),
            _drawerTile(
              Icons.chat,
              "Berbual",
              context,
              const OpenStudentChat(),
            ),
            _drawerTile(
              Icons.help_outline,
              "Bantuan & Sokongan",
              context,
              const StudentSupportPage(), // <--- menu baru sahaja ditambah
            ),
            _drawerTile(Icons.event, "Aktiviti", context, const ActivityHub()),
            _drawerTile(Icons.settings, "Tetapan", context, const AccountView()),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xff4f7f67)),
              title: const Text(
                'Log Keluar',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _logout(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Selamat Datang 👋, Murid!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pantau aktiviti dan prestasi anda di sini',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: const Center(
                  child: Text(
                    'Tiada aktiviti akan datang yang dijadualkan',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kalendar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: TableCalendar(
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
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Color(0xff7a9e8f),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Color(0xffb8cfc5),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, BuildContext context, Widget? page) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff4f7f67)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(context);
        if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }
      },
    );
  }
}
