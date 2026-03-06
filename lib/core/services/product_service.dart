import 'package:premium_store/features/product/models/product_model.dart';

class ProductService {
  static List<ProductCardModel> allProducts = [
    ProductCardModel(
      title: "Premium Wireless Headphones",
      brand: "AudioPro",
      price: 299.99,
      imageUrl: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e",
      rating: 4.8,
      reviews: 2341,
    ),
    ProductCardModel(
      title: "Minimalist Leather Backpack",
      brand: "UrbanStyle",
      price: 179.99,
      imageUrl: "https://images.unsplash.com/photo-1586769852836-bc069f19e1b6",
      rating: 4.7,
      reviews: 543,
    ),
    ProductCardModel(
      title: "Smart Watch Series 5",
      brand: "TechWear",
      price: 349.00,
      imageUrl: "https://images.unsplash.com/photo-1523275335684-37898b6baf30",
      rating: 4.9,
      reviews: 1200,
    ),
    ProductCardModel(
      title: "Mechanical Keyboard",
      brand: "KeyClick",
      price: 120.50,
      imageUrl: "https://images.unsplash.com/photo-1511467687858-23d96c32e4ae",
      rating: 4.6,
      reviews: 890,
    ),
  ];
}