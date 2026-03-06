import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:premium_store/presentation/main_wrapper.dart';
import 'package:premium_store/features/auth/screens/login_screen.dart';
import 'package:premium_store/features/seller/screens/seller_dashboard.dart';
import 'package:premium_store/core/constants/colors.dart'; // Ensure you have this for styling
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final User? user = authSnapshot.data;

        // 1. No User -> Login
        if (user == null) {
          return const LoginScreen();
        }

        // 2. CHECK EMAIL VERIFICATION
        // Note: For social logins (Google/Apple), email is usually auto-verified.
        // For Email/Password, the user MUST click the link in their inbox.
        if (!user.emailVerified) {
          return _VerificationWaitScreen(user: user);
        }

        // 3. User is verified -> Check Firestore Role
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const LoginScreen();
            }

            try {
              final Map<String, dynamic> userData = 
                  userSnapshot.data!.data() as Map<String, dynamic>;
              
              final String role = userData['role'] ?? 'customer';
              
              if (role == 'seller') {
                return const SellerDashboard();
              } else {
                return const MainWrapper();
              }
            } catch (e) {
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}

// --- NEW WIDGET: VERIFICATION WAIT SCREEN ---
class _VerificationWaitScreen extends StatelessWidget {
  final User user;
  const _VerificationWaitScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              "Verify your email",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              "We've sent a verification link to ${user.email}. Please check your inbox and click the link to continue.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                // Manually trigger a refresh to check if they've clicked the link
                await FirebaseAuth.instance.currentUser?.reload();
              },
              child: const Text("I've Verified"),
            ),
            TextButton(
              onPressed: () => user.sendEmailVerification(),
              child: const Text("Resend Verification Email"),
            ),
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text("Back to Login", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}