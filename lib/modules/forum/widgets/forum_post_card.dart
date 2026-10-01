import 'package:flutter/material.dart';

import '../../../core/models/forum_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_avatar.dart';
import '../utils/forum_utils.dart';
import 'forum_category_chip.dart';

/// Post row for the forum list (SRS §7.4 "Forum Post Card").
class ForumPostCard extends StatelessWidget {
  const ForumPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onAuthorTap,
  });

  final ForumPost post;
  final VoidCallback? onTap;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final author = post.author;
    final reputation = author?.reputationLevel;
    final imageCount = post.imageUrls.length;
    final linkedScan = post.linkedScan;
    final excerpt = excerptOf(post);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── author row ────────────────────────────────────────────────
            Row(
              children: [
                InkWell(
                  onTap: onAuthorTap,
                  borderRadius: BorderRadius.circular(20),
                  child: AppAvatar(
                    url: author?.avatarUrl,
                    name: author?.name ?? '-',
                    radius: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: onAuthorTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author?.name ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                        ),
                        if (reputation != null && reputation.isNotEmpty)
                          Text(
                            reputation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textLight),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeAgo(post.createdAt),
                  style:
                      const TextStyle(fontSize: 11.5, color: AppColors.textLight),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── meta chips ────────────────────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (post.category != null)
                  ForumCategoryChip.fromCategory(post.category!, compact: true, subtle: true),
                if (imageCount > 0)
                  _MetaIcon(icon: Icons.image_outlined, label: '$imageCount'),
                if (linkedScan != null)
                  _MetaIcon(
                      icon: Icons.document_scanner_outlined,
                      label: linkedScan.diseaseName ?? 'Hasil scan'),
                if (post.isPending)
                  _MetaIcon(icon: Icons.schedule, label: 'Menunggu moderasi'),
              ],
            ),
            const SizedBox(height: 8),

            // ── title & excerpt ───────────────────────────────────────────
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.3),
            ),
            if (excerpt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                excerpt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.45),
              ),
            ],
            const SizedBox(height: 10),

            // ── footer ────────────────────────────────────────────────────
            Row(
              children: [
                _FooterStat(
                  icon: post.votesCount >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  label: compactCount(post.votesCount),
                  color: post.votesCount >= 0
                      ? AppColors.primary
                      : AppColors.danger,
                ),
                const SizedBox(width: 12),
                _FooterStat(
                  icon: Icons.mode_comment_outlined,
                  label: compactCount(post.commentsCount),
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                _FooterStat(
                  icon: Icons.visibility_outlined,
                  label: compactCount(post.viewsCount),
                  color: AppColors.textSecondary,
                ),
                const Spacer(),
                if (post.hasBestAnswer)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.secondary),
                      SizedBox(width: 4),
                      Text('Terjawab',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaIcon extends StatelessWidget {
  const _MetaIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  const _FooterStat({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
