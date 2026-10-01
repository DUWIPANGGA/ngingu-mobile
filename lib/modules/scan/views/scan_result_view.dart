import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/scan_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_feedback.dart';
import '../controllers/scan_result_controller.dart';

/// Hasil prediksi (API.md §4.3): foto + GradCAM, confidence, daftar prediksi,
/// info kolam/waktu, export PDF, hapus, dan scan ulang.
class ScanResultView extends GetView<ScanResultController> {
  const ScanResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Hasil Scan'),
        actions: [
          Obx(() {
            final d = controller.detail.value;
            if (d == null || !d.isDone) return const SizedBox.shrink();
            if (controller.isExporting.value) {
              return const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return IconButton(
              tooltip: 'Export PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: controller.exportPdf,
            );
          }),
          Obx(() {
            final d = controller.detail.value;
            if (d == null) return const SizedBox.shrink();
            if (controller.isDeleting.value) {
              return const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return IconButton(
              tooltip: 'Hapus scan',
              icon: const Icon(Icons.delete_outline),
              onPressed: controller.deleteScan,
            );
          }),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(child: Obx(() => _body())),
    );
  }

  Widget _body() {
    if (controller.isLoading.value) {
      return const LoadingState(message: 'Memuat hasil scan…');
    }
    final d = controller.detail.value;
    if (d == null) {
      if (controller.errorMessage.value.isNotEmpty) {
        return ErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.load,
        );
      }
      return const LoadingState(message: 'Memuat hasil scan…');
    }
    if (d.isProcessing) return _processingBody();
    if (d.isFailed) return _failedBody(d);
    return _resultBody(d);
  }

  // ── state ────────────────────────────────────────────────────────────────

  Widget _processingBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingState(message: 'Hasil masih diproses…'),
            if (controller.canRetryPoll.value) ...[
              const SizedBox(height: 20),
              AppBanner(
                message: 'Pemrosesan memakan waktu lebih lama dari biasanya.',
                icon: Icons.hourglass_bottom_outlined,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Periksa lagi',
                icon: Icons.refresh_rounded,
                expand: false,
                onPressed: controller.load,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _failedBody(ScanDetail d) {
    final error = d.error;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
            const SizedBox(height: 8),
            Text(
              (error?.message?.isNotEmpty ?? false)
                  ? error!.message!
                  : 'Prediksi gagal diproses. Coba lagi nanti.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (error?.code != null && error!.code!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Kode: ${error.code}',
                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Coba Lagi',
              icon: Icons.refresh_rounded,
              onPressed: controller.load,
            ),
            const SizedBox(height: 10),
            DangerButton(label: 'Hapus Scan', onPressed: controller.deleteScan),
          ],
        ),
      ),
    );
  }

  // ── hasil sukses ─────────────────────────────────────────────────────────

  Widget _resultBody(ScanDetail d) {
    final confidence = d.confidence ?? 0.0;
    final disease = d.disease;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d.lowConfidenceWarning) ...[
            const AppBanner(
              message:
                  'Keyakinan model di bawah 60%. Periksa kembali kondisi ikan atau foto dengan pencahayaan lebih baik.',
              icon: Icons.warning_amber_outlined,
            ),
            const SizedBox(height: 12),
          ],
          _heroCard(d),
          const SizedBox(height: 12),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tingkat Keyakinan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${confidence.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConfidenceBar(value: confidence, height: 12),
                if (d.processingTimeMs != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Diproses dalam ${(d.processingTimeMs! / 1000).toStringAsFixed(1)} detik'
                    '${d.modelVersion == null ? '' : ' • Model ${d.modelVersion}'}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textLight),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (disease != null) ...[
            InkWell(
              onTap: controller.openDisease,
              borderRadius: BorderRadius.circular(16),
              child: _card(
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                          color: AppColors.softSky, shape: BoxShape.circle),
                      child: const Icon(Icons.coronavirus_outlined,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disease.name ?? 'Penyakit terdeteksi',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SeverityBadge(severity: disease.severity, small: true),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (d.topPredictions.isNotEmpty) ...[
            const SectionHeader(title: 'Prediksi Lainnya'),
            _card(
              Column(
                children: [
                  for (var i = 0; i < d.topPredictions.length; i++) ...[
                    if (i > 0) const Divider(height: 18),
                    _predictionRow(d.topPredictions[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Informasi Scan'),
                _infoRow(Icons.schedule, timeAgo(d.createdAt)),
                if (d.pond?.name != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.water_outlined, d.pond!.name!),
                ],
                if (d.fishType != null && d.fishType!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.pets_outlined, 'Jenis ikan: ${d.fishType}'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Scan Lagi',
            icon: Icons.camera_alt_outlined,
            onPressed: controller.scanAgain,
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Export PDF',
            icon: Icons.ios_share_rounded,
            onPressed: controller.isExporting.value ? null : controller.exportPdf,
          ),
          const SizedBox(height: 10),
          DangerButton(
            label: 'Hapus',
            onPressed: controller.isDeleting.value ? null : controller.deleteScan,
          ),
        ],
      ),
    );
  }

  Widget _heroCard(ScanDetail d) {
    final images = d.images;
    ScanImage? primary;
    for (final img in images) {
      if (img.isPrimary) {
        primary = img;
        break;
      }
    }
    primary ??= images.isEmpty ? null : images.first;
    final heroUrl = resolveImageUrl(primary?.url);
    final gradcamUrl = resolveImageUrl(d.gradcamUrl ?? primary?.gradcamUrl);
    final showOverlay =
        controller.showGradcam.value && gradcamUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: 240,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (heroUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: heroUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: AppColors.softSky),
                  errorWidget: (_, _, _) => _imageFallback(),
                )
              else
                _imageFallback(),
              if (showOverlay)
                Opacity(
                  opacity: 0.55,
                  child: CachedNetworkImage(
                    imageUrl: gradcamUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const SizedBox.shrink(),
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              if (gradcamUrl.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 10,
                  child: InkWell(
                    onTap: () => controller.showGradcam.toggle(),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            controller.showGradcam.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 14,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'GradCAM',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: AppColors.softSky,
        child: const Icon(Icons.photo_outlined, size: 48, color: AppColors.primary),
      );

  Widget _predictionRow(Prediction p) {
    final value = p.confidence ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                p.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ConfidenceBar(value: value, height: 6, showLabel: false),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
