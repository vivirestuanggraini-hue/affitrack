import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/affiliate_commission.dart';
import '../models/affiliate_product.dart';

class CommissionService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _products {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User belum login.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('products');
  }

  Stream<List<AffiliateCommission>> getCommissions() {
    return _products.snapshots().map((snapshot) {
      final commissions = snapshot.docs.map((doc) {
        final product = AffiliateProduct.fromMap(
          doc.id,
          doc.data(),
        );

        return AffiliateCommission.fromProduct(
          product,
        );
      }).toList();

      commissions.sort((a, b) {
        return b.estimatedCommission.compareTo(
          a.estimatedCommission,
        );
      });

      return commissions;
    });
  }

  Stream<double> getTotalCommission() {
    return getCommissions().map((commissions) {
      return commissions.fold<double>(
        0,
        (total, item) =>
            total + item.estimatedCommission,
      );
    });
  }
}