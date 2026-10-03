import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/scan_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../routes/app_routes.dart';
import '../controllers/scan_history_controller.dart';
import '../scan_shared.dart';

/// Riwayat scan: chip filter, paginasi (load more + pull-to-refresh), hapus,
/// dan menu export CSV/PDF.
class ScanHistoryView extends GetView<ScanHistoryController> {
  const ScanHistoryView({super.key});

  static const List<(String, String)> _filters = [
    ('all', 'Semua'),
    ('pending', 'Pending'),
    ('done', 'Selesai'),
    ('failed', 'Gagal'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.page,
      appBar: AppBar(
        title: const Text('Riwayat Scan'),
        actions: [
          Obx(() => controller.isExporting.value
              ? const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const SizedBox.shrink()),
          PopupMenuButton<String>(
            tooltip: 'Export riwayat',
            icon: const Icon(Icons.ios_share_rounded),
            onSelected: controller.exportHistory,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'csv',
                child: Text('Export CSV',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Text('Export PDF',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(child: Obx(() => _body())),
    );
  }

  Widget _body() {
    if (!AuthService.isAuthed) return _guestState();
    if (controller.isLoading.value && controller.items.isEmpty) {
      return const _SkeletonList();
    }
    if (controller.errorMessage.value.isNotEmpty && controller.items.isEmpty) {
      return ErrorState(
        message: controller.errorMessage.value,
        onRetry: controller.refreshList,
      );
    }
    final list = controller.visibleItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(list.length),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.refreshList,
            child: list.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 60),
                      EmptyState(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'Tidak ada scan',
                        subtitle: 'Belum ada scan dengan filter ini.',
                      ),
                    ],
                  )
                : ListView.separated(
                    controller: controller.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == list.length) return _loadMoreIndicator();
                      final item = list[index];
                      return _ScanCard(
                        summary: item,
                        onTap: () => Get.toNamed(Routes.scanResult,
                            arguments: {'scanId': item.scanId}),
                        onDelete: () => controller.deleteScan(item),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _loadMoreIndicator() {
    if (!controller.isLoadingMore.value) return const SizedBox(height: 8);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }

  Widget _header(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count scan ditampilkan',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _filters.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _FilterChip(
                    label: _filters[i].$2,
                    selected: controller.filter.value == _filters[i].$1,
                    onTap: () => controller.setFilter(_filters[i].$1),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestState() {
    return EmptyState(
      icon: Icons.lock_outline_rounded,
      title: 'Masuk untuk melihat riwayat',
      subtitle: 'Riwayat scan tersimpan di akunmu. Masuk untuk membukanya.',
      actionLabel: 'Masuk',
      onAction: () => Get.toNamed(Routes.login),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.summary, this.onTap, this.onDelete});

  final ScanSummary summary;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final status = summary.status;
    final statusColor = scanStatusColor(status);
    final thumbnail = resolveImageUrl(summary.thumbnailUrl);
    final diseaseName = summary.disease?.name;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: thumbnail.isEmpty
                    ? Container(
                        color: AppColors.softSky,
                        child: const Icon(Icons.photo_outlined,
                            color: AppColors.primary, size: 26),
                      )
                    : CachedNetworkImage(
                        imageUrl: thumbnail,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: AppColors.softSky),
                        errorWidget: (_, _, _) => Container(
                          color: AppColors.softSky,
                          child: const Icon(Icons.photo_outlined,
                              color: AppColors.primary, size: 26),
                        ),
                      ),
              ),
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
                          diseaseName == null || diseaseName.isEmpty
                              ? 'Belum ada prediksi'
                              : diseaseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusChip(label: scanStatusLabel(status), color: statusColor),
                    ],
                  ),
                  if (summary.disease?.severity != null) ...[
                    const SizedBox(height: 6),
                    SeverityBadge(severity: summary.disease!.severity, small: true),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (summary.confidence != null) ...[
                        const Icon(Icons.insights_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${summary.confidence!.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (summary.pond?.name != null) ...[
                        const Icon(Icons.water_outlined,
                            size: 13, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            summary.pond!.name!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        timeAgo(summary.createdAt),
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textLight),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.delete_outline,
                              size: 18, color: AppColors.textLight),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

/// Kartu abu-abu berdenyut untuk loading awal (SRS §7.1 — skeleton).
class _SkeletonList extends StatefulWidget {
  const _SkeletonList();

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 0.9).animate(_controller),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => Container(
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 12,
                      width: 180,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
