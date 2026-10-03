import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/disease_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_fields.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../controllers/encyclopedia_controller.dart';

/// Ensiklopedia penyakit — publik & bisa dibuka tamu (API.md §5.1, FR-03.1).
class EncyclopediaView extends GetView<EncyclopediaController> {
  const EncyclopediaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _header() {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ensiklopedia Penyakit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kenali gejala, penyebab, dan penanganan penyakit ikan.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final canClear = controller.hasQuery.value;
            return AppSearchField(
              controller: controller.searchController,
              hint: 'Cari penyakit, gejala, atau jenis ikan',
              onChanged: controller.onSearchChanged,
              onClear: canClear ? controller.clearSearch : null,
            );
          }),
          const SizedBox(height: 12),
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final option
                        in EncyclopediaController.severityOptions)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: option['label'] ?? 'Semua',
                          selected: controller.severityFilter.value ==
                              (option['value'] ?? ''),
                          onTap: () =>
                              controller.setSeverity(option['value'] ?? ''),
                        ),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _body() {
    return Obx(() {
      final items = controller.items;

      if (controller.isLoading.value && items.isEmpty) {
        return const DiseaseListSkeleton();
      }
      if (controller.errorMessage.value != null && items.isEmpty) {
        return ErrorState(
          message: controller.errorMessage.value!,
          onRetry: () => controller.reload(),
        );
      }
      if (items.isEmpty) {
        return const EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Belum ada penyakit cocok',
          subtitle: 'Coba kata kunci lain atau ubah filter tingkat keparahan.',
        );
      }

      return RefreshIndicator(
        onRefresh: controller.reload,
        color: AppColors.primary,
        child: ListView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (controller.isOffline.value) ...[
              const AppBanner(
                message: 'Mode offline — menampilkan data terakhir tersimpan.',
                icon: Icons.cloud_off_outlined,
              ),
              const SizedBox(height: 10),
            ],
            if (controller.isLoading.value)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(
                  minHeight: 2.5,
                  color: AppColors.primary,
                  backgroundColor: AppColors.border,
                ),
              ),
            for (var i = 0; i < items.length; i++) ...[
              _DiseaseCard(
                item: items[i],
                onTap: () => controller.goToDetail(items[i]),
              ),
              if (i < items.length - 1) const SizedBox(height: 12),
            ],
            if (controller.isLoadingMore.value)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Pieces
// ═══════════════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
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
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DiseaseCard extends StatelessWidget {
  const _DiseaseCard({required this.item, required this.onTap});

  final DiseaseItem item;
  final VoidCallback onTap;

  String get _subtitle {
    final snippet = item.snippet;
    if (snippet != null && snippet.isNotEmpty) return snippet;
    if (item.fishTypes.isNotEmpty) return 'Ikan: ${item.fishTypes.join(', ')}';
    return 'Penyakit ikan budidaya';
  }

  @override
  Widget build(BuildContext context) {
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
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _thumb(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SeverityBadge(severity: item.severity, small: true),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      CategoryChip(category: item.category),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.recoveryDays == null
                              ? '—'
                              : 'Sembuh ${item.recoveryDays!.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textLight,
                          ),
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

  Widget _thumb() {
    final url = resolveImageUrl(item.thumbnailUrl);
    const fallback = ColoredBox(
      color: AppColors.softSky,
      child: Center(
        child: Icon(Icons.coronavirus_outlined,
            size: 28, color: AppColors.primary),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 76,
        height: 76,
        child: url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
