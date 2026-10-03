import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_feedback.dart';
import '../controllers/article_detail_controller.dart';

/// Isi artikel edukasi.
class ArticleDetailView extends GetView<ArticleDetailController> {
  const ArticleDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.page,
      appBar: AppBar(
        title: const Text('Artikel'),
        actions: [
          Obx(() {
            final d = controller.detail.value;
            if (d == null) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Bagikan',
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  title: d.title,
                  text: '${d.title}\n\nDibaca via Ngingu',
                ),
              ),
            );
          }),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value &&
              controller.detail.value == null) {
            return const LoadingState(message: 'Memuat artikel...');
          }
          final d = controller.detail.value;
          if (d == null) {
            return ErrorState(
              message: controller.errorMessage.value ?? 'Artikel tidak ada.',
              onRetry: controller.load,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((d.category ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      d.category!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  d.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (d.readMinutes != null) ...[
                      const Icon(Icons.schedule_outlined,
                          size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        '${d.readMinutes} menit baca',
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary),
                      ),
                    ],
                    if (d.publishedAt != null) ...[
                      const Text('  •  ',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textLight)),
                      Text(
                        timeAgo(d.publishedAt),
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                if (d.body.isEmpty)
                  const Text(
                    'Isi artikel belum tersedia.',
                    style: TextStyle(
                        fontSize: 13.5, color: AppColors.textSecondary),
                  )
                else
                  for (final p in d.body) ...[
                    Text(
                      p,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
              ],
            ),
          );
        }),
      ),
    );
  }
}
