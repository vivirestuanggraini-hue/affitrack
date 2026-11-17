import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() =>
      _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
      get _notificationReference {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User belum login.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications');
  }

  Future<void> _markAsRead(String id) async {
    await _notificationReference.doc(id).update({
      'isRead': true,
    });
  }

  Future<void> _markAllAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        notifications,
  ) async {
    final unread =
        notifications.where((doc) {
      return doc.data()['isRead'] != true;
    }).toList();

    if (unread.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Semua notifikasi sudah dibaca.',
          ),
        ),
      );
      return;
    }

    final batch = _firestore.batch();

    for (final doc in unread) {
      batch.update(
        _notificationReference.doc(doc.id),
        {'isRead': true},
      );
    }

    await batch.commit();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Semua notifikasi ditandai sudah dibaca.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteNotification(
    String id,
  ) async {
    await _notificationReference.doc(id).delete();
  }

  Future<void> _clearAll() async {
    final snapshot =
        await _notificationReference.get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada notifikasi.',
          ),
        ),
      );
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Hapus Semua Notifikasi?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Semua notifikasi akan dihapus dan tidak dapat dikembalikan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus Semua'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(
        _notificationReference.doc(doc.id),
      );
    }

    await batch.commit();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Semua notifikasi berhasil dihapus.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'product':
        return Icons.shopping_bag_rounded;
      case 'content':
        return Icons.video_library_rounded;
      case 'target':
        return Icons.flag_rounded;
      case 'calendar':
        return Icons.calendar_month_rounded;
      case 'commission':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'product':
        return Colors.blue;
      case 'content':
        return Colors.purple;
      case 'target':
        return Colors.orange;
      case 'calendar':
        return Colors.green;
      case 'commission':
        return Colors.teal;
      default:
        return const Color(0xFFE91E63);
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }

    final date = timestamp.toDate();

    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'read') {
                final snapshot =
                    await _notificationReference.get();

                await _markAllAsRead(
                  snapshot.docs,
                );
              }

              if (value == 'clear') {
                await _clearAll();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'read',
                child: Row(
                  children: [
                    Icon(
                      Icons.done_all_rounded,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('Tandai semua dibaca'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_sweep_rounded,
                      size: 20,
                      color: Colors.red,
                    ),
                    SizedBox(width: 10),
                    Text('Hapus semua'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _notificationReference
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat notifikasi.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final notifications =
              snapshot.data?.docs ?? [];

          final unreadCount =
              notifications.where((doc) {
            return doc.data()['isRead'] != true;
          }).length;

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 1000,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildHeader(
                      unreadCount,
                      notifications,
                    ),
                    const SizedBox(height: 20),
                    ...notifications.map(
                      (doc) => _buildNotificationCard(
                        doc,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    int unreadCount,
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        notifications,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF5FA2),
            Color(0xFFFF8BC1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifikasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  unreadCount == 0
                      ? 'Semua notifikasi sudah dibaca.'
                      : '$unreadCount notifikasi belum dibaca.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final title =
        data['title']?.toString() ??
            'Notifikasi';

    final message =
        data['message']?.toString() ?? '';

    final type =
        data['type']?.toString() ?? 'general';

    final isRead =
        data['isRead'] == true;

    final createdAt =
        data['createdAt'] as Timestamp?;

    final iconColor =
        _getIconColor(type);

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          _markAsRead(doc.id);
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : const Color(0xFFFFF0F6),
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: isRead
                ? Colors.grey.shade200
                : const Color(0xFFFFC7DD),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Icon(
                _getIcon(type),
                color: iconColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight:
                                isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 9,
                          height: 9,
                          decoration:
                              const BoxDecoration(
                            color:
                                Color(0xFFE91E63),
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      color:
                          Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'read') {
                  _markAsRead(doc.id);
                }

                if (value == 'delete') {
                  _deleteNotification(doc.id);
                }
              },
              itemBuilder: (context) => [
                if (!isRead)
                  const PopupMenuItem(
                    value: 'read',
                    child: Row(
                      children: [
                        Icon(
                          Icons.done_rounded,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text('Tandai dibaca'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: Colors.red,
                      ),
                      SizedBox(width: 10),
                      Text('Hapus'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE6F1),
                borderRadius:
                    BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: Color(0xFFE91E63),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Notifikasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Notifikasi aktivitas AffiTrack akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}