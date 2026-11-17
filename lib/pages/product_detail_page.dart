import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/affiliate_product.dart';
import '../services/product_service.dart';
import '../widgets/product_form_sheet.dart';

class ProductDetailPage extends StatefulWidget {
  final AffiliateProduct product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();

  late AffiliateProduct product;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isFavoriteLoading = false;
  bool _isPriorityLoading = false;

  @override
  void initState() {
    super.initState();

    product = widget.product;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String formatRupiah(double value) {
    final text = value.toStringAsFixed(0);
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return 'Rp ${buffer.toString()}';
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) return;

    final newValue = !product.isFavorite;

    setState(() {
      _isFavoriteLoading = true;
    });

    try {
      await _productService.toggleFavorite(
        product.id,
        newValue,
      );

      if (!mounted) return;

      setState(() {
        product.isFavorite = newValue;
        _isFavoriteLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isFavoriteLoading = false;
      });

      _showMessage(
        'Gagal mengubah favorit',
        isError: true,
      );
    }
  }

  Future<void> _togglePriority() async {
    if (_isPriorityLoading) return;

    final newValue = !product.isPriority;

    setState(() {
      _isPriorityLoading = true;
    });

    try {
      await _productService.togglePriority(
        product.id,
        newValue,
      );

      if (!mounted) return;

      setState(() {
        product.isPriority = newValue;
        _isPriorityLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isPriorityLoading = false;
      });

      _showMessage(
        'Gagal mengubah priority',
        isError: true,
      );
    }
  }

  // ============================================================
  // EDIT PRODUK
  // ============================================================

  Future<void> _editProduct() async {
    final result = await showModalBottomSheet<AffiliateProduct>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ProductFormSheet(
          product: product,
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        product = result;
      });

      _showMessage(
        'Produk berhasil diperbarui ✨',
      );
    }
  }

  Future<void> _openAffiliateLink() async {
    final link = product.affiliateLink.trim();

    if (link.isEmpty) {
      _showMessage(
        'Link affiliate belum tersedia',
        isError: true,
      );
      return;
    }

    Uri? uri = Uri.tryParse(link);

    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https')) {
      _showMessage(
        'Link affiliate tidak valid',
        isError: true,
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage(
          'Tidak dapat membuka link',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Terjadi kesalahan saat membuka link',
        isError: true,
      );
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Hapus Produk?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D1B22),
            ),
          ),
          content: Text(
            'Produk "${product.name}" akan dihapus secara permanen.',
            style: const TextStyle(
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Hapus',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _productService.deleteProduct(product.id);

      if (!mounted) return;

      _showMessage('Produk berhasil dihapus');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Gagal menghapus produk',
        isError: true,
      );
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? Colors.redAccent : const Color(0xFFC65379),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimated = product.estimatedCommission;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Detail Produk',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D1B22),
          ),
        ),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2D1B22),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // ======================================================
          // TOMBOL EDIT
          // ======================================================
          IconButton(
            tooltip: 'Edit Produk',
            onPressed: _editProduct,
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFFC65379),
            ),
          ),

          // ======================================================
          // TOMBOL HAPUS
          // ======================================================
          IconButton(
            tooltip: 'Hapus Produk',
            onPressed: _deleteProduct,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 70 : 20,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1100,
                  ),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildProductImage(),
                            ),
                            const SizedBox(width: 30),
                            Expanded(
                              child: _buildProductInfo(
                                estimated,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildProductImage(),
                            const SizedBox(height: 24),
                            _buildProductInfo(estimated),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: 420,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE5EF),
            Color(0xFFFFF6F9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1FC65379),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: product.imageUrl.trim().isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder:
                    (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return _imageLoading();
                },
                errorBuilder: (_, __, ___) {
                  return _imagePlaceholder();
                },
              ),
            )
          : _imagePlaceholder(),
    );
  }

  Widget _imageLoading() {
    return const Center(
      child: SizedBox(
        width: 35,
        height: 35,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Color(0xFFC65379),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return const Center(
      child: Icon(
        Icons.shopping_bag_rounded,
        size: 100,
        color: Color(0xFFD98AA5),
      ),
    );
  }

  Widget _buildProductInfo(double estimated) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _badge(
              product.platform.isEmpty
                  ? 'Affiliate'
                  : product.platform,
              const Color(0xFFFFE4ED),
              const Color(0xFFB94E72),
            ),
            if (product.isPriority)
              _badge(
                'PRIORITY',
                const Color(0xFFFFE8C7),
                const Color(0xFFB96A00),
              ),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          product.name,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2D1B22),
            height: 1.2,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          formatRupiah(product.price),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFFC65379),
          ),
        ),

        const SizedBox(height: 24),

        _buildCommissionCard(estimated),

        const SizedBox(height: 20),

        _buildActions(),

        const SizedBox(height: 24),

        _buildAffiliateLink(),

        const SizedBox(height: 20),

        // ========================================================
        // TOMBOL EDIT PRODUK
        // ========================================================
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _editProduct,
            icon: const Icon(
              Icons.edit_outlined,
            ),
            label: const Text(
              'Edit Produk',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC65379),
              side: const BorderSide(
                color: Color(0xFFE3A0B5),
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCommissionCard(double estimated) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFC65379),
            Color(0xFFE08AA5),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40C65379),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimasi Komisi',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(estimated),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.commission.toStringAsFixed(1)}% komisi',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                _isFavoriteLoading ? null : _toggleFavorite,
            icon: _isFavoriteLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFC65379),
                    ),
                  )
                : Icon(
                    product.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                  ),
            label: Text(
              product.isFavorite
                  ? 'Favorit'
                  : 'Tambah Favorit',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC65379),
              disabledForegroundColor:
                  const Color(0xFFC65379),
              side: const BorderSide(
                color: Color(0xFFE3A0B5),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                _isPriorityLoading ? null : _togglePriority,
            icon: _isPriorityLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    product.isPriority
                        ? Icons.local_fire_department_rounded
                        : Icons
                            .local_fire_department_outlined,
                  ),
            label: Text(
              product.isPriority
                  ? 'Priority'
                  : 'Set Priority',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC65379),
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  const Color(0xFFC65379),
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAffiliateLink() {
    final hasLink =
        product.affiliateLink.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF0D5DE),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0AC65379),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.link_rounded,
                color: Color(0xFFC65379),
              ),
              SizedBox(width: 8),
              Text(
                'Affiliate Link',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF2D1B22),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (hasLink)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SelectableText(
                product.affiliateLink,
                style: const TextStyle(
                  color: Colors.black54,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            )
          else
            const Text(
              'Belum ada link affiliate.',
              style: TextStyle(
                color: Colors.black45,
                height: 1.5,
              ),
            ),

          if (hasLink) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openAffiliateLink,
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  size: 19,
                ),
                label: const Text(
                  'Buka Link Affiliate',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFFFE4ED),
                  foregroundColor:
                      const Color(0xFFC65379),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(
    String text,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}