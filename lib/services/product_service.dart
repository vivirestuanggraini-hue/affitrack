import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/affiliate_product.dart';

class ProductService {
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

  Stream<List<AffiliateProduct>> getProducts() {
    return _products.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AffiliateProduct.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }

  Future<void> addProduct(
    AffiliateProduct product,
  ) async {
    await _products.add({
      ...product.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProduct(
    AffiliateProduct product,
  ) async {
    await _products.doc(product.id).update({
      ...product.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(
    String productId,
  ) async {
    await _products.doc(productId).delete();
  }

  Future<void> toggleFavorite(
    String productId,
    bool value,
  ) async {
    await _products.doc(productId).update({
      'isFavorite': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> togglePriority(
    String productId,
    bool value,
  ) async {
    await _products.doc(productId).update({
      'isPriority': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}