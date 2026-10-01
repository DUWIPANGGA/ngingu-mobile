import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_feedback.dart';
import '../controllers/scan_processing_controller.dart';

/// Layar proses async (API.md §4.1 → §4.3): long-poll sampai `done`/`failed`.
class ScanProcessingView extends GetView<ScanProcessingController> {
  const ScanProcessingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Memproses Scan')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isFailed.value) return _failedState();
          return _processingState();
        }),
      ),
    );
  }

  Widget _processingState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PulsingScanIcon(),
            const SizedBox(height: 8),
            const Text(
              'Scan sedang diproses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              controller.currentMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Biasanya kurang dari 10 detik',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textLight),
            ),
            const SizedBox(height: 26),
            const SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                minHeight: 6,
                borderRadius: BorderRadius.all(Radius.circular(999)),
                color: AppColors.primary,
                backgroundColor: AppColors.border,
              ),
            ),
            if (controller.errorMessage.value.isNotEmpty &&
                controller.canManualCheck.value) ...[
              const SizedBox(height: 20),
              AppBanner(
                message: controller.errorMessage.value,
                icon: Icons.cloud_off_outlined,
              ),
            ],
            if (controller.canManualCheck.value) ...[
              const SizedBox(height: 20),
              SecondaryButton(
                label: 'Periksa lagi',
                icon: Icons.refresh_rounded,
                expand: false,
                onPressed: controller.manualCheck,
              ),
            ],
            const SizedBox(height: 30),
            DangerButton(
              label: 'Batalkan Scan',
              onPressed: controller.confirmCancel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _failedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration:
                  const BoxDecoration(color: AppColors.softRed, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded,
                  size: 34, color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan gagal diproses',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.errorMessage.value.isEmpty
                  ? 'Prediksi gagal diproses. Coba lagi nanti.'
                  : controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Lihat Detail',
              icon: Icons.visibility_outlined,
              onPressed: controller.viewDetail,
            ),
            const SizedBox(height: 10),
            SecondaryButton(label: 'Kembali', onPressed: Get.back),
          ],
        ),
      ),
    );
  }
}
