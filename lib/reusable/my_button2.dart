import 'package:flutter/material.dart';

class MyButton2 extends StatelessWidget {
  final Function()? onTap;
  final String label; // Add label parameter

  const MyButton2(
      {super.key,
      required this.onTap,
      required this.label, required Color textColor, required Color color}); // Add label to constructor

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(vertical: 18),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.teal, // Use your main color for button
          borderRadius: BorderRadius.circular(20), // Adjust border radius
        ),
        child: Center(
          child: Text(
            label, // Use the label parameter
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
