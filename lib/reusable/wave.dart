import 'package:flutter/material.dart';

class Wave extends StatelessWidget {
  const Wave({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WavePainter(),
      child: Container(),
    );
  }
}

// Custom painter to create wave shapes
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = const Color(0xFFEE4491).withOpacity(1.0);

    Path path = Path();
    path.moveTo(0, size.height * 0.1);
    path.quadraticBezierTo(
        size.width / 2, size.height * 0.3, size.width, size.height * 0.1);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    paint.color = const Color(0xFFFE6A6A).withOpacity(1);
    path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
        size.width / 2, size.height * 0.5, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    paint.color = const Color(0xFF1C59D2).withOpacity(1.0);
    path = Path();
    path.moveTo(0, size.height * 0.4);
    path.quadraticBezierTo(
        size.width / 2, size.height * 0.6, size.width, size.height * 0.4);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
