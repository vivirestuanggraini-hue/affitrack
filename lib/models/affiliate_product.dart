class AffiliateProduct {
  String id;
  String name;
  String platform;
  double price;
  double commission;
  String affiliateLink;
  String imageUrl;
  bool isFavorite;
  bool isPriority;

  AffiliateProduct({
    required this.id,
    required this.name,
    required this.platform,
    required this.price,
    required this.commission,
    required this.affiliateLink,
    this.imageUrl = '',
    this.isFavorite = false,
    this.isPriority = false,
  });

  double get estimatedCommission {
    return price * commission / 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'platform': platform,
      'price': price,
      'commission': commission,
      'affiliateLink': affiliateLink,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
      'isPriority': isPriority,
    };
  }

  factory AffiliateProduct.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return AffiliateProduct(
      id: id,
      name: map['name']?.toString() ?? '',
      platform: map['platform']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      commission: (map['commission'] as num?)?.toDouble() ?? 0,
      affiliateLink: map['affiliateLink']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      isFavorite: map['isFavorite'] == true,
      isPriority: map['isPriority'] == true,
    );
  }
}