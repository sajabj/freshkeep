import 'package:flutter/material.dart';

/// Original vector mark: a leaf nestling inside an open storage bowl.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MarkPainter(Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final fill = Paint()..color = color;
    canvas.drawPath(
      Path()
        ..moveTo(23, 27)
        ..cubicTo(9, 24, 12, 9, 34, 7)
        ..cubicTo(37, 20, 31, 27, 23, 27),
      fill,
    );
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(8, 28)
        ..quadraticBezierTo(11, 42, 24, 42)
        ..quadraticBezierTo(37, 42, 40, 28),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(22, 32)
        ..quadraticBezierTo(21, 25, 29, 16),
      stroke,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => color != oldDelegate.color;
}
