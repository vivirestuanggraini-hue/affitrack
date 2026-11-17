import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/affiliate_product.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsReference {
    final user = _auth.currentUser;

    if (user == null) {
      return _firestore.collection('empty');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('products');
  }

  CollectionReference<Map<String, dynamic>> get _contentsReference {
    final user = _auth.currentUser;

    if (user == null) {
      return _firestore.collection('empty');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('contents');
  }

  Stream<List<AffiliateProduct>> get productsStream {
    if (_auth.currentUser == null) {
      return Stream.value([]);
    }

    return _productsReference.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AffiliateProduct.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }

  Stream<int> get contentCountStream {
    if (_auth.currentUser == null) {
      return Stream.value(0);
    }

    return _contentsReference.snapshots().map(
          (snapshot) => snapshot.docs.length,
        );
  }

  double calculateTotalCommission(
    List<AffiliateProduct> products,
  ) {
    double total = 0;

    for (final product in products) {
      total += product.estimatedCommission;
    }

    return total;
  }

  Map<String, int> calculatePlatformCount(
    List<AffiliateProduct> products,
  ) {
    final Map<String, int> result = {
      'Shopee': 0,
      'TikTok Shop': 0,
      'Tokopedia': 0,
    };

    for (final product in products) {
      final platform = product.platform;

      if (result.containsKey(platform)) {
        result[platform] = result[platform]! + 1;
      } else {
        result[platform] = 1;
      }
    }

    return result;
  }

  String formatRupiah(double value) {
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)} jt';
    }

    if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)} rb';
    }

    return 'Rp ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF292333),
          ),
        ),
        title: const Text(
          'Analitik',
          style: TextStyle(
            color: Color(0xFF292333),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<List<AffiliateProduct>>(
        stream: productsStream,
        builder: (context, productSnapshot) {
          if (productSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF4F81),
              ),
            );
          }

          final products = productSnapshot.data ?? [];

          return StreamBuilder<int>(
            stream: contentCountStream,
            builder: (context, contentSnapshot) {
              final contentCount =
                  contentSnapshot.data ?? 0;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile =
                      constraints.maxWidth < 800;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(
                      isMobile ? 16 : 28,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isMobile),

                        const SizedBox(height: 24),

                        _buildSummaryCards(
                          products,
                          contentCount,
                          isMobile,
                        ),

                        const SizedBox(height: 24),

                        _buildMainAnalytics(
                          products,
                          isMobile,
                        ),

                        const SizedBox(height: 24),

                        _buildPlatformCard(
                          products,
                          isMobile,
                        ),

                        const SizedBox(height: 24),

                        _buildTopProducts(
                          products,
                          isMobile,
                        ),

                        const SizedBox(height: 30),

                        Center(
                          child: Text(
                            'AffiTrack • Analytics',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 20 : 28,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF4F81),
            Color(0xFFFF789C),
            Color(0xFFFF9EB8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4F81)
                .withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Analitik Affiliate 📊',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 22 : 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pantau perkembangan produk, konten, dan estimasi komisi kamu.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 20),
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    List<AffiliateProduct> products,
    int contentCount,
    bool isMobile,
  ) {
    final totalCommission =
        calculateTotalCommission(products);

    final favoriteCount =
        products.where((p) => p.isFavorite).length;

    final priorityCount =
        products.where((p) => p.isPriority).length;

    final cards = [
      _summaryData(
        'Total Produk',
        products.length.toString(),
        'Produk affiliate',
        Icons.shopping_bag_rounded,
      ),
      _summaryData(
        'Total Komisi',
        formatRupiah(totalCommission),
        'Estimasi komisi',
        Icons.account_balance_wallet_rounded,
      ),
      _summaryData(
        'Produk Favorit',
        favoriteCount.toString(),
        'Produk favorit',
        Icons.favorite_rounded,
      ),
      _summaryData(
        'Total Konten',
        contentCount.toString(),
        'Konten tersimpan',
        Icons.movie_creation_rounded,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(cards[0]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(cards[1]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(cards[2]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(cards[3]),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(
            child: _buildSummaryCard(cards[i]),
          ),
          if (i != cards.length - 1)
            const SizedBox(width: 14),
        ],
      ],
    );
  }

  Map<String, dynamic> _summaryData(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return {
      'title': title,
      'value': value,
      'subtitle': subtitle,
      'icon': icon,
    };
  }

  Widget _buildSummaryCard(
    Map<String, dynamic> data,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEDEAF2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F4),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              data['icon'] as IconData,
              color: const Color(0xFFFF4F81),
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data['value'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF292333),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data['subtitle'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAnalytics(
    List<AffiliateProduct> products,
    bool isMobile,
  ) {
    final sortedProducts = [...products]
      ..sort(
        (a, b) => b.estimatedCommission
            .compareTo(a.estimatedCommission),
      );

    final topProducts =
        sortedProducts.take(5).toList();

    if (isMobile) {
      return Column(
        children: [
          _buildCommissionChart(
            topProducts,
          ),
          const SizedBox(height: 18),
          _buildPerformanceInsight(
            products,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: _buildCommissionChart(
            topProducts,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 4,
          child: _buildPerformanceInsight(
            products,
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionChart(
    List<AffiliateProduct> products,
  ) {
    if (products.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.bar_chart_rounded,
        title: 'Belum Ada Data Komisi',
        subtitle:
            'Tambahkan produk affiliate untuk melihat analitik komisi.',
      );
    }

    final maxCommission = products
        .map((product) => product.estimatedCommission)
        .reduce(
          (a, b) => a > b ? a : b,
        );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEDEAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Komisi Produk Teratas',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF292333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estimasi komisi berdasarkan produk',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 22),
          for (final product in products)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 16,
              ),
              child: _buildCommissionBar(
                product,
                maxCommission,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommissionBar(
    AffiliateProduct product,
    double maxCommission,
  ) {
    final double progress =
        maxCommission == 0
            ? 0
            : (product.estimatedCommission /
                    maxCommission)
                .clamp(0.0, 1.0)
                .toDouble();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatRupiah(
                product.estimatedCommission,
              ),
              style: const TextStyle(
                color: Color(0xFFFF4F81),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 9,
            backgroundColor:
                const Color(0xFFF2EEF3),
            valueColor:
                const AlwaysStoppedAnimation<Color>(
              Color(0xFFFF4F81),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceInsight(
    List<AffiliateProduct> products,
  ) {
    if (products.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.insights_rounded,
        title: 'Belum Ada Insight',
        subtitle:
            'Data akan muncul setelah kamu menambahkan produk.',
      );
    }

    final favoriteCount =
        products.where((p) => p.isFavorite).length;

    final priorityCount =
        products.where((p) => p.isPriority).length;

    final highestCommission = [...products]
      ..sort(
        (a, b) => b.estimatedCommission
            .compareTo(a.estimatedCommission),
      );

    final topProduct = highestCommission.first;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEDEAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Insight Performa',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Ringkasan dari data produk kamu.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 18),
          _buildInsightItem(
            Icons.star_rounded,
            'Produk Prioritas',
            '$priorityCount produk',
          ),
          const SizedBox(height: 10),
          _buildInsightItem(
            Icons.favorite_rounded,
            'Produk Favorit',
            '$favoriteCount produk',
          ),
          const SizedBox(height: 10),
          _buildInsightItem(
            Icons.emoji_events_rounded,
            'Komisi Tertinggi',
            topProduct.name,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFFFF4F81),
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fokuskan promosi pada produk dengan estimasi komisi paling tinggi.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FB),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFFFF4F81),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard(
    List<AffiliateProduct> products,
    bool isMobile,
  ) {
    final platformCount =
        calculatePlatformCount(products);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEDEAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribusi Platform',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jumlah produk berdasarkan platform affiliate.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 20),
          if (platformCount.isEmpty)
            Text(
              'Belum ada data platform.',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: platformCount.entries.map(
                (entry) {
                  return _buildPlatformItem(
                    entry.key,
                    entry.value,
                  );
                },
              ).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPlatformItem(
    String platform,
    int count,
  ) {
    IconData icon;

    switch (platform.toLowerCase()) {
      case 'shopee':
        icon = Icons.shopping_bag_rounded;
        break;

      case 'tiktok shop':
        icon = Icons.music_note_rounded;
        break;

      case 'tokopedia':
        icon = Icons.storefront_rounded;
        break;

      default:
        icon = Icons.language_rounded;
    }

    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F4),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF4F81),
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  platform,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$count produk',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(
    List<AffiliateProduct> products,
    bool isMobile,
  ) {
    final sortedProducts = [...products]
      ..sort(
        (a, b) => b.estimatedCommission
            .compareTo(a.estimatedCommission),
      );

    final topProducts =
        sortedProducts.take(5).toList();

    if (topProducts.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.emoji_events_outlined,
        title: 'Belum Ada Produk',
        subtitle:
            'Tambahkan produk untuk melihat peringkat produk terbaik.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEDEAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Produk Terbaik',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Peringkat produk berdasarkan estimasi komisi.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < topProducts.length; i++)
            _buildRankingItem(
              i + 1,
              topProducts[i],
            ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(
    int rank,
    AffiliateProduct product,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFFFF0F4)
                  : const Color(0xFFFAF8FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank == 1
                    ? const Color(0xFFFF4F81)
                    : const Color(0xFF77727F),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.platform,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatRupiah(
              product.estimatedCommission,
            ),
            style: const TextStyle(
              color: Color(0xFFFF4F81),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEDEAF2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}