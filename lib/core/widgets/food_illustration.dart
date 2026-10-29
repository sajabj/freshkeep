import 'package:flutter/material.dart';

/// Original, local vector illustration. Decorative, never inventory data.
class FoodIllustration extends StatelessWidget {
  const FoodIllustration({super.key, this.scene = 0});
  final int scene;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AspectRatio(
      aspectRatio: 1.35,
      child: CustomPaint(
        painter: _FoodPainter(
          scene,
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    ),
  );
}

class _FoodPainter extends CustomPainter {
  _FoodPainter(this.scene, this.green, this.backdrop);
  final int scene;
  final Color green, backdrop;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 320, size.height / 240);
    final p = Paint()..color = backdrop;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(15, 16, 290, 215),
        const Radius.circular(90),
      ),
      p,
    );
    p.color = green;
    if (scene == 1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(94, 44, 132, 159),
          const Radius.circular(18),
        ),
        p,
      );
      p.color = const Color(0xFFF9FAF4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(108, 78, 104, 108),
          const Radius.circular(10),
        ),
        p,
      );
      p.color = const Color(0xFF216448);
      for (final x in [122.0, 148.0, 174.0]) {
        canvas.drawCircle(Offset(x, 105), 5, p);
        canvas.drawCircle(Offset(x, 129), 5, p);
      }
      p.style = PaintingStyle.stroke;
      p.strokeWidth = 5;
      p.strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(137, 159)
          ..lineTo(150, 169)
          ..lineTo(180, 145),
        p,
      );
    } else if (scene == 2) {
      canvas.drawPath(
        Path()
          ..moveTo(100, 170)
          ..lineTo(112, 105)
          ..quadraticBezierTo(114, 54, 160, 54)
          ..quadraticBezierTo(206, 54, 208, 105)
          ..lineTo(220, 170)
          ..close(),
        p,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(92, 168, 136, 13),
          const Radius.circular(8),
        ),
        p,
      );
      canvas.drawCircle(const Offset(160, 195), 12, p);
      p.style = PaintingStyle.stroke;
      p.strokeWidth = 5;
      p.strokeCap = StrokeCap.round;
      canvas.drawArc(const Rect.fromLTWH(80, 34, 160, 160), -1, 0.65, false, p);
    } else {
      // Produce above a shallow bowl: carrot, tomato and leafy greens.
      p.color = const Color(0xFFDB914F);
      canvas.drawPath(
        Path()
          ..moveTo(196, 67)
          ..quadraticBezierTo(236, 62, 233, 90)
          ..lineTo(188, 168)
          ..quadraticBezierTo(175, 178, 178, 161)
          ..close(),
        p,
      );
      p.color = green;
      canvas.drawPath(
        Path()
          ..moveTo(215, 70)
          ..quadraticBezierTo(202, 25, 227, 27)
          ..quadraticBezierTo(241, 39, 215, 70)
          ..quadraticBezierTo(263, 26, 260, 54)
          ..quadraticBezierTo(253, 74, 215, 70),
        p,
      );
      p.color = const Color(0xFF8FAE71);
      canvas.drawOval(const Rect.fromLTWH(86, 48, 55, 110), p);
      canvas.drawOval(const Rect.fromLTWH(119, 65, 52, 100), p);
      p.color = const Color(0xFFCE6C4D);
      canvas.drawCircle(const Offset(115, 142), 34, p);
      p.color = green;
      canvas.drawPath(
        Path()
          ..moveTo(107, 109)
          ..lineTo(115, 119)
          ..lineTo(128, 109)
          ..lineTo(119, 107)
          ..lineTo(119, 99)
          ..lineTo(113, 106)
          ..close(),
        p,
      );
      p.color = const Color(0xFFE9D8B5);
      canvas.drawPath(
        Path()
          ..moveTo(62, 153)
          ..lineTo(258, 153)
          ..quadraticBezierTo(245, 213, 160, 213)
          ..quadraticBezierTo(75, 213, 62, 153),
        p,
      );
      p.color = const Color(0xFFC9B591);
      p.style = PaintingStyle.stroke;
      p.strokeWidth = 4;
      canvas.drawLine(const Offset(76, 167), const Offset(244, 167), p);
      if (scene == 3) {
        p.color = green;
        p.strokeWidth = 7;
        p.strokeCap = StrokeCap.round;
        canvas.drawPath(
          Path()
            ..moveTo(247, 111)
            ..lineTo(259, 123)
            ..lineTo(282, 94),
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FoodPainter old) =>
      old.scene != scene || old.green != green || old.backdrop != backdrop;
}
