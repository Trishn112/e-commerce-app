import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Your App Imports
import 'package:premium_store/routes/app_routes.dart';
import 'package:premium_store/core/constants/colors.dart';
import 'package:premium_store/features/cart/providers/cart_provider.dart';

void main() async {
  // 1. Ensures all Flutter widgets are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase with the auto-generated configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        // Manages cart items and totals across the customer app
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const ShopFutureApp(),
    ),
  );
}

class ShopFutureApp extends StatelessWidget {
  const ShopFutureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopFuture',
      debugShowCheckedModeBanner: false,
      
      // Global App Theme
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        
        // Applying Google Fonts to the entire app
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.black, size: 22),
          titleTextStyle: TextStyle(
            color: Colors.black, 
            fontSize: 18, 
            fontWeight: FontWeight.bold
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),

      // Entry point logic: 
      // AppRoutes.initial is '/', which directs to AuthWrapper via onGenerateRoute
      initialRoute: AppRoutes.initial, 
      onGenerateRoute: AppRoutes.onGenerateRoute, 

      // This ensures that the app handles text scaling and system themes correctly
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}