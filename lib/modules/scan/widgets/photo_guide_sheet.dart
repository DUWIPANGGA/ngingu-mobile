import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';

/// Panduan 3 langkah memfoto ikan yang bagus — kualitas foto menentukan
/// akurasi model. Ditampilkan sekali per sesi sebelum kamera dibuka.
class PhotoGuideSheet extends StatelessWidget {
  const PhotoGuideSheet({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Foto yang bagus = prediksi akurat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const _Tip(
              icon: Icons.wb_sunny_outlined,
              title: 'Cahaya cukup',
              desc: 'Foto di tempat terang, hindari bayangan dan flash langsung.',
            ),
            const SizedBox(height: 12),
            const _Tip(
              icon: Icons.center_focus_strong_outlined,
              title: 'Fokus ke gejala',
              desc: 'Dekatkan kamera ke luka, bintik, atau sirip yang bermasalah.',
            ),
            const SizedBox(height: 12),
            const _Tip(
              icon: Icons.water_drop_outlined,
              title: 'Ikan tetap basah',
              desc: 'Angkat ikan secukupnya, jepret cepat lalu kembalikan ke air.',
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Lanjut Ambil Foto',
              icon: Icons.photo_camera_outlined,
              onPressed: () {
                Get.back();
                onContinue();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.title, required this.desc});

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: const BoxDecoration(
            color: AppColors.softSky,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
