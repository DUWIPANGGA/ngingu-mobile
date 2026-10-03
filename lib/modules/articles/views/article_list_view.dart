import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/article_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_feedback.dart';
import '../controllers/article_list_controller.dart';

/// Daftar artikel edukasi budidaya & kesehatan ikan.
class ArticleListView extends GetView<ArticleListController> {
  const ArticleListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.page,
      appBar: AppBar(title: const Text('Artikel Edukasi')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.items.isEmpty) {
            return const LoadingState(message: 'Memuat artikel...');
          }
          if (controller.errorMessage.value != null &&
              controller.items.isEmpty) {
            return ErrorState(
              message: controller.errorMessage.value!,
              onRetry: controller.reload,
            );
          }
          if (controller.items.isEmpty) {
            return const EmptyState(
              icon: Icons.article_outlined,
              title: 'Belum ada artikel',
              subtitle: 'Artikel edukasi akan tampil di sini.',
            );
          }
          return RefreshIndicator(
            onRefresh: controller.reload,
            color: AppColors.primary,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              itemCount: controller.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ArticleCard(
                item: controller.items[i],
                onTap: () => controller.openDetail(controller.items[i]),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.item, required this.onTap});

  final Article item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.softAmber,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.article_outlined,
                  size: 22, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((item.category ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        item.category!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  if ((item.excerpt ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.excerpt!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _ArticleMeta(item: item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris meta artikel (waktu baca + tanggal) — dipakai ulang di home.
class ArticleMeta extends StatelessWidget {
  const ArticleMeta({super.key, required this.item});

  final Article item;

  @override
  Widget build(BuildContext context) => _ArticleMeta(item: item);
}

class _ArticleMeta extends StatelessWidget {
  const _ArticleMeta({required this.item});

  final Article item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (item.readMinutes != null) ...[
          const Icon(Icons.schedule_outlined,
              size: 13, color: AppColors.textLight),
          const SizedBox(width: 4),
          Text(
            '${item.readMinutes} mnt baca',
            style: const TextStyle(
                fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ],
        if (item.readMinutes != null && item.publishedAt != null)
          const Text('  •  ',
              style: TextStyle(fontSize: 11.5, color: AppColors.textLight)),
        if (item.publishedAt != null)
          Expanded(
            child: Text(
              timeAgo(item.publishedAt),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
