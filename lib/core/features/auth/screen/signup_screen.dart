import 'package:flutter/material.dart';
import 'package:notes/core/features/auth/screen/home_screen.dart';
// import 'package:provider/provider.dart'; // No longer used, can be removed
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../provider/auth_provider.dart'; // No longer used, can be removed
import 'package:fluttertoast/fluttertoast.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  bool _isLoading = false;
  bool _agree = false; // Button will be disabled if this is false

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    mobile.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  void showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF333333),
      textColor: Colors.white,
      fontSize: 16,
    );
  }

  // --- FIX 1: Robust error handling ---
  Future<void> _createAccount() async {
    // Note: The terms check is now handled by the button's disabled state,
    // but keeping this here is good redundant validation.
    if (!_agree) {
      showToast("Please agree to the terms.");
      return;
    }

    if (password.text != confirmPassword.text) {
      showToast("Passwords do not match!");
      return;
    }

    // Safety check for async operations
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCred.user!.uid)
          .set({
        "firstName": firstName.text.trim(),
        "lastName": lastName.text.trim(),
        "mobileNumber": mobile.text.trim(),
        "email": email.text.trim(),
      });

      // Safety check before navigation
      if (!mounted) return;

      showToast("Account created successfully!");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseException catch (e) {
      // This will catch errors from both Auth and Firestore
      showToast(e.message ?? "An error occurred");
    } catch (e) {
      // Catch any other unexpected errors
      showToast("An unexpected error occurred: $e");
    } finally {
      // Safety check before setting state
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFF46D3A);
    const Color backgroundColor = Color(0xFFFFF6F0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              /// Header
              const Text(
                "Create Account",
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Let's get you started!",
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),

              /// Fields
              _field("First Name", firstName),
              _gap(),
              _field("Last Name", lastName),
              _gap(),
              _field("Mobile Number", mobile, keyboardType: TextInputType.phone),
              _gap(),
              _field("Email", email, keyboardType: TextInputType.emailAddress),
              _gap(),
              _field("Password", password, obscure: true),
              _gap(),
              _field("Confirm Password", confirmPassword, obscure: true),
              _gap(4),

              /// Terms
              Row(
                children: [
                  Checkbox(
                    value: _agree,
                    activeColor: primaryColor,
                    // This setState will trigger the build method,
                    // re-evaluating the button's onPressed logic
                    onChanged: (v) => setState(() => _agree = v ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      "I agree to the terms and conditions",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              _gap(10),

              /// Sign Up Button
              // --- FIX 2: Full-width button ---
              SizedBox(
                width: double.infinity, // This makes the button take full width
                child: ElevatedButton(
                  // --- FIX 3: Disable if loading or terms not agreed ---
                  onPressed: (_isLoading || !_agree) ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    // This handles the disabled look automatically
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              _gap(10),

              /// Already have account?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Sign in",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Beautiful text field builder
  Widget _field(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    const Color primaryColor = Color(0xFFF46D3A);
    const Color textFieldColor = Color(0xFFFDF0E7);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: textFieldColor,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _gap([double h = 14]) => SizedBox(height: h);
}