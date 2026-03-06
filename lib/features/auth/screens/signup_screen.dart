import 'package:flutter/material.dart';
import 'package:premium_store/core/constants/colors.dart';
import 'package:premium_store/core/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _selectedRole = 'customer'; 

  void _handleSignup() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    // FIXED: Now passing all 5 required parameters
    final user = await _authService.signUp(
      email: email, 
      password: password, 
      role: _selectedRole,
      name: name,
      phoneNumber: phone,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (user != null) {
        _showSuccessDialog();
      } else {
        _showError("Signup failed. Please check your details.");
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Verify Email"),
        content: const Text("A verification link has been sent to your email. Please verify and then login."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to login
            }, 
            child: const Text("OK")
          )
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Create Account", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Join us to start your premium journey", style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 30),

                _buildLabel("Register as"),
                _buildRoleSelection(),

                const SizedBox(height: 20),
                _buildLabel("Full Name"),
                TextField(controller: _nameController, decoration: _inputStyle("John Doe", Icons.person_outline)),

                const SizedBox(height: 20),
                _buildLabel("Phone Number"),
                TextField(
                  controller: _phoneController, 
                  keyboardType: TextInputType.phone,
                  decoration: _inputStyle("+1 234 567 890", Icons.phone_outlined)
                ),

                const SizedBox(height: 20),
                _buildLabel("Email Address"),
                TextField(controller: _emailController, decoration: _inputStyle("name@example.com", Icons.email_outlined)),

                const SizedBox(height: 20),
                _buildLabel("Password"),
                TextField(controller: _passwordController, obscureText: true, decoration: _inputStyle("At least 6 characters", Icons.lock_outline)),

                const SizedBox(height: 20),
                _buildLabel("Confirm Password"),
                TextField(controller: _confirmPasswordController, obscureText: true, decoration: _inputStyle("Repeat your password", Icons.lock_reset)),

                const SizedBox(height: 30),
                
                // SIGN UP BUTTON
                _buildSignUpButton(),

                const SizedBox(height: 20),
                const Center(child: Text("OR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                const SizedBox(height: 20),

                // SOCIAL LOGINS
                _buildSocialLogins(),

                const SizedBox(height: 24),
                _buildLoginRedirect(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI BUILDER METHODS ---

  Widget _buildRoleSelection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: RadioListTile<String>(title: const Text("Customer"), value: 'customer', groupValue: _selectedRole, activeColor: AppColors.primary, onChanged: (val) => setState(() => _selectedRole = val!))),
          Expanded(child: RadioListTile<String>(title: const Text("Seller"), value: 'seller', groupValue: _selectedRole, activeColor: AppColors.primary, onChanged: (val) => setState(() => _selectedRole = val!))),
        ],
      ),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Text("Sign Up", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSocialLogins() {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () => _authService.signInWithGoogle(_selectedRole),
          icon: const Icon(Icons.g_mobiledata, size: 30),
          label: const Text("Continue with Google"),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _authService.signInWithApple(_selectedRole),
          icon: const Icon(Icons.apple, color: Colors.white),
          label: const Text("Continue with Apple", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ],
    );
  }

  Widget _buildLoginRedirect() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text("Login", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)));

  InputDecoration _inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
    );
  }
}