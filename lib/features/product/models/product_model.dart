class ProductCardModel {
  final String id; // Changed to required for database operations
  final String sellerId; // Added to fix the CartScreen error
  final String title;
  final String brand;
  final double price;
  final String imageUrl;
  final double rating;
  final int reviews;
  final String category;
  final List<String> variants;
  final String description;

  ProductCardModel({
    required this.id,
    required this.sellerId, // Added
    required this.title,
    this.brand = "Generic",
    required this.price,
    required this.imageUrl,
    this.rating = 0.0,
    this.reviews = 0,
    this.category = "General",
    this.variants = const [],
    this.description = "",
  });

  factory ProductCardModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ProductCardModel(
      id: docId ?? map['id'] ?? '', 
      sellerId: map['sellerId'] ?? '', // Added extraction from Firestore
      title: map['title'] ?? '',
      brand: map['brand'] ?? 'Generic',
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviews: (map['reviews'] ?? 0).toInt(),
      category: map['category'] ?? 'General',
      variants: List<String>.from(map['variants'] ?? []),
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId, // Added to map
      'title': title,
      'brand': brand,
      'price': price,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviews': reviews,
      'category': category,
      'variants': variants,
      'description': description,
    };
  }
}