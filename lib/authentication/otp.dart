import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homemaster/screens/login_page.dart';
import 'package:homemaster/reusable/check.dart';
import 'package:lottie/lottie.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String password;

  const OtpVerificationPage({super.key, required this.email, required this.password});

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
  }

  // Send verification email without creating the account
  Future<void> _sendVerificationEmail() async {
    try {
      // Create a temporary user to send verification email
      UserCredential tempUser = await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );
      
      _user = tempUser.user;
      
      // Send verification email
      await _user?.sendEmailVerification();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending verification email: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void checkEmailVerified() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Sign out first to ensure clean state
      await _auth.signOut();
      
      // Sign in to get fresh user instance
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );
      
      // Update our user reference
      _user = userCredential.user;
      
      // Reload user data
      await _user?.reload();
      
      // Get fresh user instance
      User? freshUser = _auth.currentUser;
      
      if (freshUser?.emailVerified ?? false) {
        // Show success popup
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const SuccessPopup(
              message: 'Email Verified Successfully! Account Created.',
            ),
          );
        }

        // Delay navigation to show the success popup
        await Future.delayed(const Duration(seconds: 2));

        // Sign out so user can log in properly
        await _auth.signOut();

        // Navigate to login page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        // Add a retry mechanism
        int retryCount = 0;
        while (retryCount < 3 && !(freshUser?.emailVerified ?? false)) {
          await Future.delayed(const Duration(seconds: 2));
          await freshUser?.reload();
          freshUser = _auth.currentUser;
          retryCount++;
        }

        if (freshUser?.emailVerified ?? false) {
          // Show success popup
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const SuccessPopup(
                message: 'Email Verified Successfully! Account Created.',
              ),
            );
          }

          // Delay navigation to show the success popup
          await Future.delayed(const Duration(seconds: 2));

          // Sign out so user can log in properly
          await _auth.signOut();

          // Navigate to login page
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Email not verified yet! Please check your email and try again.",
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error verifying email: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void resendVerificationEmail() async {
    try {
      // Send verification email to the existing user
      await _user?.sendEmailVerification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification email resent!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF1C59D2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error resending verification email: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Clean up: delete the user if not verified
    if (_user != null && !_user!.emailVerified) {
      _user?.delete();
      _auth.signOut();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C59D2),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Email verification animation
                Lottie.asset(
                  'assets/email_verification.json',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 32),
                Text(
                  'Verify Your Email',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'We\'ve sent a verification link to:',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isLoading ? null : checkEmailVerified,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1C59D2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        )
                      : Text(
                          'Verify Email',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: resendVerificationEmail,
                  child: Text(
                    'Resend Verification Email',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
