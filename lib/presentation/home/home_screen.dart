import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:premium_store/core/constants/colors.dart';
import 'package:premium_store/core/widgets/product_card.dart';
import 'package:premium_store/features/home/widgets/category_card.dart';
import 'package:premium_store/routes/app_routes.dart';
import 'package:premium_store/features/cart/providers/cart_provider.dart';
import 'dart:developer' as dev;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = "All";
  final List<String> categories = ["All", "Electronics", "Fashion", "Gadgets", "Home"];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: _buildLogo(),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border, color: Colors.black), onPressed: () {}),
          _buildCartIcon(),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.chatbot),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFreeShippingBanner(),
              _buildSearchBar(),
              _buildHorizontalCategories(),
              _buildSectionHeader("Top Categories"),
              _buildCategoryGrid(),
              _buildSectionHeader(selectedCategory == "All" 
                  ? "Featured Products" 
                  : "$selectedCategory Collection"),
              _buildFirebaseProductList(),
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirebaseProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error loading products"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        String searchKeyword = _searchController.text.toLowerCase();

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String title = (data['title'] ?? "").toString().toLowerCase();
          String brand = (data['brand'] ?? "").toString().toLowerCase();
          String category = (data['category'] ?? "").toString();

          bool matchesSearch = title.contains(searchKeyword) || brand.contains(searchKeyword);
          bool matchesCategory = selectedCategory == "All" || category == selectedCategory;
          
          return matchesSearch && matchesCategory;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const SizedBox(
            height: 200, 
            child: Center(child: Text("No items found")),
          );
        }

        return SizedBox(
          height: 350, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              // 1. CREATE MUTABLE MAP AND INJECT ID
              final Map<String, dynamic> data = Map<String, dynamic>.from(doc.data() as Map);
              data['id'] = doc.id; 

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    dev.log("HOME: Navigating to ${data['title']} (ID: ${data['id']})");
                    Navigator.pushNamed(
                      context, 
                      AppRoutes.productDetail, 
                      arguments: data,
                    );
                  },
                  // 2. ABSORB POINTER ensures the card itself doesn't eat the tap
                  child: AbsorbPointer(
                    child: ProductCard(
                      imageUrl: data['imageUrl'] ?? "",
                      brand: data['brand'] ?? "",
                      title: data['title'] ?? "",
                      price: double.tryParse(data['price'].toString()) ?? 0.0,
                      rating: double.tryParse(data['rating']?.toString() ?? "0") ?? 0.0,
                      reviews: int.tryParse(data['reviews']?.toString() ?? "0") ?? 0,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.token, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          "ShopFuture",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ],
    );
  }

  Widget _buildHorizontalCategories() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          bool isSelected = selectedCategory == categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected) setState(() => selectedCategory = categories[index]);
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: AppColors.greyBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFreeShippingBanner() {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(color: AppColors.primary),
      child: const Text(
        "Free shipping on orders above \$50", 
        textAlign: TextAlign.center, 
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() {}),
        decoration: InputDecoration(
          hintText: "Search brands or products...", 
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true, 
          fillColor: AppColors.greyBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15), 
            borderSide: BorderSide.none
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: CategoryCard(
              title: "Electronics",
              itemCount: "Latest Tech",
              imageUrl: "https://images.unsplash.com/photo-1498050108023-c5249f4df085",
              onTap: () => setState(() => selectedCategory = "Electronics"),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CategoryCard(
              title: "Fashion",
              itemCount: "Urban Style",
              imageUrl: "https://images.unsplash.com/photo-1445205170230-053b83016050",
              onTap: () => setState(() => selectedCategory = "Fashion"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartIcon() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) => Badge(
        label: Text('${cart.items.length}'),
        isLabelVisible: cart.items.isNotEmpty,
        backgroundColor: AppColors.primary,
        child: IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (selectedCategory != "All")
            GestureDetector(
              onTap: () => setState(() => selectedCategory = "All"),
              child: const Text("See All", style: TextStyle(color: AppColors.primary, fontSize: 14)),
            ),
        ],
      ),
    );
  }
}