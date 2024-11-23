import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final BorderRadius borderRadius;
  final String? Function(String?)? validator; // Validator function

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.borderRadius =
        const BorderRadius.all(Radius.circular(15)), // Default border radius
    this.validator, // Optional validator parameter
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.lato(
          fontSize: 16,
          color: Colors.black, // Use black for text for better contrast
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.lato(
            color: Colors.grey.shade500, // Hint text color
          ),
          filled: true,
          fillColor: Colors.white, // White background for text field
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide:
                const BorderSide(color: Color(0xFFEE4491)), // Lazada bright blue
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
                color: Colors.orange.shade700,
                width: 1.5), // Lazada bright orange
          ),
        ),
        validator: validator ??
            (value) {
              if (value == null || value.length < 8) {
                return 'Password must be at least 8 characters long';
              }
              return null;
            }, // Applying the validator if provided
      ),
    );
  }
}
