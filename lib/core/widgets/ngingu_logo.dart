import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Hand-drawn Ngingu badge logo (fish + bubbles in a sky circle).
class NginguLogo extends StatelessWidget {
  const NginguLogo({super.key, this.size = 120, this.animate = true});

  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    Widget logo = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _NginguLogoPainter()),
    );
    if (!animate) return logo;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(scale: 0.6 + 0.4 * value, child: child),
      child: logo,
    );
  }
}

class _NginguLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    // Sky circle.
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.primaryDark],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, bg);

    // Water wave at the bottom.
    final wave = Paint()..color = Colors.white.withValues(alpha: 0.18);
    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(size.width * 0.25, size.height * 0.62, size.width * 0.45, size.height * 0.84,
          size.width * 0.7, size.height * 0.74)
      ..cubicTo(size.width * 0.85, size.height * 0.68, size.width * 0.95, size.height * 0.74,
          size.width, size.height * 0.78)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, wave);

    // Fish body.
    final body = Paint()..color = Colors.white;
    final bodyRect = Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.46),
        width: size.width * 0.5,
        height: size.height * 0.3);
    canvas.drawOval(bodyRect, body);

    // Tail.
    final tail = Path()
      ..moveTo(bodyRect.left + 2, bodyRect.center.dy)
      ..lineTo(bodyRect.left - size.width * 0.14, bodyRect.top - size.height * 0.02)
      ..lineTo(bodyRect.left - size.width * 0.14, bodyRect.bottom + size.height * 0.02)
      ..close();
    canvas.drawPath(tail, body);

    // Dorsal fin.
    final fin = Path()
      ..moveTo(size.width * 0.46, bodyRect.top + 2)
      ..lineTo(size.width * 0.52, bodyRect.top - size.height * 0.08)
      ..lineTo(size.width * 0.58, bodyRect.top + 2)
      ..close();
    canvas.drawPath(
        fin, Paint()..color = AppColors.primaryDark.withValues(alpha: 0.85));

    // Eye.
    final eyePaint = Paint()..color = AppColors.primaryDark;
    canvas.drawCircle(
        Offset(size.width * 0.66, size.height * 0.43), size.width * 0.035, eyePaint);

    // Bubbles.
    final bubble = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018;
    canvas.drawCircle(Offset(size.width * 0.74, size.height * 0.3), size.width * 0.05, bubble);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.22), size.width * 0.03, bubble);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.18), size.width * 0.022, bubble);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
