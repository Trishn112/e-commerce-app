import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:premium_store/features/product/models/product_model.dart';

class AdminService {
  final CollectionReference _products = 
      FirebaseFirestore.instance.collection('products');

  // Function to add a product to Firestore
  Future<void> addProduct(ProductCardModel product) async {
    try {
      await _products.add(product.toMap());
    } catch (e) {
      throw Exception("Failed to add product: $e");
    }
  }
}