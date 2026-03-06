import 'package:flutter/material.dart';
import 'package:premium_store/features/product/models/product_model.dart';

class CartItem {
  final ProductCardModel product;
  final int quantity;

  CartItem({
    required this.product, 
    required this.quantity
  });
}

class CartProvider extends ChangeNotifier {
  // We use a Map where the Key is the Product Title for quick lookups
  final Map<String, CartItem> _items = {};

  // Returns items as a list for the ListView.builder in CartScreen
  List<CartItem> get items => _items.values.toList();

  // Total number of unique products in the cart
  int get itemCount => _items.length;

  // Calculates the total price of all items in the cart
  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.product.price * cartItem.quantity;
    });
    return total;
  }

  // --- ADD TO CART ---
  void addToCart(ProductCardModel product, {int quantity = 1}) {
    if (_items.containsKey(product.title)) {
      // If it exists, update the quantity
      _items.update(
        product.title,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: existingItem.quantity + quantity,
        ),
      );
    } else {
      // If it's new, add it to the map
      _items.putIfAbsent(
        product.title,
        () => CartItem(product: product, quantity: quantity),
      );
    }
    notifyListeners(); // This updates the UI everywhere
  }

  // --- INCREMENT QUANTITY ---
  void incrementItem(String productTitle) {
    if (_items.containsKey(productTitle)) {
      _items.update(
        productTitle,
        (existing) => CartItem(
          product: existing.product, 
          quantity: existing.quantity + 1
        ),
      );
      notifyListeners();
    }
  }

  // --- DECREMENT QUANTITY ---
  void decrementItem(String productTitle) {
    if (!_items.containsKey(productTitle)) return;

    if (_items[productTitle]!.quantity > 1) {
      _items.update(
        productTitle,
        (existing) => CartItem(
          product: existing.product, 
          quantity: existing.quantity - 1
        ),
      );
    } else {
      // If quantity would become 0, remove it entirely
      _items.remove(productTitle);
    }
    notifyListeners();
  }

  // --- REMOVE SINGLE ITEM ---
  void removeItem(String productTitle) {
    _items.remove(productTitle);
    notifyListeners();
  }

  // --- CLEAR ENTIRE CART ---
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}