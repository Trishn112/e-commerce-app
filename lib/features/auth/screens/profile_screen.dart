import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:premium_store/core/constants/colors.dart';
import 'package:premium_store/core/services/auth_service.dart';
import 'package:premium_store/routes/app_routes.dart'; // Import your routes

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the current user
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("My Profile", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            onPressed: () => _handleLogout(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildProfileImage(),
                  const SizedBox(height: 16),
                  const Text("Trish", 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(user?.email ?? "Guest User", 
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 25),
                  _buildQuickStats(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- MENU SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Account Settings", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 12),
                  _buildMenuContainer([
                    _buildProfileTile(Icons.shopping_bag_outlined, "My Orders", "Track your packages"),
                    _buildProfileTile(Icons.favorite_border, "Wishlist", "Items you saved"),
                    _buildProfileTile(Icons.payment, "Payment Methods", "Visa **4242"),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  const Text("General", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 12),
                  _buildMenuContainer([
                    _buildProfileTile(Icons.notifications_none_outlined, "Notifications", "Alerts & updates"),
                    _buildProfileTile(Icons.security_outlined, "Security", "Password & privacy"),
                    
                    // --- UPDATED LOGOUT TILE ---
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      onTap: () => _handleLogout(context),
                    ),
                  ]),
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UPDATED LOGOUT LOGIC ---
  void _handleLogout(BuildContext context) async {
    debugPrint("!!! LOGOUT ATTEMPTED !!!");
    
    // 1. Call the service to sign out from Firebase
    await AuthService().logout();
    
    if (context.mounted) {
      // 2. IMPORTANT: We use pushNamedAndRemoveUntil to the initial route ('/')
      // We use rootNavigator: true to ensure we exit the BottomNavigationBar (MainWrapper)
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRoutes.initial, // This is '/'
        (route) => false,  // This clears all previous screens
      );
    }
  }

  // --- UI HELPERS ---
  Widget _buildProfileImage() {
    return const CircleAvatar(
      radius: 50,
      backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=trish'),
    );
  }

  Widget _buildQuickStats() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(children: [Text("12", style: TextStyle(fontWeight: FontWeight.bold)), Text("Orders")]),
        Column(children: [Text("250", style: TextStyle(fontWeight: FontWeight.bold)), Text("Points")]),
      ],
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () => debugPrint("Tapped $title"),
    );
  }
}