import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_feedback.dart';
import '../controllers/public_profile_controller.dart';
import '../widgets/profile_widgets.dart';

/// Halaman profil publik (FR-08.4): identitas, reputasi, statistik, badge.
class PublicProfileView extends GetView<PublicProfileController> {
  const PublicProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Profil Pengguna')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.profile.value == null) {
            return const LoadingState(message: 'Memuat profil...');
          }
          final profile = controller.profile.value;
          if (profile == null) {
            return ErrorState(
              message: controller.errorMessage.value ??
                  'Profil gagal dimuat. Coba lagi.',
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
                _headerCard(profile),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Postingan',
                        value: profile.postsCount,
                        icon: Icons.forum_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Jawaban Terbaik',
                        value: profile.bestAnswersCount,
                        icon: Icons.check_circle_outline,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                if (profile.badges.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Badge'),
                  SoftCard(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final badge in profile.badges)
                          InfoChip(
                            icon: Icons.verified_rounded,
                            label: badge.label,
                            bg: AppColors.softGreen,
                            color: AppColors.secondary,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _headerCard(PublicProfile profile) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(url: profile.avatarUrl, name: profile.name, radius: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if ((profile.username ?? '').isNotEmpty)
                      Text(
                        '@${profile.username}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if ((profile.province ?? '').isNotEmpty)
                          InfoChip(
                            icon: Icons.place_outlined,
                            label: profile.province!,
                          ),
                        InfoChip(
                          icon: Icons.emoji_events_outlined,
                          label:
                              '${profile.reputationPoints} • ${profile.reputationLevel}',
                          bg: AppColors.softAmber,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((profile.bio ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              profile.bio!,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.textLight),
              const SizedBox(width: 6),
              Text(
                'Bergabung ${formatDate(profile.joinedAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
