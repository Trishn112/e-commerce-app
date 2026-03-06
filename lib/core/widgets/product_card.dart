import 'package:flutter/material.dart';
import 'package:premium_store/core/constants/colors.dart';
import 'package:premium_store/routes/app_routes.dart';

class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String brand;
  final String title;
  final double price;
  final double? oldPrice;
  final double rating;
  final int reviews;
  final String? badgeText;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.brand,
    required this.title,
    required this.price,
    this.oldPrice,
    required this.rating,
    required this.reviews,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // NAVIGATION LOGIC: Now passes the actual product data to the detail screen
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.productDetail,
          arguments: {
            'imageUrl': imageUrl,
            'brand': brand,
            'title': title,
            'price': price,
            'rating': rating,
            'reviews': reviews,
          },
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGE SECTION ---
            Stack(
              children: [
                Hero(
                  tag: imageUrl, // Hero animation tag
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      height: 220,
                      width: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 220,
                        width: 200,
                        color: AppColors.greyBg,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                // Badge (Discount or Status)
                if (badgeText != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeText!.contains('%') 
                            ? AppColors.primary 
                            : AppColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText!,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                // Wishlist Button
                const Positioned(
                  top: 12,
                  right: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 16,
                    child: Icon(Icons.favorite_border, size: 18, color: Colors.black),
                  ),
                ),
              ],
            ),
            
            // --- DETAILS SECTION ---
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand, 
                    style: const TextStyle(color: AppColors.textLight, fontSize: 12)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15, 
                      height: 1.2
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Rating Row
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      Text(
                        " $rating ", 
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)
                      ),
                      Text(
                        "($reviews)", 
                        style: const TextStyle(color: AppColors.textLight, fontSize: 12)
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price Row
                  Row(
                    children: [
                      Text(
                        "\$$price", 
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18, 
                          color: AppColors.primary
                        )
                      ),
                      if (oldPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          "\$$oldPrice", 
                          style: const TextStyle(
                            color: AppColors.textLight, 
                            decoration: TextDecoration.lineThrough, 
                            fontSize: 13
                          )
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}