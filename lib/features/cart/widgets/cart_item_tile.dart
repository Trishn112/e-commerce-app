import 'package:flutter/material.dart';
import 'package:premium_store/core/constants/colors.dart';

class CartItemTile extends StatelessWidget {
  final String title;
  final String imageUrl;
  final double price;
  final String variant;

  const CartItemTile({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl, height: 100, width: 100, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Size: $variant", style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
                const SizedBox(height: 8),
                Text("\$$price", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
              ],
            ),
          ),
          // Quantity Selector
          Container(
            decoration: BoxDecoration(
              color: AppColors.greyBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.remove, size: 18)),
                const Text("1", style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.add, size: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}