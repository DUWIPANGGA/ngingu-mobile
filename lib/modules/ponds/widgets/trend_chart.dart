import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/models/pond_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_utils.dart';

/// Grafik tren gabungan: batang = jumlah scan, garis + titik = penyakit
/// terdeteksi per hari. Maksimal 14 titik terakhir.
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.trend});

  final List<HealthTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final points = trend.length > 14 ? trend.sublist(trend.length - 14) : trend;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            _LegendDot(color: AppColors.primary, label: 'Scan'),
            SizedBox(width: 12),
            _LegendDot(color: AppColors.danger, label: 'Penyakit'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 168,
          width: double.infinity,
          child: CustomPaint(painter: _TrendPainter(points)),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style:
                const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points);

  final List<HealthTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const leftPad = 4.0;
    const rightPad = 4.0;
    const topPad = 16.0;
    const bottomPad = 22.0;
    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;
    final peak = points
        .map((p) => math.max(p.scans, p.diseases.length))
        .fold<int>(1, math.max);

    double x(int i) => points.length == 1
        ? leftPad + chartW / 2
        : leftPad + chartW * i / (points.length - 1);
    double y(int v) => topPad + chartH - (v / peak) * chartH;

    final barPaint = Paint()..color = AppColors.primary.withValues(alpha: 0.85);
    final linePaint = Paint()
      ..color = AppColors.danger
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()..color = AppColors.danger;
    final dotHalo = Paint()
      ..color = AppColors.danger.withValues(alpha: 0.18);

    // Batang scan.
    final barW = math.min(20.0, chartW / math.max(points.length * 2, 1));
    for (var i = 0; i < points.length; i++) {
      final v = points[i].scans;
      final top = v == 0 ? topPad + chartH - 3 : y(v);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x(i) - barW / 2, top, barW,
              (topPad + chartH) - top),
          const Radius.circular(4),
        ),
        v == 0 ? (Paint()..color = AppColors.border) : barPaint,
      );
    }

    // Garis penyakit.
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final pt = Offset(x(i), y(points[i].diseases.length));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, linePaint);
    for (var i = 0; i < points.length; i++) {
      final pt = Offset(x(i), y(points[i].diseases.length));
      canvas.drawCircle(pt, 7, dotHalo);
      canvas.drawCircle(pt, 3.4, dotPaint);
    }

    // Label tanggal (maks ~5 label agar tidak berdesakan).
    final labelStyle = const TextStyle(
        fontSize: 10, color: AppColors.textLight);
    final step = (points.length / 5).ceil().clamp(1, points.length);
    for (var i = 0; i < points.length; i += step) {
      final tp = TextPainter(
        text: TextSpan(text: shortDate(points[i].date), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(x(i) - tp.width / 2, topPad + chartH + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points;
}
