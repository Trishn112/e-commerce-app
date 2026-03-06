import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get userStatus => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // --- 1. EMAIL/PASSWORD SIGN UP ---
  Future<User?> signUp({
    required String email,
    required String password,
    required String role,
    required String phoneNumber,
    required String name,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Triggers the verification email
        await user.sendEmailVerification();

        // Save extra data to Firestore
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'phoneNumber': phoneNumber,
          'role': role,
          'profilePic': '', // Initialized empty for future updates
          'balance': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Sign Up Error: ${e.message}");
      return null;
    }
  }

  // --- 2. PHONE VERIFICATION (SMS OTP) ---
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? "Verification failed");
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // --- 3. GOOGLE LOGIN ---
  Future<UserCredential?> signInWithGoogle(String role) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      await _syncSocialUser(result.user, role);
      return result;
    } catch (e) {
      debugPrint("Google Login Error: $e");
      return null;
    }
  }

  // --- 4. APPLE LOGIN (WEB-COMPILER SAFE) ---
  Future<UserCredential?> signInWithApple(String role) async {
    try {
      final appleIdCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [], 
      );

      final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
      final AuthCredential credential = oAuthProvider.credential(
        idToken: appleIdCredential.identityToken,
        accessToken: appleIdCredential.authorizationCode,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      await _syncSocialUser(result.user, role);
      return result;
    } catch (e) {
      debugPrint("Apple Login Error: $e");
      return null;
    }
  }

  // --- 5. PRIVATE HELPER: SYNC SOCIAL USER ---
  Future<void> _syncSocialUser(User? user, String role) async {
    if (user != null) {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      
      // If user doesn't exist, create profile with profilePic field
      if (!userDoc.exists) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? "Premium User",
          'profilePic': user.photoURL ?? '', // Use Google/Apple photo if available
          'role': role,
          'balance': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // --- 6. UPDATE PROFILE SETTINGS ---
  // Call this method from your Settings screen to update name or photo
  Future<bool> updateProfile({String? newName, String? newPhotoUrl}) async {
    try {
      String uid = _auth.currentUser!.uid;
      Map<String, dynamic> data = {};
      
      if (newName != null) data['name'] = newName;
      if (newPhotoUrl != null) data['profilePic'] = newPhotoUrl;

      if (data.isNotEmpty) {
        await _db.collection('users').doc(uid).update(data);
      }
      return true;
    } catch (e) {
      debugPrint("Update Profile Error: $e");
      return false;
    }
  }

  // --- HELPERS ---
  Future<User?> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<void> logout() async => await _auth.signOut();
}