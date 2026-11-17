import 'package:flutter/material.dart';

import '../models/affiliate_link.dart';
import '../services/affiliate_link_service.dart';

class AffiliateLinkFormSheet extends StatefulWidget {
  final AffiliateLink? link;

  const AffiliateLinkFormSheet({
    super.key,
    this.link,
  });

  @override
  State<AffiliateLinkFormSheet> createState() =>
      _AffiliateLinkFormSheetState();
}

class _AffiliateLinkFormSheetState
    extends State<AffiliateLinkFormSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  final AffiliateLinkService _service =
      AffiliateLinkService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _platform = 'TikTok';
  bool _isSaving = false;

  bool get _isEdit => widget.link != null;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    if (widget.link != null) {
      _nameController.text = widget.link!.name;
      _urlController.text = widget.link!.url;
      _platform = widget.link!.platform;
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final link = AffiliateLink(
        id: widget.link?.id ?? '',
        name: _nameController.text.trim(),
        platform: _platform,
        url: _urlController.text.trim(),
      );

      if (_isEdit) {
        await _service.updateLink(link);
      } else {
        await _service.addLink(link);
      }

      if (!mounted) return;

      Navigator.pop(context, link);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan link: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Link affiliate wajib diisi';
    }

    final uri = Uri.tryParse(value.trim());

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority) {
      return 'Masukkan link yang valid';
    }

    return null;
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'TikTok':
        return Icons.music_note_rounded;
      case 'Shopee':
        return Icons.shopping_bag_rounded;
      case 'Tokopedia':
        return Icons.storefront_rounded;
      case 'Instagram':
        return Icons.camera_alt_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: bottomInset,
        ),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 650,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  14,
                  24,
                  30,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7C7D2),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE88EAD),
                                  Color(0xFFF5B7CA),
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.circular(17),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE88EAD,
                                  ).withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset:
                                      const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.link_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEdit
                                      ? 'Edit Link Affiliate'
                                      : 'Tambah Link Affiliate',
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight:
                                        FontWeight.w800,
                                    color:
                                        Color(0xFF3E2730),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isEdit
                                      ? 'Perbarui informasi link kamu'
                                      : 'Simpan link affiliate dengan rapi',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color:
                                        Color(0xFF907681),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Nama Link',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A3039),
                        ),
                      ),

                      const SizedBox(height: 9),

                      TextFormField(
                        controller: _nameController,
                        textInputAction:
                            TextInputAction.next,
                        decoration: _inputDecoration(
                          hint:
                              'Contoh: Link Produk Skincare',
                          icon: Icons.title_rounded,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Nama link wajib diisi';
                          }

                          if (value.trim().length < 3) {
                            return 'Nama link terlalu pendek';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Platform',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A3039),
                        ),
                      ),

                      const SizedBox(height: 9),

                      DropdownButtonFormField<String>(
                        initialValue: _platform,
                        decoration: _inputDecoration(
                          hint: 'Pilih platform',
                          icon:
                              _platformIcon(_platform),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'TikTok',
                            child: Text('TikTok'),
                          ),
                          DropdownMenuItem(
                            value: 'Shopee',
                            child: Text('Shopee'),
                          ),
                          DropdownMenuItem(
                            value: 'Tokopedia',
                            child: Text('Tokopedia'),
                          ),
                          DropdownMenuItem(
                            value: 'Instagram',
                            child: Text('Instagram'),
                          ),
                          DropdownMenuItem(
                            value: 'Lainnya',
                            child: Text('Lainnya'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _platform = value;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Link Affiliate',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A3039),
                        ),
                      ),

                      const SizedBox(height: 9),

                      TextFormField(
                        controller: _urlController,
                        keyboardType:
                            TextInputType.url,
                        textInputAction:
                            TextInputAction.done,
                        decoration: _inputDecoration(
                          hint:
                              'https://contoh.com/affiliate',
                          icon: Icons.link_rounded,
                        ),
                        validator: _validateUrl,
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding:
                            const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFFF6F9),
                          borderRadius:
                              BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(
                              0xFFF2D6E0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE88EAD,
                                ).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                color:
                                    Color(0xFFE88EAD),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Link yang sudah disimpan dapat digunakan untuk mengarahkan pengguna ke halaman affiliate.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color:
                                      Color(0xFF806A73),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed:
                              _isSaving ? null : _save,
                          style:
                              ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor:
                                const Color(0xFFE88EAD),
                            foregroundColor:
                                Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFFF2CBD8),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(18),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isEdit
                                          ? Icons
                                              .save_rounded
                                          : Icons
                                              .add_link_rounded,
                                    ),
                                    const SizedBox(
                                      width: 9,
                                    ),
                                    Text(
                                      _isEdit
                                          ? 'Simpan Perubahan'
                                          : 'Simpan Link',
                                      style:
                                          const TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFFE88EAD),
      ),
      filled: true,
      fillColor: const Color(0xFFFFF9FB),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: Color(0xFFF0D7E0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: Color(0xFFF0D7E0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: Color(0xFFE88EAD),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }
}