import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_notification.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  Map<dynamic, Map<String, dynamic>> _userStatus = {}; // notificationId -> status row
  bool _isLoading = true;
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _checkRole();
    await _fetchNotifications();
  }

  Future<void> _checkRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final teacherData = await supabase
          .from('profile_teacher')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      setState(() => _isTeacher = teacherData != null);
    } catch (e) {
      setState(() => _isTeacher = false);
    }
  }

  // Build a safe IN clause for PostgREST: (1,2,3) or ('uuid1','uuid2')
  String _buildInClause(List ids) {
    final parts = ids.map((e) {
      if (e == null) return 'NULL';
      if (e is int) return e.toString();
      final s = e.toString();
      final numeric = int.tryParse(s);
      if (numeric != null) return numeric.toString();
      // escape single quotes in string values and wrap in single quotes
      final escaped = s.replaceAll("'", "''");
      return "'$escaped'";
    }).join(',');
    return '($parts)';
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;

      // Reset caches so we don't carry stale values between calls
      _notifications = [];
      _userStatus = {};

      // fetch notifications (older API style)
      final data = await supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false);

      // Postgrest/dart client sometimes returns null or List<dynamic>
      final list = List<dynamic>.from(data ?? []);
      _notifications = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Load per-user status rows (read/deleted) and recipients if needed
      if (user != null && _notifications.isNotEmpty) {
        // Build ids list (keep original type: could be int or string/uuid)
        final ids = _notifications.map((n) => n['id']).where((e) => e != null).toList();

        if (ids.isNotEmpty) {
          final inClause = _buildInClause(ids);

          // get user_notification_status rows for these notification ids and current user
          final statusRows = await supabase
              .from('user_notification_status')
              .select()
              .filter('notification_id', 'in', inClause)
              .eq('user_id', user.id);

          for (final row in List<Map<String, dynamic>>.from(statusRows ?? [])) {
            var nid = row['notification_id'];
            // normalize numeric-looking strings to int if possible
            if (nid is String) {
              final parsed = int.tryParse(nid);
              if (parsed != null) nid = parsed;
            }
            _userStatus[nid] = row;
          }

          // For students, fetch recipient rows and filter notifications so they only
          // see notifications addressed to them (or broadcasts with no recipients).
          if (!_isTeacher) {
            try {
              final recipientRows = await supabase
                  .from('notification_recipients')
                  .select()
                  .filter('notification_id', 'in', inClause);

              final Map<dynamic, List<Map<String, dynamic>>> recipientsMap = {};
              for (final r in List<Map<String, dynamic>>.from(recipientRows ?? [])) {
                var nid = r['notification_id'];
                if (nid is String) {
                  final parsed = int.tryParse(nid);
                  if (parsed != null) nid = parsed;
                }
                recipientsMap.putIfAbsent(nid, () => []).add(r);
              }

              // Keep notifications where:
              // - there are no recipients (broadcast), OR
              // - the recipients list includes the current user
              _notifications = _notifications.where((n) {
                final nid = n['id'];
                final recs = recipientsMap[nid] ?? [];
                if (recs.isEmpty) return true; // broadcast
                return recs.any((r) {
                  final rid = r['recipient_id'];
                  return rid == user.id;
                });
              }).toList();
            } catch (e) {
              debugPrint('Failed to load notification recipients: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      _notifications = [];
      _userStatus = {};
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isDeletedForUser(Map<String, dynamic> notif) {
    final nid = notif['id'];
    final row = _userStatus[nid];
    return row != null && (row['deleted'] == true || row['deleted'] == 1);
  }

  bool _isReadForUser(Map<String, dynamic> notif) {
    final nid = notif['id'];
    final row = _userStatus[nid];
    return row != null && (row['read'] == true || row['read'] == 1);
  }

  Future<void> _markAsRead(int notificationId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      // Upsert read status for this user
      final now = DateTime.now().toIso8601String();
      await supabase.from('user_notification_status').upsert({
        'notification_id': notificationId,
        'user_id': user.id,
        'read': true,
        'updated_at': now,
      });

      // Refresh local cache
      _userStatus[notificationId] = {
        'notification_id': notificationId,
        'user_id': user.id,
        'read': true,
        'updated_at': now,
      };
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to mark read: $e')));
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      if (_isTeacher) {
        // Teacher deletes the notification row globally
        await supabase.from('notifications').delete().eq('id', notificationId);
      } else {
        // Student: mark as deleted for this user only
        final now = DateTime.now().toIso8601String();
        await supabase.from('user_notification_status').upsert({
          'notification_id': notificationId,
          'user_id': user.id,
          'deleted': true,
          'updated_at': now,
        });

        _userStatus[notificationId] = {
          'notification_id': notificationId,
          'user_id': user.id,
          'deleted': true,
          'updated_at': now,
        };
      }

      await _fetchNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal padam: $e')));
    }
  }

  Future<void> _editNotification(Map<String, dynamic> notification) async {
    final titleCtrl = TextEditingController(text: notification['title'] ?? '');
    final messageCtrl = TextEditingController(text: notification['message'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sunting Notifikasi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tajuk'), maxLines: 1),
              const SizedBox(height: 12),
              TextField(controller: messageCtrl, decoration: const InputDecoration(labelText: 'Mesej'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              try {
                final now = DateTime.now().toIso8601String();
                await supabase
                    .from('notifications')
                    .update({
                      'title': titleCtrl.text,
                      'message': messageCtrl.text,
                      'updated_at': now,
                    })
                    .eq('id', notification['id']);
                Navigator.pop(ctx);
                await _fetchNotifications();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifikasi dikemas kini')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengemas kini: $e')));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: const Color(0xff4f7f67),
        actions: [
          if (_isTeacher)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateNotificationScreen()));
                if (created == true) await _fetchNotifications();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
                ? const Center(child: Text('Tiada notifikasi'))
                  : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      if (_isDeletedForUser(n)) return const SizedBox.shrink();

                      final createdAt = n['created_at'] != null ? n['created_at'].toString() : '';
                      final isRead = _isReadForUser(n);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        child: ListTile(
                          leading: Icon(isRead ? Icons.mark_email_read : Icons.mark_email_unread, color: isRead ? Colors.grey : Colors.blue),
                          title: Text(n['title'] ?? 'Tiada tajuk'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(n['message'] ?? ''),
                              const SizedBox(height: 6),
                              Text(createdAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: _isTeacher
                              ? PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') await _editNotification(n);
                                    if (value == 'delete') await _deleteNotification(n['id']);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Sunting')),
                                    PopupMenuItem(value: 'delete', child: Text('Padam')),
                                  ],
                                )
                              : PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'read') await _markAsRead(n['id']);
                                    if (value == 'delete') await _deleteNotification(n['id']);
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(value: 'read', child: Text(isRead ? 'Tandakan belum dibaca' : 'Tandakan dibaca')),
                                    const PopupMenuItem(value: 'delete', child: Text('Padam')),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}