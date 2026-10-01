import 'package:flutter/material.dart';

import '../../../core/models/forum_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_avatar.dart';
import '../utils/forum_utils.dart';
import 'forum_images.dart';

/// One comment (optionally a nested reply — max 2 levels, FR-05.3.1).
class ForumCommentTile extends StatelessWidget {
  const ForumCommentTile({
    super.key,
    required this.comment,
    this.isReply = false,
    this.canReply = false,
    this.canDelete = false,
    this.canMarkBest = false,
    this.onAuthorTap,
    this.onReply,
    this.onDelete,
    this.onMarkBest,
    this.onUpvote,
    this.onDownvote,
  });

  final ForumComment comment;
  final bool isReply;
  final bool canReply;
  final bool canDelete;
  final bool canMarkBest;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkBest;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;

  @override
  Widget build(BuildContext context) {
    final author = comment.author;
    final body = stripHtml(comment.contentHtml);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isReply ? 10 : 14),
      decoration: BoxDecoration(
        color: isReply ? AppColors.surface : AppColors.white,
        borderRadius: BorderRadius.circular(isReply ? 12 : 16),
        border: Border.all(
          color: isReply ? Colors.transparent : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onAuthorTap,
                borderRadius: BorderRadius.circular(14),
                child: AppAvatar(
                  url: author?.avatarUrl,
                  name: author?.name ?? '-',
                  radius: isReply ? 11 : 14,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: onAuthorTap,
                            child: Text(
                              author?.name ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isReply ? 12.5 : 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeAgo(comment.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textLight),
                        ),
                      ],
                    ),
                    if (comment.isBestAnswer) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.softGreen,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 12, color: AppColors.secondary),
                            SizedBox(width: 4),
                            Text('Jawaban Terbaik',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondary)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                fontSize: isReply ? 13 : 13.5,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
          ForumImageStrip(urls: comment.images, size: isReply ? 60 : 72),
          const SizedBox(height: 8),
          Row(
            children: [
              _VoteButton(
                icon: Icons.arrow_upward_rounded,
                active: comment.myVote == 1,
                activeColor: AppColors.primary,
                count: comment.votesCount,
                onPressed: onUpvote,
              ),
              const SizedBox(width: 6),
              _VoteButton(
                icon: Icons.arrow_downward_rounded,
                active: comment.myVote == -1,
                activeColor: AppColors.danger,
                onPressed: onDownvote,
              ),
              if (canReply) ...[
                const SizedBox(width: 4),
                TextButton(
                  onPressed: onReply,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Balas',
                      style:
                          TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                ),
              ],
              if (canMarkBest) ...[
                TextButton(
                  onPressed: onMarkBest,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Jadikan Terbaik',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ],
              const Spacer(),
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.textLight),
                  tooltip: 'Hapus komentar',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    this.count,
    this.onPressed,
  });

  final IconData icon;
  final bool active;
  final Color activeColor;
  final int? count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : AppColors.textLight;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: active ? activeColor : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
