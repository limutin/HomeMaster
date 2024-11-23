import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homemaster/reusable/wave.dart';
import 'package:homemaster/screens/role_selectiom.dart';
import '../reusable/my_button.dart';
import '../reusable/my_textfield.dart';
import '../authentication/auth.dart';
import 'change_password.dart';
import 'signup_page.dart';
import '../reusable/check.dart'; // Import the SuccessPopup widget
import 'package:awesome_dialog/awesome_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = Auth();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signUserIn() async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Sign in with email and password
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;

      // Check if the email is verified
      if (user != null && user.emailVerified) {
        Navigator.pop(context); // Close the loading dialog

        // Show success popup
        showDialog(
          context: context,
          builder: (context) {
            return const SuccessPopup(
              message: 'Successfuly Login!',
            );
          },
        );

        // Delay navigation to allow the user to see the success message
        await Future.delayed(const Duration(seconds: 2));

        // Navigate to the home page if verified
          Navigator.pushReplacement(
            context,
          MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
        );
      } else {
        Navigator.pop(context);
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.rightSlide,
          title: 'Email Not Verified',
          desc:
              'Please verify your email to proceed. We have sent you a new verification link.',
          btnOkText: 'Resend Verification Email',
          btnOkOnPress: () async {
            await user?.sendEmailVerification();
          },
          btnCancelText: 'OK',
          btnCancelOnPress: () {},
        ).show();
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      String errorMessage = '';
      DialogType dialogType = DialogType.error;

      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else {
        errorMessage = 'An unexpected error occurred. Please try again.';
      }

      AwesomeDialog(
        context: context,
        dialogType: dialogType,
        animType: AnimType.rightSlide,
        title: 'Sign-In Error',
        desc: errorMessage,
        btnOkText: 'OK',
        btnOkOnPress: () {},
      ).show();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      UserCredential? userCredential = await _auth.signInWithGoogle();
      if (userCredential != null) {
        // Show success popup
    showDialog(
      context: context,
      builder: (context) {
            return const SuccessPopup(
              message: 'Successfuly Login!',
            );
      },
    );

        // Delay navigation to allow the user to see the success message
        await Future.delayed(const Duration(seconds: 2));

        // Navigate to the home page
          Navigator.pushReplacement(
            context,
          MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
        );
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'Sign-In Error',
          desc: 'Failed to sign in with Google. Please try again.',
          btnOkText: 'OK',
          btnOkOnPress: () {},
        ).show();
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading dialog
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Sign-In Error',
        desc: 'An error occurred: $e',
        btnOkText: 'OK',
        btnOkOnPress: () {},
      ).show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
        const SizedBox(height: 30,),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1C59D2),
                  Color(0xFFFE6A6A),
                  Color(0xFFFEC260),
                ],
                stops: [0.1, 0.5, 0.9],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5.0,
                  ),
                  
                  child: Column(
                  
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 5),
                    
                      Image.asset(
                        'assets/icon/icon.png',  // Make sure this path matches your icon location
                        height: 150,  // Adjust size as needed
                        width: 150,
                      ),
                      const SizedBox(height: 20),  // Space between icon and text
                    
                      Text(
                        'HomeMaster',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      MyTextField(
                        controller: emailController,
                        hintText: 'Username',
                        obscureText: false,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      const SizedBox(height: 15),
                      MyTextField(
                        controller: passwordController,
                        hintText: 'Password',
                        obscureText: true,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChangePasswordPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      MyButton(
                        onTap: signUserIn,
                        gradientColors: const [
                          Colors.orange,
                          Color.fromRGBO(238, 68, 145, 1),
                        ],
                        color: Colors.white,
                        child: Text(
                          'Login',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 1.2,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              'Or continue with',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 1.2,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: ElevatedButton(
                          onPressed: signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/google.png',
                                height: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Continue with Google',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Not a member?',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 5),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const SignUpPage(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeInOut;
                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));
                                    var offsetAnimation =
                                        animation.drive(tween);
                                    return SlideTransition(
                                        position: offsetAnimation,
                                        child: child);
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                ),
                              );
                            },
                            child: Text(
                              'Register now',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
