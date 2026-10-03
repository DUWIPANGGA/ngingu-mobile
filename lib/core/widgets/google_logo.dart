import 'package:flutter/material.dart';

/// Logo "G" Google empat warna, digambar manual agar tidak perlu aset.
///
/// Dipakai di tombol "Lanjutkan/Daftar dengan Google".
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.19
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromLTWH(
      size.width * 0.11,
      size.height * 0.11,
      size.width * 0.78,
      size.height * 0.78,
    );

    // Merah: atas, kuning: kiri-bawah, hijau: bawah, biru: kanan.
    canvas.drawArc(rect, _rad(-140), _rad(105), false, stroke..color = _red);
    canvas.drawArc(rect, _rad(140), _rad(80), false, stroke..color = _yellow);
    canvas.drawArc(rect, _rad(70), _rad(70), false, stroke..color = _green);
    canvas.drawArc(rect, _rad(-35), _rad(105), false, stroke..color = _blue);

    // Bilah horizontal biru khas "G".
    final barH = size.height * 0.19;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.5,
        size.height * 0.5 - barH / 2,
        size.width * 0.42,
        barH,
      ),
      Paint()..color = _blue,
    );
  }

  double _rad(double deg) => deg * 3.141592653589793 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
