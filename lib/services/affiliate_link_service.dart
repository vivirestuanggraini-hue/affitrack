import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/affiliate_link.dart';

class AffiliateLinkService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _links {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User belum login.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('affiliateLinks');
  }

  Stream<List<AffiliateLink>> getLinks() {
    return _links.snapshots().map((snapshot) {
      final links = snapshot.docs.map((doc) {
        return AffiliateLink.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();

      links.sort((a, b) {
        final aDate =
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final bDate =
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return links;
    });
  }

  Future<void> addLink(
    AffiliateLink link,
  ) async {
    await _links.add({
      ...link.toMap(),
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLink(
    AffiliateLink link,
  ) async {
    await _links.doc(link.id).update({
      ...link.toMap(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteLink(
    String linkId,
  ) async {
    await _links.doc(linkId).delete();
  }

  Future<void> toggleFavorite(
    String linkId,
    bool value,
  ) async {
    await _links.doc(linkId).update({
      'isFavorite': value,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementClicks(
    String linkId,
  ) async {
    await _links.doc(linkId).update({
      'clicks': FieldValue.increment(1),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }
}