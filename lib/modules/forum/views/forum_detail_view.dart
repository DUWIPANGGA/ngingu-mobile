import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/forum_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/app_fields.dart';
import '../controllers/forum_detail_controller.dart';
import '../utils/forum_utils.dart';
import '../widgets/forum_category_chip.dart';
import '../widgets/forum_comment_tile.dart';
import '../widgets/forum_images.dart';

/// Post detail + comment thread (FR-05.3/FR-05.4, API.md §6.4).
class ForumDetailView extends GetView<ForumDetailController> {
  const ForumDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.page,
      appBar: AppBar(
        title: const Text('Detail Diskusi'),
        actions: [
          Obx(
            () => controller.post.value == null
                ? const SizedBox.shrink()
                : _OverflowMenu(controller: controller, onReport: () => _showReportSheet(context)),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() => _buildBody(context)),
            ),
            Obx(
              () => controller.isAuthed
                  ? _Composer(controller: controller)
                  : _GuestBar(controller: controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading.value && controller.post.value == null) {
      return const LoadingState(message: 'Memuat diskusi...');
    }
    if (controller.hasError.value && controller.post.value == null) {
      return ErrorState(
        message: controller.errorMessage.value,
        onRetry: controller.retry,
      );
    }
    final post = controller.post.value;
    if (post == null) {
      return const ErrorState(message: 'Diskusi tidak ditemukan.');
    }
    return RefreshIndicator(
      onRefresh: controller.loadDetail,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthorRow(
              post: post,
              onTap: post.author == null
                  ? null
                  : () => controller.openAuthor(post.author!),
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.3),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (post.category != null)
                  ForumCategoryChip.fromCategory(post.category!, compact: true, subtle: true),
                Text(
                  timeAgo(post.createdAt),
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility_outlined,
                        size: 14, color: AppColors.textLight),
                    const SizedBox(width: 3),
                    Text(
                      '${post.viewsCount}x dilihat',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
                if (post.isPending)
                  const Text(
                    'Menunggu moderasi',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent),
                  ),
              ],
            ),
            if (post.contentHtml != null && post.contentHtml!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                _plainBody(post.contentHtml),
                style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                    height: 1.6),
              ),
            ],
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 14),
              ForumImageGallery(urls: post.imageUrls),
            ],
            if (post.linkedScan != null || (post.linkedScanId?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 14),
              _LinkedScanCard(
                scan: post.linkedScan,
                onTap: controller.openLinkedScan,
              ),
            ],
            const SizedBox(height: 16),
            _ActionBar(controller: controller, post: post),
            const SizedBox(height: 20),
            SectionHeader(title: 'Komentar (${controller.commentsCount})'),
            _Comments(controller: controller),
          ],
        ),
      ),
    );
  }

  String _plainBody(String? html) {
    final text = stripHtml(html);
    return text.isEmpty ? '-' : text;
  }

  void _showReportSheet(BuildContext context) {
    const reasons = <String, String>{
      'spam': 'Spam',
      'konten_kasar': 'Konten Kasar',
      'hoax': 'Hoax / Menyesatkan',
      'lainnya': 'Lainnya',
    };
    Get.bottomSheet(
      SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Laporkan diskusi'),
              const Text(
                'Pilih alasan agar moderator dapat menindak lebih cepat.',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              for (final entry in reasons.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.flag_outlined,
                      size: 20, color: AppColors.danger),
                  title: Text(
                    entry.value,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Get.back();
                    controller.reportPost(entry.key);
                  },
                ),
            ],
          ),
        ),
      ),
      backgroundColor: AppColors.white,
    );
  }
}

/// Author line: avatar, name, reputation, tap → public profile (§7.10).
class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.post, this.onTap});

  final ForumPost post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final author = post.author;
    final reputation = author?.reputationLevel;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          AppAvatar(
            url: author?.avatarUrl,
            name: author?.name ?? '-',
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author?.name ?? '-',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
                if (reputation != null && reputation.isNotEmpty)
                  Text(
                    reputation,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.textLight),
        ],
      ),
    );
  }
}

/// Thumbnail + "Lihat Hasil Scan" → scan result (FR-05.2.3).
class _LinkedScanCard extends StatelessWidget {
  const _LinkedScanCard({this.scan, this.onTap});

  final LinkedScan? scan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disease = scan?.diseaseName;
    final confidence = scan?.confidence;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.softSky,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: scan?.thumbnailUrl == null
                  ? Container(
                      width: 52,
                      height: 52,
                      color: AppColors.white,
                      child: const Icon(Icons.document_scanner_outlined,
                          size: 24, color: AppColors.primary),
                    )
                  : CachedNetworkImage(
                      imageUrl: resolveImageUrl(scan!.thumbnailUrl),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(width: 52, height: 52, color: AppColors.white),
                      errorWidget: (_, _, _) => Container(
                        width: 52,
                        height: 52,
                        color: AppColors.white,
                        child: const Icon(Icons.document_scanner_outlined,
                            size: 24, color: AppColors.primary),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hasil scan terkait',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    disease ?? 'Hasil prediksi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                  ),
                  if (confidence != null)
                    Text(
                      'Confidence ${confidence.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primaryDark),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.primary),
                  SizedBox(width: 5),
                  Text('Lihat Hasil Scan',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vote / bookmark / follow / comments row (§6.7–§6.9).
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller, required this.post});

  final ForumDetailController controller;
  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    final viewer = post.viewer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _votePill(
            icon: Icons.arrow_upward_rounded,
            active: viewer.myVote == 1,
            color: AppColors.primary,
            onTap: () => controller.vote(1),
          ),
          const SizedBox(width: 10),
          Text(
            '${post.votesCount}',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(width: 10),
          _votePill(
            icon: Icons.arrow_downward_rounded,
            active: viewer.myVote == -1,
            color: AppColors.danger,
            onTap: () => controller.vote(-1),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mode_comment_outlined,
                  size: 17, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${controller.commentsCount}',
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: viewer.isBookmarked ? 'Hapus simpanan' : 'Simpan diskusi',
            onPressed: controller.toggleBookmark,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              viewer.isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              size: 21,
              color:
                  viewer.isBookmarked ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
          IconButton(
            tooltip: viewer.isFollowing
                ? 'Berhenti mengikuti'
                : 'Ikuti diskusi',
            onPressed: controller.toggleFollow,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              viewer.isFollowing
                  ? Icons.notifications_active
                  : Icons.notifications_active_outlined,
              size: 21,
              color: viewer.isFollowing
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _votePill({
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.14) : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
              color: active ? color : Colors.transparent, width: 1.2),
        ),
        child: Icon(icon, size: 18, color: active ? color : AppColors.textSecondary),
      ),
    );
  }
}

