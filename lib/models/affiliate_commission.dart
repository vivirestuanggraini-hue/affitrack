import '../models/affiliate_product.dart';

class AffiliateCommission {
  final String productId;
  final String productName;
  final String platform;
  final double price;
  final double commissionPercent;
  final double estimatedCommission;
  final bool isPriority;

  AffiliateCommission({
    required this.productId,
    required this.productName,
    required this.platform,
    required this.price,
    required this.commissionPercent,
    required this.estimatedCommission,
    required this.isPriority,
  });

  factory AffiliateCommission.fromProduct(
    AffiliateProduct product,
  ) {
    return AffiliateCommission(
      productId: product.id,
      productName: product.name,
      platform: product.platform,
      price: product.price,
      commissionPercent: product.commission,
      estimatedCommission: product.estimatedCommission,
      isPriority: product.isPriority,
    );
  }
}