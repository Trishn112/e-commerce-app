import 'package:flutter/material.dart';
import 'package:premium_store/core/constants/colors.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.token, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text("ShopFuture", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Your premium destination for quality products. We bring you the future of online shopping with AI-powered recommendations.",
                      style: TextStyle(color: AppColors.textLight, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Expanded(child: _FooterLinks(title: "Shop", links: ["All Products", "Deals", "New Arrivals"])),
            ],
          ),
          const SizedBox(height: 40),
          const Text("Subscribe to our newsletter", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("Get updates on new products and exclusive offers.", style: TextStyle(color: AppColors.textLight)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    filled: true,
                    fillColor: AppColors.greyBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Subscribe", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Center(child: Text("© 2026 ShopFuture. All rights reserved.", style: TextStyle(color: AppColors.textLight, fontSize: 12))),
        ],
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  final String title;
  final List<String> links;
  const _FooterLinks({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(link, style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
        )),
      ],
    );
  }
}