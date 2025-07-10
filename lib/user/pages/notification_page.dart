import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class NotificationPage extends StatefulWidget {
  final int userId;

  const NotificationPage({super.key, required this.userId});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/notifications/user/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifications = data['data'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseUrl}/notifications/$notificationId/read'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _notifications = _notifications.map((notif) {
            if (notif['id'] == notificationId) {
              notif['is_read'] = 1;
            }
            return notif;
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'late':
        return Colors.red;
      case 'damage':
        return Colors.red;
      case 'system':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Icon _getNotificationIcon(String type) {
    switch (type) {
      case 'warning':
        return const Icon(Icons.warning, color: Colors.orange);
      case 'late':
        return const Icon(Icons.timer_off, color: Colors.red);
      case 'damage':
        return const Icon(Icons.build, color: Colors.red);
      case 'system':
        return const Icon(Icons.info, color: Colors.blue);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? const Center(
                      child: Text('Tidak ada notifikasi'),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        final isRead = notif['is_read'] == 1;

                        return Dismissible(
                          key: Key(notif['id'].toString()),
                          direction: DismissDirection.horizontal,
                          onDismissed: (_) => _markAsRead(notif['id']),
                          background: Container(
                            color: Colors.green,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.check, color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            color: Colors.green,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.check, color: Colors.white),
                          ),
                          child: Card(
                            elevation: isRead ? 1 : 3,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: _getNotificationIcon(notif['type']),
                              title: Text(
                                notif['title'],
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  color: _getNotificationColor(notif['type']),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(notif['message']),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateTime.parse(notif['created_at'])
                                        .toLocal()
                                        .toString()
                                        .substring(0, 16),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _markAsRead(notif['id']),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
