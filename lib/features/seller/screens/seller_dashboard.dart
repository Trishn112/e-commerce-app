import 'dart:async'; // Required for StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:premium_store/core/constants/colors.dart';
import 'add_product_screen.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? "";

  late Stream<QuerySnapshot> _productStream;
  // Use a Subscription to manage the background listener safely
  StreamSubscription<QuerySnapshot>? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void dispose() {
    // CRITICAL: Cancel the listener to prevent background crashes
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _initStreams() {
    if (uid.isEmpty) return;

    // 1. Live Product Stream
    _productStream = FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: uid)
        .snapshots();

    // 2. Active Order Listener with Error Handling
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
      (snapshot) {
        // We iterate through changes to find only NEWLY added orders
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;
            _showNewOrderNotification(data);
          }
        }
      },
      onError: (error) {
        // This catches missing indexes or permission errors
        debugPrint("Order Listener Error: $error");
      },
    );
  }

  void _showNewOrderNotification(Map<String, dynamic> orderData) {
    if (!mounted) return;
    
    // Fallback values to prevent crashes if data is missing
    final String amount = orderData['totalAmount']?.toString() ?? "0.00";
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.yellow),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "New Order Received! Value: \$$amount",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Seller Hub",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: uid.isEmpty
          ? const Center(child: Text("User Session Lost. Please Login."))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildStatsHeader(),
                  const SizedBox(height: 25),
                  const Text(
                    "Live Inventory",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _buildSellerProductList()),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddProductScreen()),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Product", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return StreamBuilder<QuerySnapshot>(
      stream: _productStream,
      builder: (context, snapshot) {
        int productCount = 0;
        double totalValue = 0.0;

        if (snapshot.hasData) {
          productCount = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final price = double.tryParse(data['price']?.toString() ?? "0") ?? 0.0;
            final stock = int.tryParse(data['stock']?.toString() ?? "0") ?? 0;
            totalValue += (price * stock);
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem("Stock Value", "\$${totalValue.toStringAsFixed(0)}"),
              _statItem("Items", productCount.toString()),
              _statItem("Status", "Active"),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  Widget _buildSellerProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _productStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        return ListView.separated(
          itemCount: docs.length,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildProductCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildProductCard(String docId, Map<String, dynamic> data) {
    final String imageUrl = data['imageUrl'] ?? "";
    final double price = double.tryParse(data['price']?.toString() ?? "0") ?? 0.0;
    final int stock = int.tryParse(data['stock']?.toString() ?? "0") ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60, height: 60, color: Colors.grey[50],
              child: imageUrl.isNotEmpty 
                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                : const Icon(Icons.image),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? "Untitled", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text("\$${price.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _buildStockBadge(stock),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                onPressed: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => AddProductScreen(productId: docId, productData: data))
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _showDeleteDialog(context, docId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(int stock) {
    Color color = Colors.green;
    String text = "Stock: $stock";
    if (stock == 0) { color = Colors.red; text = "Sold Out"; }
    else if (stock < 5) { color = Colors.orange; text = "Low: $stock"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text("No products listed.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Cancel subscription before logging out to prevent errors
    await _orderSubscription?.cancel();
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _showDeleteDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Item?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('products').doc(docId).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}