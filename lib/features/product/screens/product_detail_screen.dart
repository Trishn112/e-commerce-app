import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:premium_store/core/constants/colors.dart';
import 'package:premium_store/features/cart/providers/cart_provider.dart';
import 'package:premium_store/features/product/models/product_model.dart';
import 'package:intl/intl.dart'; // Ensure you have intl in pubspec.yaml
import 'dart:developer' as dev;

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailScreen({super.key, required this.productData});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  String? selectedVariant;

  // --- HELPERS TO EXTRACT DATA SAFELY ---
  
  List<String> _getVariants(Map<String, dynamic> d) {
    var list = d['variants'] ?? d['Variants'] ?? d['sizes'] ?? d['options'];
    if (list == null || list is! List) return [];
    return list.map((e) => e.toString()).toList();
  }

  String _getDescription(Map<String, dynamic> d) {
    return d['description'] ?? d['Description'] ?? d['details'] ?? d['Details'] ?? "No description available.";
  }

  // --- NEW: TRACKING TIMELINE COMPONENT ---
  Widget _buildTrackingSection(String productId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: user.uid)
          .where('productId', isEqualTo: productId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        var orderData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        List<dynamic> history = orderData['trackingHistory'] ?? [];

        return Container(
          margin: const EdgeInsets.only(top: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text("Order Tracking", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              ...history.reversed.map((step) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step['status'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(step['timestamp'])),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // --- PAYMENT SELECTION STEP ---
  void _showPaymentSelection(String productId, String sellerId, String title, double price) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select Payment Method", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.money, color: AppColors.primary),
                title: const Text("Cash on Delivery"),
                onTap: () {
                  Navigator.pop(context);
                  _handleBuyNow(productId, sellerId, title, price, "Cash on Delivery");
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                title: const Text("Online Payment (Wallet)"),
                onTap: () {
                  Navigator.pop(context);
                  _handleBuyNow(productId, sellerId, title, price, "Online Payment");
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // --- DATABASE TRANSACTION: BUY NOW ---
  Future<void> _handleBuyNow(String productId, String sellerId, String title, double price, String method) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to purchase")));
      return;
    }

    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary))
    );

    try {
      final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
      final buyerRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final double totalAmount = price * quantity;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot productSnap = await transaction.get(productRef);
        DocumentSnapshot buyerSnap = await transaction.get(buyerRef);
        
        if (!productSnap.exists) throw "Product no longer exists.";
        
        final buyerData = buyerSnap.exists ? buyerSnap.data() as Map<String, dynamic> : {};
        double currentBalance = double.tryParse(buyerData['balance']?.toString() ?? "0.0") ?? 0.0;
        String buyerName = buyerData['name'] ?? "Premium User";
        
        int currentStock = int.tryParse(productSnap['stock']?.toString() ?? "0") ?? 0;
        if (currentStock < quantity) throw "Insufficient stock.";

        if (method == "Online Payment") {
          if (currentBalance < totalAmount) throw "Insufficient wallet balance.";
          transaction.update(buyerRef, {'balance': currentBalance - totalAmount});
        }

        transaction.update(productRef, {'stock': currentStock - quantity});

        transaction.set(orderRef, {
          'sellerId': sellerId,
          'buyerId': user.uid,
          'buyerName': buyerName, 
          'buyerEmail': user.email ?? "",
          'productId': productId,
          'productTitle': title,
          'totalAmount': totalAmount,
          'quantity': quantity,
          'paymentMethod': method,
          'status': 'Order Placed', 
          'trackingHistory': [
            {'status': 'Order Placed', 'timestamp': DateTime.now().toIso8601String()},
          ],
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        Navigator.pop(context); 
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text("Order Placed Successfully!\nYou can track your order below.", textAlign: TextAlign.center),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String productId = widget.productData['id']?.toString() ?? 
                             widget.productData['productId']?.toString() ?? "";

    if (productId.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Product not found.")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('products').doc(productId).snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> data = Map<String, dynamic>.from(widget.productData);

        if (snapshot.hasData && snapshot.data!.exists) {
          final liveData = snapshot.data!.data() as Map<String, dynamic>;
          data.addAll(liveData);
          data['id'] = productId;
        }

        final String title = data['title']?.toString() ?? "Premium Product";
        final String brand = data['brand']?.toString() ?? "Premium Brand";
        final String imageUrl = data['imageUrl']?.toString() ?? data['image']?.toString() ?? "";
        final double price = double.tryParse(data['price'].toString()) ?? 0.0;
        final double rating = double.tryParse(data['rating']?.toString() ?? "0") ?? 0.0;
        final int reviews = int.tryParse(data['reviews']?.toString() ?? "0") ?? 0;
        final int stock = int.tryParse(data['stock']?.toString() ?? "0") ?? 0;
        
        final List<String> variants = _getVariants(data);
        final String description = _getDescription(data);

        if (selectedVariant == null && variants.isNotEmpty) {
          selectedVariant = variants[0];
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(imageUrl),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(brand, rating, reviews),
                      const SizedBox(height: 12),
                      Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("\$${price.toStringAsFixed(2)}", 
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text("Stock: $stock", style: TextStyle(color: stock > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      
                      // TRACKING SECTION INTEGRATED HERE
                      _buildTrackingSection(productId),

                      if (variants.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text("Select Variant", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        _buildVariantList(variants),
                      ],

                      const SizedBox(height: 32),
                      const Text("About Product", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      Text(description, style: TextStyle(color: Colors.black.withOpacity(0.6), height: 1.6, fontSize: 15)),
                      const SizedBox(height: 140), 
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: _buildBottomPanel(context, data, title, brand, imageUrl, price, rating, reviews, stock),
        );
      },
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildAppBar(String url) {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: url.isNotEmpty 
          ? Image.network(url, fit: BoxFit.contain)
          : const Icon(Icons.image, size: 50),
      ),
    );
  }

  Widget _buildHeader(String brand, double rating, int reviews) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(brand.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        Row(children: [
          const Icon(Icons.star, color: Colors.orange, size: 16),
          Text(" $rating ($reviews reviews)", style: const TextStyle(fontSize: 13)),
        ]),
      ],
    );
  }

  Widget _buildVariantList(List<String> variants) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: variants.length,
        itemBuilder: (context, i) {
          bool isSelected = selectedVariant == variants[i];
          return GestureDetector(
            onTap: () => setState(() => selectedVariant = variants[i]),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
              ),
              child: Center(
                child: Text(variants[i], 
                  style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, Map<String, dynamic> data, String title, String brand, String img, double price, double rat, int rev, int currentStock) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(color: AppColors.greyBg, borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.remove, size: 20), onPressed: () => setState(() => quantity > 1 ? quantity-- : null)),
                Text("$quantity", style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add, size: 20), onPressed: () => setState(() => quantity++)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              final product = ProductCardModel(
                id: data['id']?.toString() ?? "",
                sellerId: data['sellerId']?.toString() ?? "",
                title: title,
                brand: brand,
                price: price,
                imageUrl: img,
                rating: rat,
                reviews: rev,
                category: data['category']?.toString() ?? 'General',
                description: _getDescription(data),
                variants: _getVariants(data),
              );
              context.read<CartProvider>().addToCart(product, quantity: quantity);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Added to cart"), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.primary),
              );
            },
            icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
          ),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: currentStock < quantity 
                  ? null 
                  : () => _showPaymentSelection(data['id']?.toString() ?? "", data['sellerId'] ?? "", title, price),
                child: Text(currentStock < quantity ? "Out of Stock" : "Buy Now", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}