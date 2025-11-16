import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;

  bool _loading = false;
  bool get loading => _loading;

  // Constructor to initialize Google Sign-In
  AuthProvider() {
    _initializeGoogleSignIn();
  }

  // Initialization method
  Future<void> _initializeGoogleSignIn() async {
    try {
      // --- CHANGED 1: initialize() now takes NO parameters ---
      await GoogleSignIn.instance.initialize();
    } catch (e) {
      debugPrint("Google Sign-In Initialization Error: $e");
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  // ---------------------------
  // 	  GOOGLE SIGN-IN (Version 7+)
  // ---------------------------
  Future<String?> googleSignIn() async {
    try {
      _setLoading(true);

      // --- CHANGED 2: 'authenticate()' returns a 'GoogleSignInAccount' ---
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn.instance.authenticate();

      if (googleUser == null) {
        // User cancelled the sign-in
        return "Cancelled by user";
      }

      // --- CHANGED 3: Get 'authentication' from the 'googleUser' ---
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. Create the Firebase credential
      // (This part was correct)
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: null,
      );

      // 5. Sign in to Firebase
      await _auth.signInWithCredential(credential);

      return "success";
    } catch (e) {
      debugPrint("GoogleSignIn Error: $e");
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // -----------------------------------
  // EMAIL LOGIN
  // (No changes needed)
  // -----------------------------------
  Future<String?> login(String email, String password) async {
    try {
      _setLoading(true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _setLoading(false);
    }
  }

  // -----------------------------------
  // EMAIL SIGN-UP
  // (No changes needed)
  // -----------------------------------
  Future<String?> signup(String email, String password) async {
    try {
      _setLoading(true);
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _setLoading(false);
    }
  }

  // -----------------------------------
  // LOGOUT
  // (No changes needed)
  // -----------------------------------
  Future<void> logout() async {
    // Sign out from Google
    await GoogleSignIn.instance.signOut();

    // Sign out from Firebase
    await _auth.signOut();
    notifyListeners();
  }
}