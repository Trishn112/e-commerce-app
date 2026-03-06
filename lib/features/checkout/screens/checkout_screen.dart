import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for Haptic Feedback
import 'package:provider/provider.dart';
import 'package:premium_store/core/constants/colors.dart';
import 'package:premium_store/features/cart/providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPaymentIndex = 0;

  void _handlePayment(CartProvider cart) {
    // 1. Show Loading Indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
      ),
    );

    // 2. Simulate Payment Processing
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      cart.clearCart(); // Empty the cart
      _showSuccessBottomSheet();
    });
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 90),
            const SizedBox(height: 20),
            const Text("Order Confirmed!", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "Your premium items have been reserved and will be shipped shortly.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("Continue Shopping", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Using watch to react to any last-minute price changes
    final cart = context.watch<CartProvider>();
    final total = cart.totalAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB), // Slightly cleaner white/grey
      appBar: AppBar(
        title: const Text("Checkout", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Shipping Address"),
            _buildInfoCard(
              icon: Icons.local_shipping_outlined,
              title: "Home Address",
              subtitle: "123 Future Tech Lane, Silicon Valley, CA",
              onTap: () {}, 
            ),
            const SizedBox(height: 30),
            
            _buildSectionHeader("Payment Method"),
            _buildPaymentOption(0, "Visa Card", "**** **** **** 4242", Icons.credit_card),
            _buildPaymentOption(1, "Apple Pay", "Default Wallet", Icons.apple),
            _buildPaymentOption(2, "Cash on Delivery", "Pay when items arrive", Icons.payments_outlined),
            const SizedBox(height: 30),
            
            _buildSectionHeader("Order Summary"),
            _buildOrderSummary(total),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(cart, total),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(int index, String title, String subtitle, IconData icon) {
    bool isSelected = _selectedPaymentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); // Add haptic feel
        setState(() => _selectedPaymentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if(isSelected) BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.black54),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]
              ),
            ),
            Radio(
              value: index,
              groupValue: _selectedPaymentIndex,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _selectedPaymentIndex = val as int),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _SummaryRow(label: "Subtotal", value: "\$${total.toStringAsFixed(2)}"),
          const _SummaryRow(label: "Shipping", value: "FREE", isGreen: true),
          const _SummaryRow(label: "Tax (Estimated)", value: "\$0.00"),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          _SummaryRow(label: "Order Total", value: "\$${total.toStringAsFixed(2)}", isBold: true),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CartProvider cart, double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: total > 0 ? () => _handlePayment(cart) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: Colors.grey.shade300,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 0,
          ),
          child: Text(
            total > 0 ? "Place Order • \$${total.toStringAsFixed(2)}" : "Empty Bag", 
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isGreen;
  final bool isBold;

  const _SummaryRow({
    required this.label, 
    required this.value, 
    this.isGreen = false, 
    this.isBold = false
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isBold ? 18 : 15, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? Colors.black : Colors.grey.shade600,
          )),
          Text(value, style: TextStyle(
            color: isGreen ? Colors.green : Colors.black, 
            fontWeight: FontWeight.bold, 
            fontSize: isBold ? 20 : 15
          )),
        ],
      ),
    );
  }
}