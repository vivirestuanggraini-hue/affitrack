import 'package:flutter/material.dart';

import '../models/affiliate_product.dart';
import '../services/product_service.dart';
import 'product_detail_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  late AnimationController _animationController;

  final List<String> _filters = [
    'Semua',
    'Favorit',
    'Prioritas',
    'TikTok Shop',
    'Shopee',
    'Tokopedia',
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animationController.forward();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<AffiliateProduct> _filterProducts(
    List<AffiliateProduct> products,
  ) {
    return products.where((product) {
      final matchesSearch =
          product.name.toLowerCase().contains(_searchQuery) ||
          product.platform.toLowerCase().contains(_searchQuery);

      bool matchesFilter = true;

      switch (_selectedFilter) {
        case 'Favorit':
          matchesFilter = product.isFavorite;
          break;

        case 'Prioritas':
          matchesFilter = product.isPriority;
          break;

        case 'TikTok Shop':
        case 'Shopee':
        case 'Tokopedia':
          matchesFilter = product.platform == _selectedFilter;
          break;

        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  String _formatRupiah(double value) {
    final number = value.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < number.length; i++) {
      final positionFromRight = number.length - i;

      buffer.write(number[i]);

      if (positionFromRight > 1 && positionFromRight % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp ${buffer.toString()}';
  }

  String _formatCommission(double value) {
    if (value % 1 == 0) {
      return '${value.toInt()}%';
    }

    return '${value.toStringAsFixed(1)}%';
  }

  Future<void> _showProductForm({
    AffiliateProduct? product,
  }) async {
    final nameController = TextEditingController(
      text: product?.name ?? '',
    );

    final priceController = TextEditingController(
      text: product == null ? '' : product.price.toString(),
    );

    final commissionController = TextEditingController(
      text: product == null ? '' : product.commission.toString(),
    );

    final linkController = TextEditingController(
      text: product?.affiliateLink ?? '',
    );

    String selectedPlatform = product?.platform ?? 'TikTok Shop';

    bool isFavorite = product?.isFavorite ?? false;
    bool isPriority = product?.isPriority ?? false;

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 700,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.fromLTRB(
                  22,
                  12,
                  22,
                  24,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 45,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6FAE),
                                    Color(0xFFFF9AC5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product == null
                                        ? 'Tambah Produk'
                                        : 'Edit Produk',
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF24242A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    product == null
                                        ? 'Tambahkan produk affiliate baru'
                                        : 'Perbarui informasi produk',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        _formLabel('Nama Produk'),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: nameController,
                          decoration: _inputDecoration(
                            'Contoh: Skincare Glow Serum',
                            Icons.shopping_bag_outlined,
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Nama produk wajib diisi';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _formLabel('Platform'),
                        const SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          initialValue: selectedPlatform,
                          decoration: _inputDecoration(
                            'Pilih platform',
                            Icons.storefront_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'TikTok Shop',
                              child: Text('TikTok Shop'),
                            ),
                            DropdownMenuItem(
                              value: 'Shopee',
                              child: Text('Shopee'),
                            ),
                            DropdownMenuItem(
                              value: 'Tokopedia',
                              child: Text('Tokopedia'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() {
                                selectedPlatform = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _formLabel('Harga Produk'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: priceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: _inputDecoration(
                                      'Contoh: 150000',
                                      Icons.payments_outlined,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Wajib diisi';
                                      }

                                      final price =
                                          double.tryParse(value);

                                      if (price == null || price < 0) {
                                        return 'Harga tidak valid';
                                      }

                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _formLabel('Komisi (%)'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: commissionController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: _inputDecoration(
                                      'Contoh: 10',
                                      Icons.percent_rounded,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Wajib diisi';
                                      }

                                      final commission =
                                          double.tryParse(value);

                                      if (commission == null ||
                                          commission < 0 ||
                                          commission > 100) {
                                        return '0 - 100%';
                                      }

                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _formLabel('Link Affiliate'),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: linkController,
                          keyboardType: TextInputType.url,
                          decoration: _inputDecoration(
                            'https://...',
                            Icons.link_rounded,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6FA),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFFFE0EC),
                            ),
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                value: isFavorite,
                                activeThumbColor:
                                    const Color(0xFFFF5FA2),
                                title: const Text(
                                  'Produk Favorit',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Tandai sebagai produk favorit',
                                ),
                                secondary: const Icon(
                                  Icons.favorite_rounded,
                                  color: Color(0xFFFF5FA2),
                                ),
                                onChanged: (value) {
                                  setModalState(() {
                                    isFavorite = value;
                                  });
                                },
                              ),
                              const Divider(
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                              ),
                              SwitchListTile(
                                value: isPriority,
                                activeThumbColor:
                                    const Color(0xFFFFA23D),
                                title: const Text(
                                  'Produk Prioritas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Tandai produk yang sedang diprioritaskan',
                                ),
                                secondary: const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFA23D),
                                ),
                                onChanged: (value) {
                                  setModalState(() {
                                    isPriority = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor:
                                  const Color(0xFFFF5FA2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              final price = double.parse(
                                priceController.text.trim(),
                              );

                              final commission = double.parse(
                                commissionController.text.trim(),
                              );

                              final newProduct = AffiliateProduct(
                                id: product?.id ?? '',
                                name: nameController.text.trim(),
                                platform: selectedPlatform,
                                price: price,
                                commission: commission,
                                affiliateLink:
                                    linkController.text.trim(),
                                imageUrl: product?.imageUrl ?? '',
                                isFavorite: isFavorite,
                                isPriority: isPriority,
                              );

                              Navigator.pop(context);

                              try {
                                if (product == null) {
                                  await _productService.addProduct(
                                    newProduct,
                                  );
                                } else {
                                  await _productService.updateProduct(
                                    newProduct,
                                  );
                                }

                                if (!mounted) return;

                                _showSnackBar(
                                  product == null
                                      ? 'Produk berhasil ditambahkan 🎉'
                                      : 'Produk berhasil diperbarui ✨',
                                );
                              } catch (e) {
                                if (!mounted) return;

                                _showSnackBar(
                                  'Gagal menyimpan produk.',
                                  isError: true,
                                );
                              }
                            },
                            child: Text(
                              product == null
                                  ? 'Tambah Produk'
                                  : 'Simpan Perubahan',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
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
          },
        );
      },
    );

    nameController.dispose();
    priceController.dispose();
    commissionController.dispose();
    linkController.dispose();
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 20,
        color: const Color(0xFFFF5FA2),
      ),
      filled: true,
      fillColor: const Color(0xFFF9F9FB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFFF78B1),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _formLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: Color(0xFF36363D),
      ),
    );
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? Colors.red.shade600 : const Color(0xFF24242A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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
      ),
    );
  }

  Future<void> _deleteProduct(
    AffiliateProduct product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Hapus Produk?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Produk "${product.name}" akan dihapus dari daftar affiliate kamu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _productService.deleteProduct(product.id);

      if (!mounted) return;

      _showSnackBar('Produk berhasil dihapus.');
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Gagal menghapus produk.',
        isError: true,
      );
    }
  }

  Future<void> _toggleFavorite(
    AffiliateProduct product,
  ) async {
    try {
      await _productService.toggleFavorite(
        product.id,
        !product.isFavorite,
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Gagal mengubah favorit.',
        isError: true,
      );
    }
  }

  Future<void> _togglePriority(
    AffiliateProduct product,
  ) async {
    try {
      await _productService.togglePriority(
        product.id,
        !product.isPriority,
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Gagal mengubah prioritas.',
        isError: true,
      );
    }
  }

  // ============================================================
  // NAVIGASI KE DETAIL PRODUK
  // ============================================================

  void _openProductDetail(AffiliateProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: product,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF5FA2),
        foregroundColor: Colors.white,
        elevation: 8,
        onPressed: () => _showProductForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Produk',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<AffiliateProduct>>(
          stream: _productService.getProducts(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error);
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            final allProducts = snapshot.data ?? [];

            final filteredProducts =
                _filterProducts(allProducts);

            final totalProducts = allProducts.length;

            final favoriteProducts =
                allProducts.where((p) => p.isFavorite).length;

            final priorityProducts =
                allProducts.where((p) => p.isPriority).length;

            final totalEstimatedCommission =
                allProducts.fold<double>(
              0,
              (sum, product) =>
                  sum + product.estimatedCommission,
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(isMobile),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSummaryCards(
                        totalProducts,
                        favoriteProducts,
                        priorityProducts,
                        totalEstimatedCommission,
                        isMobile,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSearchAndFilters(
                        isMobile,
                      ),
                    ),
                    if (filteredProducts.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(
                          allProducts.isEmpty,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          isMobile ? 16 : 28,
                          8,
                          isMobile ? 16 : 28,
                          120,
                        ),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product =
                                  filteredProducts[index];

                              return _AnimatedProductCard(
                                index: index,
                                child: _buildProductCard(
                                  product,
                                  isMobile,
                                ),
                              );
                            },
                            childCount: filteredProducts.length,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                isMobile ? 1 : 2,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                            childAspectRatio:
                                isMobile ? 1.55 : 1.45,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 18 : 30,
        24,
        isMobile ? 18 : 30,
        18,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF5FA2),
                  Color(0xFFFFA0C7),
                ],
              ),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5FA2).withValues(
                    alpha: .25,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Produk Affiliate',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF24242A),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Kelola produk affiliate kamu dengan mudah.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777780),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    int total,
    int favorite,
    int priority,
    double commission,
    bool isMobile,
  ) {
    final cards = [
      _SummaryData(
        title: 'Total Produk',
        value: total.toString(),
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFFFF5FA2),
      ),
      _SummaryData(
        title: 'Favorit',
        value: favorite.toString(),
        icon: Icons.favorite_rounded,
        color: const Color(0xFFFF6B8A),
      ),
      _SummaryData(
        title: 'Prioritas',
        value: priority.toString(),
        icon: Icons.star_rounded,
        color: const Color(0xFFFFA23D),
      ),
      _SummaryData(
        title: 'Est. Komisi',
        value: _formatRupiah(commission),
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF8D6BFF),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 28,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isMobile ? 1.45 : 1.8,
        ),
        itemBuilder: (context, index) {
          return _buildSummaryCard(cards[index]);
        },
      ),
    );
  }

  Widget _buildSummaryCard(_SummaryData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withValues(alpha: .035),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: 20,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: Colors.green,
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF28282E),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF888890),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isMobile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 28,
        22,
        isMobile ? 16 : 28,
        8,
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama produk atau platform...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFFFF5FA2),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(
                vertical: 17,
                horizontal: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.black.withValues(alpha: .035),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFFF8BB9),
                  width: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 43,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final selected =
                    _selectedFilter == filter;

                return ChoiceChip(
                  label: Text(filter),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  selectedColor:
                      const Color(0xFFFF5FA2),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(0xFF66666F),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFFFF5FA2)
                        : Colors.black.withValues(alpha: .05),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    AffiliateProduct product,
    bool isMobile,
  ) {
    final estimated = product.estimatedCommission;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),

        // ======================================================
        // CARD PRODUK SEKARANG MENUJU PRODUCT DETAIL
        // ======================================================
        onTap: () => _openProductDetail(product),

        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.black.withValues(alpha: .035),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .045),
                blurRadius: 20,
                offset: const Offset(0, 9),
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
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFE0EC),
                          Color(0xFFFFF5F9),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Color(0xFFFF5FA2),
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
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Color(0xFF28282E),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F6),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.platform,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF5FA2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Popup tidak ikut membuka detail.
                  PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showProductForm(
                          product: product,
                        );
                      } else if (value == 'delete') {
                        _deleteProduct(product);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_rounded,
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
                              Icons.delete_outline_rounded,
                              size: 19,
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

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _miniInfo(
                      'Harga',
                      _formatRupiah(product.price),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _miniInfo(
                      'Komisi',
                      _formatCommission(
                        product.commission,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7FC),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
                      color: Color(0xFF8D6BFF),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Est. komisi',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF777780),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatRupiah(estimated),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF8D6BFF),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Row(
                children: [
                  _actionButton(
                    icon: product.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    active: product.isFavorite,
                    onTap: () =>
                        _toggleFavorite(product),
                  ),
                  const SizedBox(width: 8),
                  _actionButton(
                    icon: product.isPriority
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    active: product.isPriority,
                    priority: true,
                    onTap: () =>
                        _togglePriority(product),
                  ),
                  const Spacer(),
                  if (product.affiliateLink.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFEFFAF3),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.link_rounded,
                            size: 14,
                            color: Colors.green,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Link aktif',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight:
                                  FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8A8A92),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF303037),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
    bool priority = false,
  }) {
    final color = priority
        ? const Color(0xFFFFA23D)
        : const Color(0xFFFF5FA2);

    return Material(
      color: active
          ? color.withValues(alpha: .12)
          : const Color(0xFFF7F7F9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 19,
            color: active
                ? color
                : const Color(0xFF898991),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDF5),
              borderRadius:
                  BorderRadius.circular(22),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF5FA2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Memuat produk...',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF55555D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius:
                    BorderRadius.circular(25),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                color: Colors.red.shade400,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Gagal memuat produk',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi Firebase atau aturan Firestore.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFFF5FA2),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noProducts) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFE5EF),
                    Color(0xFFFFF5F9),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 45,
                color: Color(0xFFFF5FA2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              noProducts
                  ? 'Belum Ada Produk'
                  : 'Produk Tidak Ditemukan',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF28282E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noProducts
                  ? 'Tambahkan produk affiliate pertama kamu untuk mulai mengelola produk.'
                  : 'Coba gunakan kata kunci atau filter yang berbeda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            if (noProducts) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showProductForm(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Produk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFFF5FA2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedProductCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedProductCard({
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedProductCard> createState() =>
      _AnimatedProductCardState();
}

class _AnimatedProductCardState
    extends State<_AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 450 + (widget.index * 70),
      ),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, .08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(
      Duration(milliseconds: widget.index * 50),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _SummaryData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}