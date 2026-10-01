import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';

/// Skor kesehatan 0–100 → warna ambang (FR-04.2.2: hijau/kuning/oranye/merah).
Color healthScoreColor(int? score) {
  final s = score ?? 0;
  if (s >= 75) return AppColors.secondary;
  if (s >= 50) return AppColors.severitySedang;
  if (s >= 25) return AppColors.orange;
  return AppColors.danger;
}

/// Skor → label kondisi tambak.
String healthScoreLabel(int? score) {
  final s = score ?? 0;
  if (s >= 75) return 'Sehat';
  if (s >= 50) return 'Baik';
  if (s >= 25) return 'Waspada';
  return 'Kritis';
}

/// Ribuan gaya Indonesia: `12000` → `12.000`.
String idNumber(num value) {
  final isWhole = value == value.truncateToDouble();
  final raw = isWhole ? value.toInt().toString() : value.toStringAsFixed(2);
  final negative = raw.startsWith('-');
  final body = negative ? raw.substring(1) : raw;
  final parts = body.split('.');
  final head = parts.first;
  final buf = StringBuffer();
  for (var i = 0; i < head.length; i++) {
    if (i > 0 && (head.length - i) % 3 == 0) buf.write('.');
    buf.write(head[i]);
  }
  final rest = parts.length > 1 ? '.${parts.sublist(1).join('.')}' : '';
  return '${negative ? '-' : ''}$buf$rest';
}

/// Kartu putih radius 16 + shadow lembut (SRS §7 playful-professional).
BoxDecoration pondCardDecoration() => BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

/// Konfirmasi aksi destruktif (hapus tambak).
Future<bool> confirmPondDestructive({
  required String title,
  required String message,
  String confirmLabel = 'Hapus',
}) async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      title:
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: Text(message, style: const TextStyle(fontSize: 14, height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Batal',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: Text(
            confirmLabel,
            style: const TextStyle(
                color: AppColors.danger, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
    barrierDismissible: true,
  );
  return result ?? false;
}

/// Chip ikon kecil (luas, kapasitas, jumlah scan, dkk).
class PondInfoChip extends StatelessWidget {
  const PondInfoChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softSky,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gauge/radial skor kesehatan (FR-04.2.2).
class HealthScoreRing extends StatelessWidget {
  const HealthScoreRing({super.key, required this.score, this.size = 64});

  final int? score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final double value = ((score ?? 0).clamp(0, 100)).toDouble() / 100;
    final color = healthScoreColor(score);
    final big = size >= 90;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => CircularProgressIndicator(
                value: v,
                strokeWidth: big ? 9 : 6.5,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score ?? 0}',
                style: TextStyle(
                  fontSize: big ? 27 : 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              if (big) ...[
                const SizedBox(height: 3),
                const Text(
                  'skor',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
