import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/alert_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_feedback.dart';
import '../controllers/heatmap_controller.dart';

/// Peta sebaran penyakit (FR-07.3): heatmap titik per provinsi + feed
/// "Laporan Terbaru" dari `GET /api/outbreaks`.
class HeatmapView extends GetView<HeatmapController> {
  const HeatmapView({super.key});

  @override
  Widget build(BuildContext context) {
    final mapHeight = MediaQuery.sizeOf(context).height * 0.45;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Peta Sebaran Penyakit'),
        actions: [
          Obx(() => controller.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.only(right: 18),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: AppColors.primary),
                  ),
                )
              : IconButton(
                  tooltip: 'Muat ulang',
                  onPressed: controller.fetchAll,
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.textPrimary),
                )),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.fetchAll,
          child: Obx(
            () => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _rangeChips(),
                  const SizedBox(height: 12),
                  _mapCard(context, mapHeight),
                  if (controller.points.isEmpty &&
                      !controller.isLoading.value &&
                      !controller.hasError.value) ...[
                    const SizedBox(height: 10),
                    const AppBanner(
                      icon: Icons.info_outline,
                      message:
                          'Belum ada laporan sebaran pada rentang waktu ini. Peta tetap dapat dijelajahi.',
                    ),
                  ],
                  const SizedBox(height: 22),
                  const SectionHeader(title: 'Laporan Terbaru'),
                  _outbreaksCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── rentang hari (API.md §7.11: query `days`) ────────────────────────────

  Widget _rangeChips() {
    return Row(
      children: [
        const Text(
          'Rentang',
          style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final days in HeatmapController.rangeOptions) ...[
                  if (days != HeatmapController.rangeOptions.first)
                    const SizedBox(width: 8),
                  _rangeChip(days),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _rangeChip(int days) {
    final selected = controller.selectedRange.value == days;
    return InkWell(
      onTap: () => controller.setRange(days),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 1.2),
        ),
        child: Text(
          '$days Hari',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── peta ─────────────────────────────────────────────────────────────────

  Widget _mapCard(BuildContext context, double height) {
    return Container(
      decoration: BoxDecoration(
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(height: height, child: _mapStack()),
      ),
    );
  }

  Widget _mapStack() {
    final selected = controller.selectedPoint.value;
    final hasPoints = controller.points.isNotEmpty;
    final isReady = !controller.isLoading.value && !controller.hasError.value;
    return Stack(
      children: [
        _mapBody(),
        if (hasPoints || isReady) _focusIndramayuButton(),
        if (hasPoints && selected == null) _legend(),
        if (selected != null) _selectedCard(selected),
        if (!hasPoints && isReady) _emptyOverlay(),
      ],
    );
  }

  Widget _focusIndramayuButton() {
    return Positioned(
      top: 10,
      right: 10,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.focusIndramayu,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.my_location_rounded,
                    size: 14, color: AppColors.primary),
                SizedBox(width: 5),
                Text(
                  'Fokus Indramayu',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mapBody() {
    if (controller.isLoading.value && controller.points.isEmpty) {
      return Container(
        color: AppColors.border.withValues(alpha: 0.4),
        child: const Center(
          child: SingleChildScrollView(
            child: LoadingState(message: 'Memuat peta sebaran...'),
          ),
        ),
      );
    }
    if (controller.hasError.value && controller.points.isEmpty) {
      return Container(
        color: AppColors.white,
        child: Center(
          child: SingleChildScrollView(
            child: ErrorState(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              message: controller.errorMessage.value ?? 'Gagal memuat peta sebaran.',
              onRetry: controller.fetchHeatmap,
            ),
          ),
        ),
      );
    }
    return FlutterMap(
      mapController: controller.mapController,
      options: const MapOptions(
        initialCenter: HeatmapController.indramayuCenter,
        initialZoom: HeatmapController.indramayuZoom,
        minZoom: 4,
        maxZoom: 18,
        keepAlive: true,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'id.ngingu.apps',
          maxZoom: 19,
        ),
        MarkerLayer(markers: _markers()),
      ],
    );
  }

  List<Marker> _markers() {
    final selected = controller.selectedPoint.value;
    final markers = <Marker>[];
    for (final point in controller.points) {
      if (point.lat < -90 || point.lat > 90) continue;
      if (point.lng < -180 || point.lng > 180) continue;
      final severity = HeatmapController.severityForCases(point.cases);
      final color = AppColors.severity(severity);
      final size = HeatmapController.markerSize(point.cases);
      final isSelected = selected == point;
      markers.add(
        Marker(
          point: LatLng(point.lat, point.lng),
          width: size,
          height: size,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.selectPoint(point),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: isSelected ? 1 : 0.88),
                border: Border.all(
                    color: isSelected ? AppColors.primaryDark : Colors.white,
                    width: isSelected ? 3 : 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 8,
                    spreadRadius: 1.5,
                  ),
                ],
              ),
              child: Text(
                '${point.cases}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size >= 40 ? 13 : 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _legend() {
    const entries = <(String, String)>[
      ('Ringan', '< 5 kasus'),
      ('Sedang', '5 - 9 kasus'),
      ('Berat', '10 - 19 kasus'),
      ('Kritis', '20+ kasus'),
    ];
    return Positioned(
      left: 10,
      bottom: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tingkat kasus',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            for (final (severity, range) in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.severity(severity.toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '$severity ($range)',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _selectedCard(HeatmapPoint point) {
    final severity = HeatmapController.severityForCases(point.cases);
    final color = AppColors.severity(severity);
    final diseaseId = controller.resolveDiseaseId(point);
    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.province,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (point.topDisease ?? '').isNotEmpty
                            ? 'Penyakit dominan: ${point.topDisease}'
                            : 'Belum ada penyakit dominan',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Tutup',
                    onPressed: controller.clearSelection,
                    icon: const Icon(Icons.close_rounded,
                        size: 19, color: AppColors.textLight),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SeverityBadge(severity: severity, small: true),
                    const SizedBox(width: 8),
                    Text(
                      '${point.cases} kasus',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color),
                    ),
                  ],
                ),
                if (diseaseId != null)
                  TextButton(
                    onPressed: controller.openPointDisease,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Lihat Penyakit',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyOverlay() {
    return Positioned.fill(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const SingleChildScrollView(
              child: EmptyState(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                icon: Icons.map_outlined,
                title: 'Belum ada laporan sebaran',
                subtitle:
                    'Laporan penyakit dari pengguna lain akan tampil di sini.',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── laporan terbaru (GET /api/outbreaks) ─────────────────────────────────

  Widget _outbreaksCard() {
    return Container(
      decoration: BoxDecoration(
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
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: _outbreaksBody()),
    );
  }

  Widget _outbreaksBody() {
    if (controller.outbreaksLoading.value && controller.outbreaks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: LoadingState(message: 'Memuat laporan terbaru...'),
      );
    }
    if (controller.outbreaksError.value != null &&
        controller.outbreaks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ErrorState(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          message: controller.outbreaksError.value!,
          onRetry: controller.fetchOutbreaks,
        ),
      );
    }
    if (controller.outbreaks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: EmptyState(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          icon: Icons.notifications_active_outlined,
          title: 'Belum ada alert wabah',
          subtitle: 'Belum ada wabah penyakit yang terdeteksi saat ini.',
        ),
      );
    }
    final items = controller.outbreaks;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _outbreakTile(items[i]),
          if (i < items.length - 1) const Divider(indent: 66, endIndent: 16),
        ],
      ],
    );
  }

  Widget _outbreakTile(Outbreak item) {
    final color = AppColors.severity(item.severity);
    return InkWell(
      onTap: () => controller.openOutbreak(item),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.diseaseName ?? 'Penyakit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SeverityBadge(severity: item.severity, small: true),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.province ?? '-'} · ${timeAgo(item.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.cases7d} kasus dalam 7 hari',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
