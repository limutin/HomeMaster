import 'package:flutter/material.dart';

class SquareTile extends StatelessWidget {
  final String imagePath;
  final Function()? onTap;
  final double size;

  const SquareTile({
    super.key,
    required this.imagePath,
    required this.onTap,
    this.size = 50, // Default size for flexibility
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, 
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100, // Light background color
          borderRadius:
              BorderRadius.circular(20), // Softer corners for a modern look
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5), // Subtle shadow for a floating effect
            ),
          ],
        ),
        child: Image.asset(
          imagePath,
          height: size,
          width: size,
          fit: BoxFit.contain, // Ensures the image scales nicely
        ),
      ),
    );
  }
}
