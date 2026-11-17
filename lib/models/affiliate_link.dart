import 'package:cloud_firestore/cloud_firestore.dart';

class AffiliateLink {
  String id;
  String name;
  String platform;
  String url;
  String productName;
  int clicks;
  bool isFavorite;
  DateTime? createdAt;

  AffiliateLink({
    required this.id,
    required this.name,
    required this.platform,
    required this.url,
    this.productName = '',
    this.clicks = 0,
    this.isFavorite = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'platform': platform,
      'url': url,
      'productName': productName,
      'clicks': clicks,
      'isFavorite': isFavorite,
    };
  }

  factory AffiliateLink.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final timestamp = map['createdAt'];

    return AffiliateLink(
      id: id,
      name: map['name']?.toString() ?? '',
      platform: map['platform']?.toString() ?? 'TikTok Shop',
      url: map['url']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      clicks: map['clicks'] is num
          ? (map['clicks'] as num).toInt()
          : 0,
      isFavorite: map['isFavorite'] == true,
      createdAt:
          timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}