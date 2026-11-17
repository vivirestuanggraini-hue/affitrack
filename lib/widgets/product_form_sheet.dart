import 'package:flutter/material.dart';

import '../models/affiliate_product.dart';
import '../services/product_service.dart';

class ProductFormSheet extends StatefulWidget {
  final AffiliateProduct? product;

  const ProductFormSheet({
    super.key,
    this.product,
  });

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final ProductService _productService = ProductService();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _commissionController;
  late final TextEditingController _affiliateLinkController;
  late final TextEditingController _imageUrlController;

  String _platform = 'TikTok Shop';
  bool _isFavorite = false;
  bool _isPriority = false;
  bool _isSaving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _nameController = TextEditingController(
      text: product?.name ?? '',
    );

    _priceController = TextEditingController(
      text: product != null
          ? product.price.toStringAsFixed(0)
          : '',
    );

    _commissionController = TextEditingController(
      text: product != null
          ? product.commission.toString()
          : '',
    );

    _affiliateLinkController = TextEditingController(
      text: product?.affiliateLink ?? '',
    );

    _imageUrlController = TextEditingController(
      text: product?.imageUrl ?? '',
    );

    _platform = product?.platform ?? 'TikTok Shop';
    _isFavorite = product?.isFavorite ?? false;
    _isPriority = product?.isPriority ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _commissionController.dispose();
    _affiliateLinkController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFFE88EAD),
      ),
      filled: true,
      fillColor: const Color(0xFFFFF8FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFF4D8E2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE88EAD),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEF4),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFE88EAD),
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3A2730),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF8D737D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final product = AffiliateProduct(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        platform: _platform,
        price: double.parse(
          _priceController.text.trim(),
        ),
        commission: double.parse(
          _commissionController.text.trim(),
        ),
        affiliateLink: _affiliateLinkController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        isFavorite: _isFavorite,
        isPriority: _isPriority,
      );

      if (_isEdit) {
        await _productService.updateProduct(product);
      } else {
        await _productService.addProduct(product);
      }

      if (!mounted) return;

      Navigator.pop(
        context,
        product,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan produk: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(
          top: 35,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            22,
            12,
            22,
            24 + bottomInset,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8D6DD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEdit
                                ? 'Edit Produk'
                                : 'Tambah Produk',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF33232B),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _isEdit
                                ? 'Perbarui informasi produk affiliate kamu.'
                                : 'Tambahkan produk affiliate baru ke AffiTrack.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF927A84),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD9E6),
                            Color(0xFFF4A9C3),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                _sectionTitle(
                  'Informasi Produk',
                  'Masukkan informasi utama produk.',
                  Icons.shopping_bag_outlined,
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _nameController,
                  textInputAction:
                      TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'Nama Produk',
                    icon: Icons.shopping_bag_outlined,
                    hint: 'Contoh: Tas Wanita Premium',
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Nama produk wajib diisi';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  initialValue: _platform,
                  decoration: _inputDecoration(
                    label: 'Platform',
                    icon: Icons.storefront_outlined,
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
                      setState(() {
                        _platform = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType:
                            TextInputType.number,
                        decoration: _inputDecoration(
                          label: 'Harga',
                          icon: Icons.payments_outlined,
                          hint: '150000',
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Wajib diisi';
                          }

                          final price =
                              double.tryParse(
                            value.trim(),
                          );

                          if (price == null ||
                              price < 0) {
                            return 'Harga tidak valid';
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller:
                            _commissionController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration(
                          label: 'Komisi (%)',
                          icon:
                              Icons.percent_outlined,
                          hint: '10',
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Wajib diisi';
                          }

                          final commission =
                              double.tryParse(
                            value.trim(),
                          );

                          if (commission == null ||
                              commission < 0 ||
                              commission > 100) {
                            return '0 - 100%';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                _sectionTitle(
                  'Link Affiliate',
                  'Tambahkan link yang akan digunakan untuk promosi.',
                  Icons.link_outlined,
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller:
                      _affiliateLinkController,
                  keyboardType:
                      TextInputType.url,
                  decoration: _inputDecoration(
                    label: 'Link Affiliate',
                    icon: Icons.link,
                    hint: 'https://...',
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Link affiliate wajib diisi';
                    }

                    final uri =
                        Uri.tryParse(value.trim());

                    if (uri == null ||
                        !(uri.scheme == 'http' ||
                            uri.scheme == 'https')) {
                      return 'Masukkan link yang valid';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _imageUrlController,
                  keyboardType:
                      TextInputType.url,
                  decoration: _inputDecoration(
                    label: 'URL Gambar Produk',
                    icon:
                        Icons.image_outlined,
                    hint: 'https://...',
                  ),
                ),

                const SizedBox(height: 28),

                _sectionTitle(
                  'Pengaturan Produk',
                  'Atur produk favorit dan prioritas.',
                  Icons.tune_outlined,
                ),

                const SizedBox(height: 14),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8FB),
                    borderRadius:
                        BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFF4D8E2),
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _isFavorite,
                        onChanged: (value) {
                          setState(() {
                            _isFavorite = value;
                          });
                        },
                        activeThumbColor:
                            const Color(0xFFE88EAD),
                        title: const Text(
                          'Produk Favorit',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF45323A),
                          ),
                        ),
                        subtitle: const Text(
                          'Tandai sebagai produk favorit.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF927A84),
                          ),
                        ),
                        secondary: const Icon(
                          Icons.favorite_outline,
                          color: Color(0xFFE88EAD),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        indent: 18,
                        endIndent: 18,
                      ),
                      SwitchListTile(
                        value: _isPriority,
                        onChanged: (value) {
                          setState(() {
                            _isPriority = value;
                          });
                        },
                        activeThumbColor:
                            const Color(0xFFE88EAD),
                        title: const Text(
                          'Produk Prioritas',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF45323A),
                          ),
                        ),
                        subtitle: const Text(
                          'Tampilkan sebagai produk penting.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF927A84),
                          ),
                        ),
                        secondary: const Icon(
                          Icons.star_outline,
                          color: Color(0xFFE88EAD),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        _isSaving ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFE88EAD),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFFECC5D2),
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(17),
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
                                    ? Icons.save_outlined
                                    : Icons
                                        .add_circle_outline,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                _isEdit
                                    ? 'Simpan Perubahan'
                                    : 'Tambah Produk',
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

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: Color(0xFF927A84),
                        fontWeight: FontWeight.w700,
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
}