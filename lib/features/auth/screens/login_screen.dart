import 'package:flutter/material.dart';
import 'package:premium_store/core/constants/colors.dart';
import 'package:premium_store/core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final AuthService _authService = AuthService(); 
  bool _isLoading = false; 

  void _login() async {
    debugPrint("--- Login Process Started ---");
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      debugPrint("Error: Fields are empty");
      _showErrorSnackBar("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint("Attempting login for: $email");
      final user = await _authService.login(email, password);

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (user == null) {
          debugPrint("Login Failed: AuthService returned null");
          _showErrorSnackBar("Login Failed. Please check your credentials.");
        } else {
          debugPrint("Login Success! User UID: ${user.uid}");
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login Successful! Redirecting..."),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 500),
            ),
          );

          // Give the snackbar a tiny moment to register then force navigation
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              debugPrint("Navigating to root (AuthWrapper)...");
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
          });
        }
      }
    } catch (e) {
      debugPrint("CRITICAL ERROR DURING LOGIN: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                
                // Logo Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.token, color: AppColors.primary, size: 50),
                ),
                
                const SizedBox(height: 32),
                
                const Text(
                  "Welcome Back", 
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sign in to continue your premium shopping", 
                  style: TextStyle(color: Colors.grey, fontSize: 16)
                ),
                
                const SizedBox(height: 48),
                
                _buildInputLabel("Email Address"),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration("Enter your email", Icons.email_outlined),
                ),
                
                const SizedBox(height: 24),
                
                _buildInputLabel("Password"),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration("Enter your password", Icons.lock_outline),
                ),
                
                const SizedBox(height: 12),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {}, 
                    child: const Text("Forgot Password?", style: TextStyle(color: AppColors.primary)),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text(
                          "Sign Up", 
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }
}