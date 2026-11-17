import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/affiliate_link.dart';
import '../services/affiliate_link_service.dart';
import '../widgets/affiliate_link_form_sheet.dart';

class AffiliateLinksPage extends StatefulWidget {
  const AffiliateLinksPage({
    super.key,
  });

  @override
  State<AffiliateLinksPage> createState() =>
      _AffiliateLinksPageState();
}

class _AffiliateLinksPageState
    extends State<AffiliateLinksPage>
    with SingleTickerProviderStateMixin {
  final AffiliateLinkService _service =
      AffiliateLinkService();

  final TextEditingController _searchController =
      TextEditingController();

  late AnimationController _animationController;

  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Favorit',
    'TikTok Shop',
    'Shopee',
    'Tokopedia',
    'Instagram',
    'YouTube',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 800),
    )..forward();

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<AffiliateLink> _filteredLinks(
    List<AffiliateLink> links,
  ) {
    final query =
        _searchController.text
            .trim()
            .toLowerCase();

    return links.where((link) {
      final matchesSearch =
          query.isEmpty ||
          link.name
              .toLowerCase()
              .contains(query) ||
          link.productName
              .toLowerCase()
              .contains(query) ||
          link.platform
              .toLowerCase()
              .contains(query) ||
          link.url
              .toLowerCase()
              .contains(query);

      final matchesFilter =
          _selectedFilter == 'Semua'
              ? true
              : _selectedFilter ==
                      'Favorit'
                  ? link.isFavorite
                  : link.platform ==
                      _selectedFilter;

      return matchesSearch &&
          matchesFilter;
    }).toList();
  }

  Future<void> _showForm({
    AffiliateLink? link,
  }) async {
    final result =
        await showModalBottomSheet<
            AffiliateLink>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AffiliateLinkFormSheet(
          link: link,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    _showSnackBar(
      link == null
          ? 'Link affiliate berhasil ditambahkan 🎉'
          : 'Link affiliate berhasil diperbarui ✨',
    );
  }

  Future<void> _deleteLink(
    AffiliateLink link,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Text(
            'Hapus Link?',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF342A35),
            ),
          ),
          content: Text(
            'Link "${link.name}" akan dihapus permanen.',
            style: const TextStyle(
              color:
                  Color(0xFF81727E),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Batal',
                style: TextStyle(
                  color:
                      Color(0xFF8C7B87),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
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
              ),
              child: const Text(
                'Hapus',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _service.deleteLink(
        link.id,
      );

      if (!mounted) return;

      _showSnackBar(
        'Link berhasil dihapus.',
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Gagal menghapus link.',
      );
    }
  }

  Future<void> _toggleFavorite(
    AffiliateLink link,
  ) async {
    try {
      await _service.toggleFavorite(
        link.id,
        !link.isFavorite,
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Gagal memperbarui favorit.',
      );
    }
  }

  Future<void> _copyLink(
    AffiliateLink link,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: link.url),
    );

    if (!mounted) return;

    _showSnackBar(
      'Link berhasil disalin 📋',
    );
  }

  Future<void> _openLink(
    AffiliateLink link,
  ) async {
    final uri = Uri.tryParse(
      link.url,
    );

    if (uri == null) {
      _showSnackBar(
        'URL tidak valid.',
      );
      return;
    }

    try {
      final opened =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception();
      }

      await _service.incrementClicks(
        link.id,
      );
    } catch (_) {
      if (!mounted) return;

      _showSnackBar(
        'Link tidak dapat dibuka.',
      );
    }
  }

  void _showSnackBar(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        backgroundColor:
            const Color(0xFF29222D),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
    );
  }

  Color _platformColor(
    String platform,
  ) {
    switch (platform) {
      case 'TikTok Shop':
        return const Color(0xFF29222D);
      case 'Shopee':
        return const Color(0xFFFF6B35);
      case 'Tokopedia':
        return const Color(0xFF34A853);
      case 'Instagram':
        return const Color(0xFFE84983);
      case 'YouTube':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF9C7BFF);
    }
  }

  IconData _platformIcon(
    String platform,
  ) {
    switch (platform) {
      case 'TikTok Shop':
        return Icons.music_note_rounded;
      case 'Shopee':
        return Icons.shopping_bag_rounded;
      case 'Tokopedia':
        return Icons.storefront_rounded;
      case 'Instagram':
        return Icons.camera_alt_rounded;
      case 'YouTube':
        return Icons.play_circle_fill_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8FC),
      body: SafeArea(
        child: StreamBuilder<
            List<AffiliateLink>>(
          stream: _service.getLinks(),
          builder:
              (context, snapshot) {
            final links =
                snapshot.data ?? [];

            final filtered =
                _filteredLinks(
              links,
            );

            return LayoutBuilder(
              builder:
                  (context, constraints) {
                final isMobile =
                    constraints.maxWidth <
                        700;

                final isTablet =
                    constraints.maxWidth >=
                            700 &&
                        constraints.maxWidth <
                            1050;

                return _buildPage(
                  links: links,
                  filteredLinks:
                      filtered,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isLoading:
                      snapshot.connectionState ==
                          ConnectionState
                              .waiting &&
                      !snapshot.hasData,
                  hasError:
                      snapshot.hasError,
                );
              },
            );
          },
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () =>
            _showForm(),
        backgroundColor:
            const Color(0xFFE84983),
        foregroundColor:
            Colors.white,
        elevation: 8,
        icon: const Icon(
          Icons.add_link_rounded,
        ),
        label: const Text(
          'Tambah Link',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required List<AffiliateLink> links,
    required List<AffiliateLink>
        filteredLinks,
    required bool isMobile,
    required bool isTablet,
    required bool isLoading,
    required bool hasError,
  }) {
    final totalClicks =
        links.fold<int>(
      0,
      (sum, link) =>
          sum + link.clicks,
    );

    final favorites =
        links.where(
      (link) => link.isFavorite,
    ).length;

    return AnimatedBuilder(
      animation:
          _animationController,
      builder: (context, child) {
        final animation =
            CurvedAnimation(
          parent:
              _animationController,
          curve:
              Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
              begin:
                  const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        physics:
            const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          isMobile ? 14 : 25,
          14,
          isMobile ? 14 : 25,
          100,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildHeader(
              isMobile,
            ),
            const SizedBox(height: 20),
            _buildSummary(
              totalLinks: links.length,
              totalClicks:
                  totalClicks,
              favorites: favorites,
              isMobile: isMobile,
            ),
            const SizedBox(height: 20),
            _buildSearchAndFilter(
              isMobile,
            ),
            const SizedBox(height: 20),
            if (isLoading)
              _buildLoading()
            else if (hasError)
              _buildError()
            else if (filteredLinks.isEmpty)
              _buildEmpty(
                hasAnyLinks:
                    links.isNotEmpty,
              )
            else
              _buildLinkGrid(
                filteredLinks,
                isMobile,
                isTablet,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    bool isMobile,
  ) {
    return Row(
      children: [
        Container(
          width: isMobile ? 48 : 55,
          height: isMobile ? 48 : 55,
          decoration:
              BoxDecoration(
            gradient:
                const LinearGradient(
              colors: [
                Color(0xFFFF82B0),
                Color(0xFFE84983),
              ],
            ),
            borderRadius:
                BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(
                  0xFFE84983,
                ).withOpacity(0.22),
                blurRadius: 18,
                offset:
                    const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.link_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Link Affiliate',
                style: TextStyle(
                  fontSize:
                      isMobile ? 22 : 29,
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
                  'Kelola, simpan, dan pantau semua link affiliate kamu.',
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
      ],
    );
  }

  Widget _buildSummary({
    required int totalLinks,
    required int totalClicks,
    required int favorites,
    required bool isMobile,
  }) {
    final cards = [
      _SummaryData(
        'Total Link',
        '$totalLinks',
        Icons.link_rounded,
        const Color(0xFFE84983),
      ),
      _SummaryData(
        'Total Klik',
        '$totalClicks',
        Icons.ads_click_rounded,
        const Color(0xFFFFA34D),
      ),
      _SummaryData(
        'Favorit',
        '$favorites',
        Icons.star_rounded,
        const Color(0xFFFFB43D),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth < 560
                ? 1
                : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio:
                columns == 1
                    ? 4.0
                    : 2.1,
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
        decoration:
            BoxDecoration(
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
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
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
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF342A35),
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w800,
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
          decoration: InputDecoration(
            hintText:
                'Cari nama link, produk, atau platform...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color:
                  Color(0xFFE84983),
            ),
            suffixIcon:
                _searchController
                        .text
                        .isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController
                              .clear();
                        },
                        icon:
                            const Icon(
                          Icons
                              .close_rounded,
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
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,
          physics:
              const BouncingScrollPhysics(),
          child: Row(
            children:
                _filters.map(
              (filter) {
                final selected =
                    _selectedFilter ==
                        filter;

                return Padding(
                  padding:
                      const EdgeInsets
                          .only(
                    right: 8,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      filter,
                    ),
                    selected:
                        selected,
                    onSelected:
                        (_) {
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
                        BorderSide(
                      color:
                          selected
                              ? const Color(
                                  0xFFE84983,
                                )
                              : const Color(
                                  0xFFF0E0E8,
                                ),
                    ),
                    labelStyle:
                        TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(
                              0xFF6C5C68,
                            ),
                      fontWeight:
                          selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                      fontSize: 11,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        30,
                      ),
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 6,
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkGrid(
    List<AffiliateLink> links,
    bool isMobile,
    bool isTablet,
  ) {
    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        itemCount: links.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(height: 13),
        itemBuilder:
            (context, index) {
          return _buildAnimatedLinkCard(
            links[index],
            index,
          );
        },
      );
    }

    final columns =
        isTablet ? 2 : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: links.length,
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            columns,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio:
            isTablet ? 1.55 : 1.45,
      ),
      itemBuilder:
          (context, index) {
        return _buildAnimatedLinkCard(
          links[index],
          index,
        );
      },
    );
  }

  Widget _buildAnimatedLinkCard(
    AffiliateLink link,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(
        milliseconds:
            350 + index * 70,
      ),
      tween: Tween(
        begin: 0,
        end: 1,
      ),
      curve: Curves.easeOutCubic,
      builder:
          (context, value, child) {
        return Transform.translate(
          offset: Offset(
            0,
            15 * (1 - value),
          ),
          child: Opacity(
            opacity:
                value.clamp(0, 1),
            child: child,
          ),
        );
      },
      child: _buildLinkCard(link),
    );
  }

  Widget _buildLinkCard(
    AffiliateLink link,
  ) {
    final platformColor =
        _platformColor(
      link.platform,
    );

    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(21),
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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration:
                    BoxDecoration(
                  color: platformColor
                      .withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  _platformIcon(
                    link.platform,
                  ),
                  color:
                      platformColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF3B303D),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      link.platform,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          TextStyle(
                        color:
                            platformColor,
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons
                      .more_vert_rounded,
                  color:
                      Color(0xFF9C8D98),
                  size: 20,
                ),
                onSelected:
                    (value) {
                  if (value ==
                      'edit') {
                    _showForm(
                      link: link,
                    );
                  } else if (value ==
                      'delete') {
                    _deleteLink(
                      link,
                    );
                  }
                },
                itemBuilder:
                    (context) {
                  return const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .edit_outlined,
                            size: 18,
                          ),
                          SizedBox(
                            width: 9,
                          ),
                          Text(
                            'Edit',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .delete_outline_rounded,
                            size: 18,
                            color:
                                Color(
                              0xFFE84983,
                            ),
                          ),
                          SizedBox(
                            width: 9,
                          ),
                          Text(
                            'Hapus',
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (link.productName
              .trim()
              .isNotEmpty)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFFFF7FA,
                ),
                borderRadius:
                    BorderRadius.circular(
                  11,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .shopping_bag_outlined,
                    size: 15,
                    color:
                        Color(0xFFE84983),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      link.productName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF655565),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 11),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFF9F5F8),
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  size: 15,
                  color:
                      Color(0xFF9B8D98),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    link.url,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF8A7A86),
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFFFF4E7,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .ads_click_rounded,
                      size: 13,
                      color:
                          Color(0xFFFFA34D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${link.clicks} klik',
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFFD78326,
                        ),
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip:
                    'Salin link',
                onPressed: () =>
                    _copyLink(
                  link,
                ),
                icon:
                    const Icon(
                  Icons
                      .content_copy_rounded,
                  size: 18,
                  color:
                      Color(0xFF9C8D98),
                ),
              ),
              IconButton(
                tooltip:
                    'Favorit',
                onPressed: () =>
                    _toggleFavorite(
                  link,
                ),
                icon: Icon(
                  link.isFavorite
                      ? Icons
                          .star_rounded
                      : Icons
                          .star_border_rounded,
                  size: 20,
                  color:
                      link.isFavorite
                          ? const Color(
                              0xFFFFB43D,
                            )
                          : const Color(
                              0xFF9C8D98,
                            ),
                ),
              ),
              const SizedBox(width: 3),
              SizedBox(
                height: 36,
                child:
                    ElevatedButton.icon(
                  onPressed: () =>
                      _openLink(
                    link,
                  ),
                  style:
                      ElevatedButton
                          .styleFrom(
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
                      horizontal: 12,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        11,
                      ),
                    ),
                  ),
                  icon:
                      const Icon(
                    Icons
                        .open_in_new_rounded,
                    size: 15,
                  ),
                  label:
                      const Text(
                    'Buka',
                    style:
                        TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(40),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: const Center(
        child:
            CircularProgressIndicator(
          color:
              Color(0xFFE84983),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(30),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              const Color(0xFFF3E3EA),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons
                .error_outline_rounded,
            color:
                Color(0xFFE84983),
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            'Gagal memuat link affiliate.',
            style:
                TextStyle(
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF443744),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Periksa koneksi Firebase dan Firestore.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Color(0xFF998A95),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty({
    required bool hasAnyLinks,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 45,
      ),
      decoration:
          BoxDecoration(
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
            width: 75,
            height: 75,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFFFEAF2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.link_off_rounded,
              color:
                  Color(0xFFE84983),
              size: 34,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            hasAnyLinks
                ? 'Link tidak ditemukan'
                : 'Belum ada link affiliate',
            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF3D323E),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hasAnyLinks
                ? 'Coba gunakan kata kunci atau filter lain.'
                : 'Tambahkan link affiliate pertama kamu untuk mulai mengelolanya.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Color(0xFF998A95),
              fontSize: 11,
              height: 1.5,
            ),
          ),
          if (!hasAnyLinks) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  _showForm(),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFE84983,
                ),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.add_link_rounded,
              ),
              label: const Text(
                'Tambah Link Pertama',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _SummaryData(
    this.title,
    this.value,
    this.icon,
    this.color,
  );
}