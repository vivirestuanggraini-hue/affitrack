import 'package:flutter/material.dart';

import '../models/affiliate_commission.dart';
import '../services/commission_service.dart';

class CommissionPage extends StatefulWidget {
  const CommissionPage({
    super.key,
  });

  @override
  State<CommissionPage> createState() =>
      _CommissionPageState();
}

class _CommissionPageState
    extends State<CommissionPage>
    with SingleTickerProviderStateMixin {
  final CommissionService _commissionService =
      CommissionService();

  final TextEditingController _searchController =
      TextEditingController();

  late AnimationController _animationController;

  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'TikTok Shop',
    'Shopee',
    'Tokopedia',
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 800,
      ),
    )..forward();

    _searchController.addListener(() {
      setState(() {
        _searchQuery =
            _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatRupiah(double value) {
    final rounded = value.round();

    final text = rounded.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final position =
          text.length - i;

      buffer.write(text[i]);

      if (position > 1 &&
          position % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp ${buffer.toString()}';
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')} Jt';
    }

    if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)} Rb';
    }

    return _formatRupiah(value);
  }

  List<AffiliateCommission> _filterCommissions(
    List<AffiliateCommission> commissions,
  ) {
    return commissions.where((commission) {
      final matchesSearch =
          commission.productName
                  .toLowerCase()
                  .contains(_searchQuery) ||
              commission.platform
                  .toLowerCase()
                  .contains(_searchQuery);

      final matchesFilter =
          _selectedFilter == 'Semua' ||
          commission.platform ==
              _selectedFilter;

      return matchesSearch &&
          matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8FC),
      body: SafeArea(
        child: StreamBuilder<
            List<AffiliateCommission>>(
          stream:
              _commissionService
                  .getCommissions(),
          builder:
              (context, snapshot) {
            if (snapshot.hasError) {
              return _buildError(
                snapshot.error.toString(),
              );
            }

            if (snapshot.connectionState ==
                    ConnectionState.waiting &&
                !snapshot.hasData) {
              return _buildLoading();
            }

            final commissions =
                snapshot.data ?? [];

            final filtered =
                _filterCommissions(
              commissions,
            );

            return LayoutBuilder(
              builder:
                  (context, constraints) {
                final isMobile =
                    constraints.maxWidth <
                        700;

                return AnimatedBuilder(
                  animation:
                      _animationController,
                  builder:
                      (context, child) {
                    final animation =
                        CurvedAnimation(
                      parent:
                          _animationController,
                      curve:
                          Curves.easeOutCubic,
                    );

                    return FadeTransition(
                      opacity: animation,
                      child:
                          SlideTransition(
                        position:
                            Tween<Offset>(
                          begin:
                              const Offset(
                            0,
                            0.04,
                          ),
                          end:
                              Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child:
                      SingleChildScrollView(
                    physics:
                        const BouncingScrollPhysics(),
                    padding:
                        EdgeInsets.all(
                      isMobile ? 14 : 28,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        _buildHeader(
                          isMobile,
                        ),
                        SizedBox(
                          height:
                              isMobile
                                  ? 18
                                  : 25,
                        ),
                        _buildSummary(
                          commissions,
                          isMobile,
                        ),
                        SizedBox(
                          height:
                              isMobile
                                  ? 18
                                  : 25,
                        ),
                        _buildSearchAndFilter(
                          isMobile,
                        ),
                        SizedBox(
                          height:
                              isMobile
                                  ? 18
                                  : 22,
                        ),
                        _buildCommissionList(
                          filtered,
                          isMobile,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(14),
          child: InkWell(
            borderRadius:
                BorderRadius.circular(14),
            onTap: () {
              Navigator.pop(context);
            },
            child: const SizedBox(
              width: 45,
              height: 45,
              child: Icon(
                Icons.arrow_back_rounded,
                color:
                    Color(0xFF403541),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Komisi',
                style: TextStyle(
                  fontSize:
                      isMobile ? 23 : 29,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      const Color(
                    0xFF302632,
                  ),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(height: 4),
                const Text(
                  'Pantau estimasi komisi dari produk affiliate kamu.',
                  style: TextStyle(
                    color:
                        Color(0xFF91818D),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color:
                Color(0xFFE84983),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(
    List<AffiliateCommission> commissions,
    bool isMobile,
  ) {
    final total = commissions.fold<double>(
      0,
      (sum, item) =>
          sum + item.estimatedCommission,
    );

    final highest = commissions.isEmpty
        ? 0.0
        : commissions
            .map(
              (item) =>
                  item.estimatedCommission,
            )
            .reduce(
              (a, b) =>
                  a > b ? a : b,
            );

    final priorityCount =
        commissions
            .where(
              (item) => item.isPriority,
            )
            .length;

    final cards = [
      _SummaryData(
        'Total Komisi',
        _formatCompact(total),
        'Estimasi keseluruhan',
        Icons
            .account_balance_wallet_rounded,
        const Color(0xFFE84983),
      ),
      _SummaryData(
        'Produk',
        '${commissions.length}',
        'Produk terdaftar',
        Icons.shopping_bag_rounded,
        const Color(0xFF9C7BFF),
      ),
      _SummaryData(
        'Komisi Tertinggi',
        _formatCompact(highest),
        'Dari satu produk',
        Icons.trending_up_rounded,
        const Color(0xFF4EC9A0),
      ),
      _SummaryData(
        'Prioritas',
        '$priorityCount',
        'Produk prioritas',
        Icons.flag_rounded,
        const Color(0xFFFFA34D),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth < 520) {
          columns = 1;
        } else if (constraints.maxWidth <
            950) {
          columns = 2;
        } else {
          columns = 4;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio:
                columns == 1
                    ? 3.0
                    : 1.55,
          ),
          itemBuilder:
              (context, index) {
            return _buildSummaryCard(
              cards[index],
              index,
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(
    _SummaryData data,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(
        milliseconds:
            450 + index * 100,
      ),
      tween: Tween(
        begin: 0,
        end: 1,
      ),
      curve: Curves.easeOutBack,
      builder:
          (context, value, child) {
        return Transform.translate(
          offset: Offset(
            0,
            18 * (1 - value),
          ),
          child: Opacity(
            opacity:
                value.clamp(0, 1),
            child: child,
          ),
        );
      },
      child: Container(
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color:
                const Color(0xFFF3E3EA),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  const Color(0xFF8C526A)
                      .withOpacity(0.05),
              blurRadius: 18,
              offset:
                  const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration:
                  BoxDecoration(
                color:
                    data.color
                        .withOpacity(0.11),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                data.icon,
                color: data.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    data.title,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF958792),
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.value,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF342A35),
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: data.color,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        TextField(
          controller:
              _searchController,
          decoration:
              InputDecoration(
            hintText:
                'Cari produk atau platform...',
            prefixIcon:
                const Icon(
              Icons.search_rounded,
              color:
                  Color(0xFFE84983),
            ),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController
                              .clear();
                        },
                        icon:
                            const Icon(
                          Icons
                              .clear_rounded,
                        ),
                      )
                    : null,
            filled: true,
            fillColor: Colors.white,
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(0xFFF3E3EA),
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(0xFFF3E3EA),
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(0xFFE84983),
                width: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection:
                Axis.horizontal,
            itemCount:
                _filters.length,
            separatorBuilder:
                (_, __) =>
                    const SizedBox(
              width: 8,
            ),
            itemBuilder:
                (context, index) {
              final filter =
                  _filters[index];

              final selected =
                  _selectedFilter ==
                      filter;

              return ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(
                            0xFF675866,
                          ),
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedFilter =
                        filter;
                  });
                },
                selectedColor:
                    const Color(
                  0xFFE84983,
                ),
                backgroundColor:
                    Colors.white,
                side:
                    const BorderSide(
                  color:
                      Color(0xFFF3E3EA),
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionList(
    List<AffiliateCommission> commissions,
    bool isMobile,
  ) {
    if (commissions.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Daftar Komisi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF372D38),
                ),
              ),
            ),
            Text(
              '${commissions.length} produk',
              style: const TextStyle(
                color:
                    Color(0xFF9B8D98),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isMobile)
          ...commissions
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child:
                      _buildCommissionCard(
                    entry.value,
                    entry.key,
                  ),
                ),
              )
        else
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount:
                commissions.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.5,
            ),
            itemBuilder:
                (context, index) {
              return _buildCommissionCard(
                commissions[index],
                index,
              );
            },
          ),
      ],
    );
  }

  Widget _buildCommissionCard(
    AffiliateCommission commission,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(
        milliseconds:
            350 + (index * 60),
      ),
      tween: Tween(
        begin: 0,
        end: 1,
      ),
      curve: Curves.easeOutCubic,
      builder:
          (context, value, child) {
        return Opacity(
          opacity:
              value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(
              0,
              12 * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(20),
          onTap: () {
            _showCommissionDetail(
              commission,
            );
          },
          child: Container(
            padding:
                const EdgeInsets.all(16),
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color:
                    const Color(
                  0xFFF3E3EA,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color(
                    0xFF8C526A,
                  ).withOpacity(0.05),
                  blurRadius: 15,
                  offset:
                      const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      colors: [
                        Color(0xFFFF8DB7),
                        Color(0xFFE84983),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              commission
                                  .productName,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    Color(
                                  0xFF3D333F,
                                ),
                                fontWeight:
                                    FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (commission
                              .isPriority)
                            const Icon(
                              Icons
                                  .star_rounded,
                              color:
                                  Color(
                                0xFFFFA34D,
                              ),
                              size: 17,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        commission.platform,
                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xFF9B8D98,
                          ),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Text(
                            '${commission.commissionPercent.toStringAsFixed(0)}%',
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF9C7BFF,
                              ),
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            _formatRupiah(
                              commission
                                  .price,
                            ),
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF9B8D98,
                              ),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Estimasi',
                      style:
                          TextStyle(
                        color:
                            Color(
                          0xFFB0A1AB,
                        ),
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatCompact(
                        commission
                            .estimatedCommission,
                      ),
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFFE84983,
                        ),
                        fontWeight:
                            FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCommissionDetail(
    AffiliateCommission commission,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            28,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFE9DDE4,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration:
                          BoxDecoration(
                        gradient:
                            const LinearGradient(
                          colors: [
                            Color(
                              0xFFFF8DB7,
                            ),
                            Color(
                              0xFFE84983,
                            ),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          17,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .account_balance_wallet_rounded,
                        color:
                            Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Detail Komisi',
                            style:
                                TextStyle(
                              fontSize:
                                  18,
                              fontWeight:
                                  FontWeight
                                      .w800,
                              color:
                                  Color(
                                0xFF342A35,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            commission
                                .productName,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF91818D,
                              ),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _detailRow(
                  'Platform',
                  commission.platform,
                ),
                _detailRow(
                  'Harga Produk',
                  _formatRupiah(
                    commission.price,
                  ),
                ),
                _detailRow(
                  'Persentase Komisi',
                  '${commission.commissionPercent.toStringAsFixed(0)}%',
                ),
                const Divider(
                  height: 24,
                  color:
                      Color(0xFFF1E4EA),
                ),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    const Text(
                      'Estimasi Komisi',
                      style:
                          TextStyle(
                        color:
                            Color(
                          0xFF4B3E4C,
                        ),
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _formatRupiah(
                        commission
                            .estimatedCommission,
                      ),
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFFE84983,
                        ),
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFFE84983,
                      ),
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          15,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 11,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Text(
            label,
            style:
                const TextStyle(
              color:
                  Color(0xFF958792),
              fontSize: 11,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                color:
                    Color(0xFF493C4A),
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color:
              const Color(0xFFF3E3EA),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration:
                const BoxDecoration(
              color: Color(0xFFFFE8F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .account_balance_wallet_outlined,
              color:
                  Color(0xFFE84983),
              size: 34,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Belum ada data komisi',
            style:
                TextStyle(
              color:
                  Color(0xFF433744),
              fontWeight:
                  FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tambahkan produk affiliate terlebih dahulu untuk melihat estimasi komisinya.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Color(0xFF9B8D98),
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFE84983),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              color:
                  Color(0xFFE84983),
              size: 45,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat data komisi',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              error,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Color(0xFF9B8D98),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFE84983,
                ),
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  _SummaryData(
    this.title,
    this.value,
    this.subtitle,
    this.icon,
    this.color,
  );
}