import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/affiliate_content.dart';
import '../services/content_service.dart';

class ContentPage extends StatefulWidget {
  final bool autoOpenForm;

  const ContentPage({
    super.key,
    this.autoOpenForm = false,
  });

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage>
    with SingleTickerProviderStateMixin {
  final ContentService _contentService = ContentService();

  final TextEditingController _searchController =
      TextEditingController();

  late AnimationController _animationController;

  String _search = '';
  String _platformFilter = 'Semua';
  String _statusFilter = 'Semua';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animationController.forward();

    if (widget.autoOpenForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showContentForm();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<AffiliateContent> _filterContents(
    List<AffiliateContent> contents,
  ) {
    return contents.where((content) {
      final matchesSearch =
          content.title.toLowerCase().contains(
                _search.toLowerCase(),
              ) ||
          content.description.toLowerCase().contains(
                _search.toLowerCase(),
              ) ||
          content.platform.toLowerCase().contains(
                _search.toLowerCase(),
              );

      final matchesPlatform =
          _platformFilter == 'Semua' ||
          content.platform == _platformFilter;

      final matchesStatus =
          _statusFilter == 'Semua' ||
          content.status == _statusFilter;

      return matchesSearch &&
          matchesPlatform &&
          matchesStatus;
    }).toList();
  }

  Future<void> _showContentForm({
    AffiliateContent? content,
  }) async {
    final result =
        await showModalBottomSheet<AffiliateContent>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _ContentFormSheet(
          content: content,
        );
      },
    );

    if (!mounted || result == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          content == null
              ? 'Konten berhasil ditambahkan 🎉'
              : 'Konten berhasil diperbarui ✨',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFE88EAD),
      ),
    );
  }

  Future<void> _deleteContent(
    AffiliateContent content,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Hapus Konten?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Konten "${content.title}" akan dihapus permanen.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _contentService.deleteContent(content.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konten berhasil dihapus'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus konten: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openLink(String link) async {
    if (link.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link konten belum tersedia.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(link.trim());

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link tidak valid.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link tidak dapat dibuka.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat membuka link.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FB),
      body: Stack(
        children: [
          _buildBackground(),

          SafeArea(
            child: StreamBuilder<List<AffiliateContent>>(
              stream: _contentService.getContents(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString());
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE88EAD),
                    ),
                  );
                }

                final contents =
                    snapshot.data ?? <AffiliateContent>[];

                final filtered =
                    _filterContents(contents);

                final draftCount = contents
                    .where((e) => e.status == 'Draft')
                    .length;

                final postedCount = contents
                    .where((e) => e.status == 'Diposting')
                    .length;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop =
                        constraints.maxWidth >= 900;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            isDesktop ? 40 : 18,
                        vertical: 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(
                            maxWidth: 1450,
                          ),
                          child: FadeTransition(
                            opacity: CurvedAnimation(
                              parent:
                                  _animationController,
                              curve: Curves.easeOut,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 26),
                                _buildStats(
                                  contents.length,
                                  draftCount,
                                  postedCount,
                                ),
                                const SizedBox(height: 26),
                                _buildSearch(),
                                const SizedBox(height: 16),
                                _buildFilters(),
                                const SizedBox(height: 24),
                                if (filtered.isEmpty)
                                  _buildEmpty()
                                else
                                  _buildContentGrid(
                                    filtered,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE88EAD),
        foregroundColor: Colors.white,
        elevation: 8,
        onPressed: () => _showContentForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Konten',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -100,
          child: _glowCircle(
            280,
            const Color(0xFFFFC9DC),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -100,
          child: _glowCircle(
            300,
            const Color(0xFFF8DCE8),
          ),
        ),
      ],
    );
  }

  Widget _glowCircle(
    double size,
    Color color,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.35),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 70,
          sigmaY: 70,
        ),
        child: const SizedBox(),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE88EAD),
                Color(0xFFF4B7CB),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFFE88EAD)
                        .withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.video_library_rounded,
            color: Colors.white,
            size: 29,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: const [
              Text(
                'Konten Affiliate',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF34222A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Kelola semua konten promosi affiliate kamu.',
                style: TextStyle(
                  color: Color(0xFF8D737D),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats(
    int total,
    int draft,
    int posted,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardWidth =
            width < 600
                ? width
                : (width - 32) / 3;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _statCard(
                icon: Icons.article_rounded,
                title: 'Total Konten',
                value: total.toString(),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _statCard(
                icon: Icons.edit_note_rounded,
                title: 'Draft',
                value: draft.toString(),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _statCard(
                icon: Icons.check_circle_rounded,
                title: 'Diposting',
                value: posted.toString(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF3DCE5),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.035),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF4),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFE88EAD),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF8D737D),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF34222A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Cari judul atau deskripsi konten...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFFE88EAD),
        ),
        suffixIcon:
            _search.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _search = '';
                      });
                    },
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFF3DCE5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFE88EAD),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Platform',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF4D3740),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip(
              'Semua',
              _platformFilter,
              (value) {
                setState(() {
                  _platformFilter = value;
                });
              },
            ),
            _filterChip(
              'TikTok',
              _platformFilter,
              (value) {
                setState(() {
                  _platformFilter = value;
                });
              },
            ),
            _filterChip(
              'Instagram',
              _platformFilter,
              (value) {
                setState(() {
                  _platformFilter = value;
                });
              },
            ),
            _filterChip(
              'YouTube',
              _platformFilter,
              (value) {
                setState(() {
                  _platformFilter = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Status',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF4D3740),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip(
              'Semua',
              _statusFilter,
              (value) {
                setState(() {
                  _statusFilter = value;
                });
              },
            ),
            _filterChip(
              'Draft',
              _statusFilter,
              (value) {
                setState(() {
                  _statusFilter = value;
                });
              },
            ),
            _filterChip(
              'Diposting',
              _statusFilter,
              (value) {
                setState(() {
                  _statusFilter = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _filterChip(
    String label,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    final active = label == selected;

    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) {
        onSelected(label);
      },
      selectedColor: const Color(0xFFE88EAD),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color:
            active
                ? Colors.white
                : const Color(0xFF6E5961),
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color:
            active
                ? const Color(0xFFE88EAD)
                : const Color(0xFFF0DDE5),
      ),
    );
  }

  Widget _buildContentGrid(
    List<AffiliateContent> contents,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1200) {
          columns = 3;
        } else if (constraints.maxWidth >= 700) {
          columns = 2;
        } else {
          columns = 1;
        }

        final spacing = 18.0;
        final cardWidth =
            (constraints.maxWidth -
                ((columns - 1) * spacing)) /
            columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: contents.map((content) {
            return SizedBox(
              width: cardWidth,
              child: _buildContentCard(content),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildContentCard(
    AffiliateContent content,
  ) {
    final platformColor =
        _platformColor(content.platform);

    final posted =
        content.status == 'Diposting';

    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: 0.94,
        end: 1,
      ),
      duration:
          const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFF1DCE5),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.045,
              ),
              blurRadius: 25,
              offset: const Offset(0, 10),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: platformColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _platformIcon(
                      content.platform,
                    ),
                    color: platformColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    content.title,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: Color(0xFF34222A),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF9B7E89),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showContentForm(
                        content: content,
                      );
                    } else if (value == 'delete') {
                      _deleteContent(content);
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 19,
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
                              Icons.delete_outline,
                              size: 19,
                              color: Colors.redAccent,
                            ),
                            SizedBox(width: 10),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _badge(
                  content.platform,
                  platformColor,
                ),
                _badge(
                  content.status,
                  posted
                      ? Colors.green
                      : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              content.description.isEmpty
                  ? 'Tidak ada deskripsi.'
                  : content.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                height: 1.5,
                color: Color(0xFF7E6871),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            if (content.contentLink.isNotEmpty)
              InkWell(
                borderRadius:
                    BorderRadius.circular(14),
                onTap: () {
                  _openLink(
                    content.contentLink,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F8),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        color:
                            Color(0xFFE88EAD),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Buka link konten',
                          style: TextStyle(
                            color:
                                Color(0xFFE0789F),
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new_rounded,
                        color:
                            Color(0xFFE88EAD),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF8F5F6),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.link_off_rounded,
                      color: Color(0xFFAD969F),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Belum ada link konten',
                      style: TextStyle(
                        color:
                            Color(0xFF9B858D),
                        fontWeight:
                            FontWeight.w600,
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

  Widget _badge(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _platformColor(String platform) {
    switch (platform) {
      case 'TikTok':
        return Colors.black87;
      case 'Instagram':
        return const Color(0xFFE1306C);
      case 'YouTube':
        return const Color(0xFFFF0000);
      default:
        return const Color(0xFFE88EAD);
    }
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'TikTok':
        return Icons.music_note_rounded;
      case 'Instagram':
        return Icons.camera_alt_rounded;
      case 'YouTube':
        return Icons.play_circle_fill_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 70,
        horizontal: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFF1DCE5),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFEEF4),
            ),
            child: const Icon(
              Icons.video_library_outlined,
              size: 42,
              color: Color(0xFFE88EAD),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada konten',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Color(0xFF34222A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mulai tambahkan konten affiliate pertama kamu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8D737D),
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () => _showContentForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFFE88EAD),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Tambah Konten',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat konten',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentFormSheet extends StatefulWidget {
  final AffiliateContent? content;

  const _ContentFormSheet({
    this.content,
  });

  @override
  State<_ContentFormSheet> createState() =>
      _ContentFormSheetState();
}

class _ContentFormSheetState
    extends State<_ContentFormSheet> {
  final _formKey = GlobalKey<FormState>();

  final ContentService _contentService =
      ContentService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _linkController;

  String _platform = 'TikTok';
  String _status = 'Draft';

  bool _saving = false;

  bool get _isEdit => widget.content != null;

  @override
  void initState() {
    super.initState();

    final content = widget.content;

    _titleController =
        TextEditingController(
      text: content?.title ?? '',
    );

    _descriptionController =
        TextEditingController(
      text: content?.description ?? '',
    );

    _linkController =
        TextEditingController(
      text: content?.contentLink ?? '',
    );

    _platform =
        content?.platform ?? 'TikTok';

    _status =
        content?.status ?? 'Draft';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final content = AffiliateContent(
        id: widget.content?.id ?? '',
        title: _titleController.text.trim(),
        platform: _platform,
        description:
            _descriptionController.text.trim(),
        contentLink:
            _linkController.text.trim(),
        status: _status,
      );

      if (_isEdit) {
        await _contentService.updateContent(
          content,
        );
      } else {
        await _contentService.addContent(
          content,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, content);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan konten: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        bottom: bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFAFC),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            22,
            16,
            22,
            25,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6CCD7),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isEdit
                      ? 'Edit Konten'
                      : 'Tambah Konten',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF34222A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isEdit
                      ? 'Perbarui informasi konten kamu.'
                      : 'Tambahkan konten affiliate baru.',
                  style: const TextStyle(
                    color: Color(0xFF8D737D),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    'Judul Konten',
                    Icons.title_rounded,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Judul konten wajib diisi';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _platform,
                  decoration: _inputDecoration(
                    'Platform',
                    Icons.public_rounded,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'TikTok',
                      child: Text('TikTok'),
                    ),
                    DropdownMenuItem(
                      value: 'Instagram',
                      child: Text('Instagram'),
                    ),
                    DropdownMenuItem(
                      value: 'YouTube',
                      child: Text('YouTube'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _platform = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: _inputDecoration(
                    'Status Konten',
                    Icons.flag_rounded,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Draft',
                      child: Text('Draft'),
                    ),
                    DropdownMenuItem(
                      value: 'Diposting',
                      child: Text('Diposting'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _status = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller:
                      _descriptionController,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    'Deskripsi / Caption',
                    Icons.notes_rounded,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _linkController,
                  keyboardType:
                      TextInputType.url,
                  decoration: _inputDecoration(
                    'Link Konten',
                    Icons.link_rounded,
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFE88EAD),
                      foregroundColor: Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(17),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEdit
                                ? 'Simpan Perubahan'
                                : 'Simpan Konten',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFFE88EAD),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFF0DCE5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFF0DCE5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE88EAD),
          width: 1.5,
        ),
      ),
    );
  }
}