/// Top-level comments plus one level of replies (FR-05.3.1).
class _Comments extends StatelessWidget {
  const _Comments({required this.controller});

  final ForumDetailController controller;

  @override
  Widget build(BuildContext context) {
    final top = controller.topLevel;
    if (top.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            'Belum ada komentar. Jadilah yang pertama membalas.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final currentUserId = AuthService.currentUser.value?.id;
    final isPostOwner = controller.isOwner;

    return Column(
      children: [
        for (final comment in top) ...[
          ForumCommentTile(
            comment: comment,
            canReply: controller.isAuthed,
            canDelete: _canDelete(comment, currentUserId, isPostOwner),
            canMarkBest:
                isPostOwner && !comment.isBestAnswer && comment.parentId == null,
            onAuthorTap: comment.author == null
                ? null
                : () => controller.openAuthor(comment.author!),
            onReply: () => controller.setReplyTarget(comment),
            onDelete: () => controller.confirmDeleteComment(comment),
            onMarkBest: () => controller.markBestAnswer(comment),
            onUpvote: () => controller.voteComment(comment, 1),
            onDownvote: () => controller.voteComment(comment, -1),
          ),
          for (final reply in controller.repliesFor(comment.id))
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 8),
              child: ForumCommentTile(
                comment: reply,
                isReply: true,
                canDelete: _canDelete(reply, currentUserId, isPostOwner),
                onAuthorTap: reply.author == null
                    ? null
                    : () => controller.openAuthor(reply.author!),
                onDelete: () => controller.confirmDeleteComment(reply),
                onUpvote: () => controller.voteComment(reply, 1),
                onDownvote: () => controller.voteComment(reply, -1),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  bool _canDelete(ForumComment comment, String? currentUserId, bool isPostOwner) {
    if (!controller.isAuthed) return false;
    final authorId = comment.author?.id?.toString();
    if (authorId == null || currentUserId == null) return false;
    return authorId == currentUserId || isPostOwner;
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.controller, required this.onReport});

  final ForumDetailController controller;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final items = <PopupMenuItem<String>>[];
    if (controller.isOwner) {
      items.add(const PopupMenuItem(
        value: 'hapus',
        child: Row(
          children: [
            Icon(Icons.delete_outline, size: 19, color: AppColors.danger),
            SizedBox(width: 10),
            Text('Hapus',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.danger)),
          ],
        ),
      ));
    } else if (controller.isAuthed) {
      items.add(const PopupMenuItem(
        value: 'lapor',
        child: Row(
          children: [
            Icon(Icons.flag_outlined, size: 19, color: AppColors.textSecondary),
            SizedBox(width: 10),
            Text('Laporkan', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'hapus') {
          controller.confirmDeletePost();
        } else if (value == 'lapor') {
          onReport();
        }
      },
      itemBuilder: (_) => items,
    );
  }
}

/// Pinned comment composer (images ≤ 3, reply target banner, send button).
class _Composer extends StatelessWidget {
  const _Composer({required this.controller});

  final ForumDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.replyTarget.value != null)
              _ReplyBanner(
                name: controller.replyTarget.value!.author?.name ?? 'komentar',
                onCancel: controller.clearReplyTarget,
              ),
            if (controller.commentImages.isNotEmpty) ...[
              ForumPickedImages(
                files: controller.commentImages,
                onRemove: controller.removeCommentImage,
                max: ForumDetailController.maxCommentImages,
                size: 56,
                addLabel: '',
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Tambah foto',
                  onPressed: controller.commentImages.length >=
                          ForumDetailController.maxCommentImages
                      ? null
                      : controller.pickCommentImages,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_photo_alternate_outlined,
                      size: 24, color: AppColors.primary),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: AppTextField(
                    label: 'Komentar',
                    controller: controller.commentController,
                    hint: 'Tulis komentar atau balasan...',
                    maxLines: 4,
                    minLines: 2,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: controller.canSend.value
                        ? controller.sendComment
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: controller.canSend.value
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: controller.isSending.value
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded,
                              size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyBanner extends StatelessWidget {
  const _ReplyBanner({required this.name, required this.onCancel});

  final String name;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4, right: 4),
      decoration: BoxDecoration(
        color: AppColors.softSky,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Membalas $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark),
            ),
          ),
          InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child:
                  Icon(Icons.close, size: 15, color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// Guest variant of the composer (FR-03.1.5 guest gate).
class _GuestBar extends StatelessWidget {
  const _GuestBar({required this.controller});

  final ForumDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: SafeArea(
        top: false,
        child: SecondaryButton(
          label: 'Masuk untuk ikut berdiskusi',
          icon: Icons.login_rounded,
          onPressed: controller.openLogin,
        ),
      ),
    );
  }
}
