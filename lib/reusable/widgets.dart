import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homemaster/reusable/square_tile.dart';

import '../authentication/auth.dart';
import '../screens/login_page.dart';
import '../screens/role_selectiom.dart';
import '../screens/signup_page.dart';

class DividerWithText extends StatelessWidget {
  final String text;

  const DividerWithText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(thickness: 1.2, color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(text, style: GoogleFonts.lato(color: Colors.grey.shade600, fontSize: 14)),
        ),
        Expanded(child: Divider(thickness: 1.2, color: Colors.grey.shade300)),
      ],
    );
  }
}

class AuthOptions extends StatelessWidget {
  final Auth auth;

  const AuthOptions({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SquareTile(
          onTap: () async {
            UserCredential? userCredential = await auth.signInWithGoogle();
            if (userCredential != null) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage()));
            }
          },
          imagePath: 'assets/google_logo.png',
        ),
      ],
    );
  }
}

class SignUpPrompt extends StatelessWidget {
  const SignUpPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Not a member?',
          style: GoogleFonts.lato(color: Colors.grey.shade700, fontSize: 14),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignUpPage()),
            );
          },
          child: Text(
            'Register now',
            style: GoogleFonts.lato(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class SignInPrompt extends StatelessWidget {
  const SignInPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already a member?',
          style: GoogleFonts.lato(color: Colors.grey.shade700, fontSize: 14),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          child: Text(
            'Login now',
            style: GoogleFonts.lato(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
