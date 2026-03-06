import 'package:flutter/material.dart';
import 'package:premium_store/presentation/main_wrapper.dart';
import 'package:premium_store/presentation/home/home_screen.dart';
import 'package:premium_store/features/cart/screens/cart_screen.dart';
import 'package:premium_store/features/checkout/screens/checkout_screen.dart';
import 'package:premium_store/presentation/profile/profile_screen.dart';
import 'package:premium_store/features/chatbot/screens/chatbot_screen.dart';
import 'package:premium_store/features/product/screens/product_detail_screen.dart';
import 'package:premium_store/features/auth/screens/login_screen.dart';
import 'package:premium_store/features/auth/screens/signup_screen.dart';
import 'package:premium_store/features/auth/screens/auth_wrapper.dart';
import 'package:premium_store/features/seller/screens/seller_dashboard.dart';
import 'package:premium_store/features/seller/screens/add_product_screen.dart';
import 'dart:developer' as dev; // Added for logging

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String profile = '/profile';
  static const String productDetail = '/product-detail';
  static const String chatbot = '/chatbot';
  
  // --- SELLER ROUTES ---
  static const String sellerDashboard = '/seller-dashboard';
  static const String addProduct = '/add-product';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Object? args = settings.arguments;

    switch (settings.name) {
      case initial:
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());

      case checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case productDetail:
        // FIX: Enhanced extraction logic
        if (args is Map<String, dynamic>) {
          dev.log("ROUTER: Passing product with ID: ${args['id']}");
          return MaterialPageRoute(
            settings: settings, // Important for nested navigation tracking
            builder: (_) => ProductDetailScreen(productData: args), 
          );
        }
        return _errorRoute("Product details were not passed correctly. Expected a Map, but got: ${args.runtimeType}");

      case chatbot:
        return MaterialPageRoute(builder: (_) => const ChatbotScreen());

      case sellerDashboard:
        return MaterialPageRoute(builder: (_) => const SellerDashboard());

      case addProduct:
        return MaterialPageRoute(builder: (_) => const AddProductScreen());

      default:
        return _errorRoute("No route defined for ${settings.name}");
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text("Navigation Error"), 
          centerTitle: true,
          backgroundColor: Colors.redAccent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  message, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}