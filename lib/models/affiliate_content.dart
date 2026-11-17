import 'package:cloud_firestore/cloud_firestore.dart';

class AffiliateContent {
  String id;
  String title;
  String platform;
  String description;
  String contentLink;
  String status;
  DateTime? createdAt;

  AffiliateContent({
    required this.id,
    required this.title,
    required this.platform,
    this.description = '',
    this.contentLink = '',
    this.status = 'Draft',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'platform': platform,
      'description': description,
      'contentLink': contentLink,
      'status': status,
    };
  }

  factory AffiliateContent.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final timestamp = map['createdAt'];

    return AffiliateContent(
      id: id,
      title: map['title']?.toString() ?? '',
      platform: map['platform']?.toString() ?? 'TikTok',
      description: map['description']?.toString() ?? '',
      contentLink: map['contentLink']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
      createdAt:
          timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}