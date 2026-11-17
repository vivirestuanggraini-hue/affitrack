import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TargetPage extends StatefulWidget {
  const TargetPage({super.key});

  @override
  State<TargetPage> createState() => _TargetPageState();
}

class _TargetPageState extends State<TargetPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _targetController =
      TextEditingController();

  String _selectedMonth = 'November';
  bool _loading = true;
  bool _saving = false;

  double _target = 6000000;

  final List<String> _months = const [
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

  DocumentReference<Map<String, dynamic>> get _targetReference {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User belum login.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('target');
  }

  @override
  void initState() {
    super.initState();
    _loadTarget();
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _loadTarget() async {
    try {
      final snapshot = await _targetReference.get();

      if (snapshot.exists) {
        final data = snapshot.data();

        if (data != null) {
          final savedTarget =
              (data['target'] as num?)?.toDouble();

          final savedMonth =
              data['month']?.toString();

          if (savedTarget != null && savedTarget > 0) {
            _target = savedTarget;
          }

          if (savedMonth != null &&
              _months.contains(savedMonth)) {
            _selectedMonth = savedMonth;
          }
        }
      }

      _targetController.text =
          _formatNumber(_target);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat target: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveTarget() async {
    final cleanValue =
        _targetController.text.replaceAll('.', '');

    final value = double.tryParse(cleanValue);

    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Masukkan target yang valid.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _targetReference.set({
        'target': value,
        'month': _selectedMonth,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _target = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Target berhasil disimpan.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan target: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _formatNumber(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }

  String _formatRupiah(double value) {
    return 'Rp ${_formatNumber(value)}';
  }

  Future<void> _showTargetDialog() async {
    final controller = TextEditingController(
      text: _formatNumber(_target),
    );

    String selectedMonth = _selectedMonth;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Atur Target Komisi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType:
                        TextInputType.number,
                    decoration:
                        const InputDecoration(
                      labelText: 'Target Komisi',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedMonth,
                    decoration:
                        const InputDecoration(
                      labelText: 'Bulan Target',
                      border: OutlineInputBorder(),
                    ),
                    items: _months.map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedMonth = value;
                        });
                      }
                    },
                  ),
                ],
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
                    final cleanValue =
                        controller.text
                            .replaceAll('.', '');

                    final value =
                        double.tryParse(cleanValue);

                    if (value == null || value <= 0) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Masukkan nominal target yang valid.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    setState(() {
                      _targetController.text =
                          _formatNumber(value);
                      _selectedMonth =
                          selectedMonth;
                    });

                    await _saveTarget();
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      appBar: AppBar(
        title: const Text(
          'Target Komisi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _auth.currentUser == null
            ? const Stream.empty()
            : _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .collection('products')
                .snapshots(),
        builder: (context, snapshot) {
          double totalCommission = 0;

          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data();

              final price =
                  (data['price'] as num?)?.toDouble() ?? 0;

              final commission =
                  (data['commission'] as num?)?.toDouble() ?? 0;

              totalCommission +=
                  price * commission / 100;
            }
          }

          final progress = _target <= 0
              ? 0.0
              : (totalCommission / _target)
                  .clamp(0.0, 1.0)
                  .toDouble();

          final remaining =
              (_target - totalCommission)
                  .clamp(0.0, _target)
                  .toDouble();

          final percentage =
              (progress * 100).toStringAsFixed(0);

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
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildTargetCard(
                      totalCommission,
                      progress,
                      percentage,
                      remaining,
                    ),
                    const SizedBox(height: 20),
                    _buildSummaryCards(
                      totalCommission,
                      remaining,
                      percentage,
                    ),
                    const SizedBox(height: 20),
                    _buildInfoCard(),
                  ],
                ),
              ),
            ),
          );
        },
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
              Icons.flag_rounded,
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
                  'Target Komisi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Atur dan pantau pencapaian target affiliate kamu.',
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

  Widget _buildTargetCard(
    double totalCommission,
    double progress,
    String percentage,
    double remaining,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Target Bulanan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE6F1),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedMonth,
                  style: const TextStyle(
                    color: Color(0xFFE91E63),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _formatRupiah(_target),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE91E63),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Target komisi bulan $_selectedMonth',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 14,
                    backgroundColor:
                        const Color(0xFFF3E3EB),
                    valueColor:
                        const AlwaysStoppedAnimation(
                      Color(0xFFFF5FA2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tercapai: ${_formatRupiah(totalCommission)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Sisa: ${_formatRupiah(remaining)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _saving ? null : _showTargetDialog,
              icon: const Icon(
                Icons.edit_rounded,
              ),
              label: Text(
                _saving
                    ? 'Menyimpan...'
                    : 'Atur Target',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFFF5FA2),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    double totalCommission,
    double remaining,
    String percentage,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;

        final cards = [
          _summaryCard(
            'Target',
            _formatRupiah(_target),
            Icons.flag_rounded,
            const Color(0xFFE91E63),
          ),
          _summaryCard(
            'Tercapai',
            _formatRupiah(totalCommission),
            Icons.trending_up_rounded,
            Colors.green,
          ),
          _summaryCard(
            'Sisa Target',
            _formatRupiah(remaining),
            Icons.account_balance_wallet_rounded,
            Colors.orange,
          ),
        ];

        if (isSmall) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFE91E63),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Target dihitung berdasarkan estimasi komisi '
              'dari produk affiliate yang tersimpan di akun kamu. '
              'Perubahan target akan tersimpan otomatis ke Firebase.',
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}