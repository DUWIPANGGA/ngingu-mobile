import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/pond_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_feedback.dart';
import '../controllers/pond_health_controller.dart';
import '../widgets/pond_common.dart';

/// Laporan kesehatan tambak (FR-04.2) — gauge skor, tren scan/penyakit,
/// alert penyakit berulang, scan terakhir, CTA scan baru.
class PondHealthView extends GetView<PondHealthController> {
  const PondHealthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Laporan Kesehatan')),
      body: SafeArea(child: Obx(_body)),
    );
  }

  Widget _body() {
    if (controller.isLoading.value && controller.report.value == null) {
      return const _HealthSkeleton();
    }
    final report = controller.report.value;
    if (report == null) {
      return ErrorState(
        message: controller.errorMessage.value ?? 'Laporan tidak ditemukan.',
        onRetry: controller.fetch,
      );
    }
    return RefreshIndicator(
      onRefresh: controller.fetch,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _headerCard(report),
          const SizedBox(height: 14),
          _trendCard(report),
          if (report.repeatAlert != null &&
              (report.repeatAlert!.diseaseName ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            _repeatAlertCard(report.repeatAlert!),
          ],
          if (report.lastScan != null) ...[
            const SizedBox(height: 14),
            _lastScanCard(report.lastScan!),
          ],
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Scan Baru',
            icon: Icons.center_focus_strong,
            onPressed: controller.startScan,
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Ambil foto ikan untuk prediksi penyakit terbaru.',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _headerCard(HealthReport report) {
    final pond = controller.pond.value;
    final score = report.healthScore;
    final color = healthScoreColor(score);
    final location = pond?.locationLabel;
    return Container(
      decoration: pondCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.pondName ?? pond?.name ?? 'Tambak',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if ((location ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 15, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (pond?.areaM2 != null)
                          PondInfoChip(
                            icon: Icons.straighten_outlined,
                            label: '${idNumber(pond!.areaM2!)} m²',
                          ),
                        if (pond?.capacity != null)
                          PondInfoChip(
                            icon: Icons.group_outlined,
                            label: '${idNumber(pond!.capacity!)} ekor',
                          ),
                        for (final fish in (pond?.fishTypes ?? const [])
                            .take(3))
                          PondInfoChip(icon: Icons.pets_outlined, label: fish),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              HealthScoreRing(score: score, size: 98),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                ),
                child: Text(
                  healthScoreLabel(score),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Skor dihitung dari frekuensi & keparahan penyakit.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tren ──────────────────────────────────────────────────────────────────

  Widget _trendCard(HealthReport report) {
    final trend = report.trend;
    return Container(
      decoration: pondCardDecoration(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Tren Aktivitas'),
          const Text(
            'Jumlah scan dan penyakit terdeteksi per hari.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 14),
          if (trend.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Belum ada data tren untuk periode ini.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final point in trend) _trendBar(point, trend),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _trendBar(HealthTrendPoint point, List<HealthTrendPoint> trend) {
    final peak = trend
        .map((p) => math.max(p.scans, p.diseases.length))
        .fold<int>(1, math.max);
    final value = math.max(point.scans, point.diseases.length);
    final barHeight = value == 0 ? 4.0 : 6.0 + (value / peak) * 74.0;
    final hasDisease = point.diseases.isNotEmpty;
    final color = hasDisease ? AppColors.accent : AppColors.primary;
    return SizedBox(
      width: 42,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value == 0 ? '' : '$value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 18,
            height: barHeight,
            decoration: BoxDecoration(
              color: value == 0 ? AppColors.border : color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            shortDate(point.date),
            style: const TextStyle(fontSize: 10.5, color: AppColors.textLight),
          ),
          SizedBox(
            height: 26,
            child: hasDisease
                ? Tooltip(
                    message: point.diseases.join(', '),
                    child: const Icon(Icons.coronavirus_outlined,
                        size: 13, color: AppColors.danger),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ── Alert penyakit berulang ───────────────────────────────────────────────

  Widget _repeatAlertCard(RepeatAlert alert) {
    final tappable = alert.diseaseId != null;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: tappable ? () => controller.openDisease(alert.diseaseId) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.softRed.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  size: 20, color: AppColors.danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penyakit muncul berulang',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.diseaseName ?? '-',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alert.occurrences == null
                        ? 'Terdeteksi berulang dalam 7 hari terakhir.'
                        : 'Muncul ${alert.occurrences} kali dalam 7 hari terakhir.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (tappable)
              const Icon(Icons.chevron_right_rounded,
                  size: 22, color: AppColors.danger),
          ],
        ),
      ),
    );
  }

  // ── Scan terakhir ─────────────────────────────────────────────────────────

  Widget _lastScanCard(LastScanRef lastScan) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: controller.openScan,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: pondCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.softSky,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.center_focus_weak,
                  size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan terakhir',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastScan.createdAt == null
                        ? 'Waktu tidak tersedia'
                        : 'Dilakukan ${timeAgo(lastScan.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 22, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

/// Placeholder rangka saat memuat laporan.
class _HealthSkeleton extends StatelessWidget {
  const _HealthSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box({double height = 16, double width = double.infinity}) =>
        Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
        );

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: pondCardDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(height: 18, width: 140),
                    const SizedBox(height: 10),
                    box(height: 12, width: 180),
                    const SizedBox(height: 14),
                    box(height: 22, width: 220),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox(
                width: 98,
                height: 98,
                child: CircularProgressIndicator(
                  strokeWidth: 9,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: pondCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box(height: 16, width: 120),
              const SizedBox(height: 16),
              box(height: 90),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: pondCardDecoration(),
          child: box(height: 56),
        ),
      ],
    );
  }
}
