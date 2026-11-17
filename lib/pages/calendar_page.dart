import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  CollectionReference<Map<String, dynamic>> get _eventsReference {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User belum login.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('calendar_events');
  }

  String _monthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  Future<void> _addEvent() async {
    await _showEventDialog();
  }

  Future<void> _editEvent(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _showEventDialog(
      id: id,
      existingData: data,
    );
  }

  Future<void> _showEventDialog({
    String? id,
    Map<String, dynamic>? existingData,
  }) async {
    final titleController = TextEditingController(
      text: existingData?['title']?.toString() ?? '',
    );

    final noteController = TextEditingController(
      text: existingData?['note']?.toString() ?? '',
    );

    DateTime eventDate = _selectedDate;

    TimeOfDay eventTime = TimeOfDay.now();

    if (existingData != null) {
      final timestamp = existingData['date'];

      if (timestamp is Timestamp) {
        eventDate = timestamp.toDate();
      }

      final hour =
          (existingData['hour'] as num?)?.toInt();

      final minute =
          (existingData['minute'] as num?)?.toInt();

      if (hour != null && minute != null) {
        eventTime = TimeOfDay(
          hour: hour,
          minute: minute,
        );
      }
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                id == null
                    ? 'Tambah Agenda'
                    : 'Edit Agenda',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration:
                          const InputDecoration(
                        labelText: 'Judul Agenda',
                        hintText:
                            'Contoh: Upload konten TikTok',
                        prefixIcon:
                            Icon(Icons.title_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText: 'Catatan',
                        hintText:
                            'Tambahkan catatan jika diperlukan',
                        prefixIcon:
                            Icon(Icons.notes_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      borderRadius:
                          BorderRadius.circular(12),
                      onTap: () async {
                        final pickedDate =
                            await showDatePicker(
                          context: context,
                          initialDate: eventDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );

                        if (pickedDate != null) {
                          setDialogState(() {
                            eventDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(
                          labelText: 'Tanggal',
                          prefixIcon:
                              Icon(
                            Icons.calendar_today_rounded,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _formatDate(eventDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      borderRadius:
                          BorderRadius.circular(12),
                      onTap: () async {
                        final pickedTime =
                            await showTimePicker(
                          context: context,
                          initialTime: eventTime,
                        );

                        if (pickedTime != null) {
                          setDialogState(() {
                            eventTime = pickedTime;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(
                          labelText: 'Waktu',
                          prefixIcon:
                              Icon(
                            Icons.access_time_rounded,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _formatTime(eventTime),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title =
                        titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Judul agenda wajib diisi.',
                          ),
                        ),
                      );
                      return;
                    }

                    final dateTime = DateTime(
                      eventDate.year,
                      eventDate.month,
                      eventDate.day,
                      eventTime.hour,
                      eventTime.minute,
                    );

                    try {
                      final data = {
                        'title': title,
                        'note':
                            noteController.text.trim(),
                        'date':
                            Timestamp.fromDate(dateTime),
                        'hour': eventTime.hour,
                        'minute': eventTime.minute,
                        'updatedAt':
                            FieldValue.serverTimestamp(),
                      };

                      if (id == null) {
                        await _eventsReference.add({
                          ...data,
                          'createdAt':
                              FieldValue.serverTimestamp(),
                        });
                      } else {
                        await _eventsReference
                            .doc(id)
                            .update(data);
                      }

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      setState(() {
                        _selectedDate = eventDate;
                        _focusedMonth = DateTime(
                          eventDate.year,
                          eventDate.month,
                        );
                      });

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            id == null
                                ? 'Agenda berhasil ditambahkan.'
                                : 'Agenda berhasil diperbarui.',
                          ),
                          backgroundColor:
                              Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Gagal menyimpan agenda: $e',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFFF5FA2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    noteController.dispose();
  }

  Future<void> _deleteEvent(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Hapus Agenda?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Agenda yang dihapus tidak dapat dikembalikan.',
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
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _eventsReference.doc(id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Agenda berhasil dihapus.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus agenda: $e',
          ),
        ),
      );
    }
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + 1,
      );
    });
  }

  List<DateTime> _buildCalendarDays() {
    final firstDay = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );

    final lastDay = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );

    int startOffset = firstDay.weekday - 1;

    final days = <DateTime>[];

    for (int i = startOffset; i > 0; i--) {
      days.add(
        firstDay.subtract(
          Duration(days: i),
        ),
      );
    }

    for (int day = 1;
        day <= lastDay.day;
        day++) {
      days.add(
        DateTime(
          _focusedMonth.year,
          _focusedMonth.month,
          day,
        ),
      );
    }

    while (days.length < 42) {
      days.add(
        days.last.add(
          const Duration(days: 1),
        ),
      );
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      appBar: AppBar(
        title: const Text(
          'Kalender',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Tambah Agenda',
            onPressed: _addEvent,
            icon: const Icon(
              Icons.add_circle_outline_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _eventsReference.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat kalender.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final events = snapshot.data?.docs ?? [];

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 1100,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildCalendar(events),
                        const SizedBox(height: 20),
                        _buildSelectedDateTitle(),
                        const SizedBox(height: 12),
                        _buildEventList(events),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _addEvent,
        backgroundColor:
            const Color(0xFFFF5FA2),
        foregroundColor: Colors.white,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Tambah Agenda',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Kalender AffiTrack',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Atur jadwal konten, promosi, dan aktivitas affiliate.',
                  style: TextStyle(
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

  Widget _buildCalendar(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        events,
  ) {
    final days = _buildCalendarDays();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              'Sen',
              'Sel',
              'Rab',
              'Kam',
              'Jum',
              'Sab',
              'Min',
            ]
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final date = days[index];

              final isCurrentMonth =
                  date.month == _focusedMonth.month;

              final isSelected =
                  _sameDate(date, _selectedDate);

              final isToday =
                  _sameDate(date, DateTime.now());

              final hasEvent = events.any((doc) {
                final timestamp =
                    doc.data()['date'];

                if (timestamp is! Timestamp) {
                  return false;
                }

                return _sameDate(
                  timestamp.toDate(),
                  date,
                );
              });

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF5FA2)
                        : isToday
                            ? const Color(0xFFFFE6F1)
                            : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(
                            color:
                                const Color(0xFFFF5FA2),
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isCurrentMonth
                                    ? const Color(
                                        0xFF333333,
                                      )
                                    : Colors.grey.shade400,
                            fontWeight:
                                isSelected ||
                                        isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasEvent)
                        Positioned(
                          bottom: 5,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration:
                                  BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(
                                        0xFFE91E63,
                                      ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDateTitle() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Agenda',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE6F1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatDate(_selectedDate),
            style: const TextStyle(
              color: Color(0xFFE91E63),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        events,
  ) {
    final selectedEvents = events.where((doc) {
      final timestamp = doc.data()['date'];

      if (timestamp is! Timestamp) {
        return false;
      }

      return _sameDate(
        timestamp.toDate(),
        _selectedDate,
      );
    }).toList();

    selectedEvents.sort((a, b) {
      final aDate =
          (a.data()['date'] as Timestamp).toDate();

      final bDate =
          (b.data()['date'] as Timestamp).toDate();

      return aDate.compareTo(bDate);
    });

    if (selectedEvents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada agenda',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Tambahkan agenda untuk tanggal ini.',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addEvent,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Agenda'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFFF5FA2),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: selectedEvents.map((doc) {
        final data = doc.data();

        final timestamp = data['date'];

        DateTime? date;

        if (timestamp is Timestamp) {
          date = timestamp.toDate();
        }

        final timeText = date == null
            ? '--:--'
            : '${date.hour.toString().padLeft(2, '0')}:'
                '${date.minute.toString().padLeft(2, '0')}';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(
            bottom: 12,
          ),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFFE0ED),
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE6F1),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: Color(0xFFE91E63),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title']?.toString() ??
                          'Tanpa Judul',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          timeText,
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if ((data['note'] ?? '')
                        .toString()
                        .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        data['note'].toString(),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editEvent(
                      doc.id,
                      data,
                    );
                  } else if (value == 'delete') {
                    _deleteEvent(doc.id);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
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
        );
      }).toList(),
    );
  }
}