import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/affiliate_content.dart';

class ContentService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _contents {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User belum login.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('contents');
  }

  Stream<List<AffiliateContent>> getContents() {
    return _contents.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return AffiliateContent.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();

      list.sort((a, b) {
        final aDate =
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final bDate =
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return list;
    });
  }

  Future<void> addContent(
    AffiliateContent content,
  ) async {
    await _contents.add({
      ...content.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateContent(
    AffiliateContent content,
  ) async {
    await _contents.doc(content.id).update({
      ...content.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteContent(
    String contentId,
  ) async {
    await _contents.doc(contentId).delete();
  }
}