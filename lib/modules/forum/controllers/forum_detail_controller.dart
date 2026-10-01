import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

import '../../../core/models/forum_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../routes/app_routes.dart';
import '../utils/forum_utils.dart';

/// Detail state for one forum post + its comments (API.md Â§6.4â€“Â§6.15).
class ForumDetailController extends GetxController {
  static const maxCommentImages = 3; // FR-05.3.2

  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  final post = Rxn<ForumPost>();

  /// Flat comment store: top-level items (`parentId == null`) plus their
  /// replies, deduplicated by id.
  final comments = <ForumComment>[].obs;

  // â”€â”€ composer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final commentController = TextEditingController();
  final commentImages = <File>[].obs;
  final replyTarget = Rxn<ForumComment>();
  final isSending = false.obs;
  final canSend = false.obs;

  int postId = 0;
  bool _busy = false;

  bool get isAuthed => AuthService.isAuthed;

  bool get isOwner {
    final p = post.value;
    final user = AuthService.currentUser.value;
    if (p?.author?.id == null || user == null) return false;
    return p!.author!.id!.toString() == user.id;
  }

  List<ForumComment> get topLevel =>
      comments.where((c) => c.parentId == null).toList();

  List<ForumComment> repliesFor(int commentId) =>
      comments.where((c) => c.parentId == commentId).toList();

  int get commentsCount => post.value?.commentsCount ?? 0;

  @override
  void onInit() {
    super.onInit();
    commentController.addListener(_onComposerChanged);
    _readArguments();
    loadDetail();
  }

  @override
  void onClose() {
    commentController.removeListener(_onComposerChanged);
    commentController.dispose();
    super.onClose();
  }

  void _onComposerChanged() {
    canSend.value =
        commentController.text.trim().isNotEmpty && !isSending.value;
  }

  void _readArguments() {
    final args = Get.arguments;
    if (args is Map) {
      final raw = args['id'] ?? args['postId'];
      postId = (raw as num?)?.toInt() ?? 0;
    } else if (args is num) {
      postId = args.toInt();
    }
  }

  // â”€â”€ load (Â§6.4) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> loadDetail() async {
    if (postId <= 0) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Diskusi tidak ditemukan.';
      return;
    }
    if (comments.isEmpty) isLoading.value = true;
    final res = await ApiClient.get<ForumPost>(
      '/forum/posts/$postId',
      parse: (raw) => ForumPost.fromJson(raw, withDetail: true),
    );
    if (res.success && res.data != null) {
      post.value = res.data;
      _setComments(res.data!.comments);
      hasError.value = false;
      errorMessage.value = '';
    } else {
      hasError.value = true;
      errorMessage.value = res.errorText;
    }
    isLoading.value = false;
  }

  Future<void> retry() => loadDetail();

  void _setComments(List<ForumComment> raw) {
    final flat = <ForumComment>[];
    final seen = <int>{};

    void push(ForumComment comment, int? forcedParent) {
      var item = comment;
      if (forcedParent != null && item.parentId == null) {
        item = _withParent(item, forcedParent);
      }
      if (!seen.add(item.id)) return;
      flat.add(item);
    }

    for (final comment in raw) {
      push(comment, null);
      for (final reply in comment.replies) {
        push(reply, comment.id);
      }
    }
    comments.assignAll(flat);
  }

  ForumComment _withParent(ForumComment c, int parentId) => ForumComment(
        id: c.id,
        parentId: parentId,
        author: c.author,
        contentHtml: c.contentHtml,
        images: c.images,
        votesCount: c.votesCount,
        isBestAnswer: c.isBestAnswer,
        mentionUsers: c.mentionUsers,
        createdAt: c.createdAt,
        myVote: c.myVote,
      );

  void _replaceComment(ForumComment updated) {
    final index = comments.indexWhere((c) => c.id == updated.id);
    if (index >= 0) comments[index] = updated;
  }

  // â”€â”€ post interactions (Â§6.6â€“Â§6.10) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  bool _guardAuth() {
    if (AuthService.isAuthed) return true;
    showLoginPrompt();
    return false;
  }

  /// Optimistic post vote â€” `value` 1 / -1, tapping the active one sends 0.
  Future<void> vote(int value) async {
    if (!_guardAuth() || _busy) return;
    final current = post.value;
    if (current == null) return;

    final previous = current.viewer.myVote;
    final next = previous == value ? 0 : value;
    final optimisticCount = current.votesCount + (next - previous);
    final snapshot = current;

    post.value = current.copyWith(
      votesCount: optimisticCount,
      viewer: ViewerState(
        isBookmarked: current.viewer.isBookmarked,
        isFollowing: current.viewer.isFollowing,
        myVote: next,
      ),
    );

    _busy = true;
    final res = await ApiClient.post<dynamic>(
      '/forum/posts/$postId/vote',
      data: {'value': next},
      parse: VoteResult.fromJson,
    );
    _busy = false;

    if (res.success && res.data is VoteResult) {
      final result = res.data as VoteResult;
      post.value = post.value?.copyWith(
        votesCount: result.votesCount,
        viewer: ViewerState(
          isBookmarked: post.value!.viewer.isBookmarked,
          isFollowing: post.value!.viewer.isFollowing,
          myVote: result.myVote,
        ),
      );
    } else {
      post.value = snapshot;
      AppTheme.error('Gagal', res.errorText);
    }
  }

  Future<void> toggleBookmark() async {
    if (!_guardAuth() || _busy) return;
    final current = post.value;
    if (current == null) return;

    final next = !current.viewer.isBookmarked;
    final snapshot = current;
    post.value = current.copyWith(
      viewer: ViewerState(
        isBookmarked: next,
        isFollowing: current.viewer.isFollowing,
        myVote: current.viewer.myVote,
      ),
    );

    _busy = true;
    final res = await ApiClient.post<dynamic>(
      '/forum/posts/$postId/bookmark',
    );
    _busy = false;

    if (res.success) {
      final server = _toggleValue(res.data, 'is_bookmarked', next);
      final p = post.value;
      if (p != null) {
        post.value = p.copyWith(
          viewer: ViewerState(
            isBookmarked: server,
            isFollowing: p.viewer.isFollowing,
            myVote: p.viewer.myVote,
          ),
        );
      }
      AppTheme.success(
          'Berhasil', server ? 'Diskusi disimpan' : 'Bookmark dihapus');
    } else {
      post.value = snapshot;
      AppTheme.error('Gagal', res.errorText);
    }
  }

  Future<void> toggleFollow() async {
    if (!_guardAuth() || _busy) return;
    final current = post.value;
    if (current == null) return;

    final next = !current.viewer.isFollowing;
    final snapshot = current;
    post.value = current.copyWith(
      viewer: ViewerState(
        isBookmarked: current.viewer.isBookmarked,
        isFollowing: next,
        myVote: current.viewer.myVote,
      ),
    );

    _busy = true;
    final res = await ApiClient.post<dynamic>(
      '/forum/posts/$postId/follow',
    );
    _busy = false;

    if (res.success) {
      final server = _toggleValue(res.data, 'is_following', next);
      final p = post.value;
      if (p != null) {
        post.value = p.copyWith(
          viewer: ViewerState(
            isBookmarked: p.viewer.isBookmarked,
            isFollowing: server,
            myVote: p.viewer.myVote,
          ),
        );
      }
      AppTheme.success('Berhasil',
          server ? 'Mengikuti diskusi ini' : 'Berhenti mengikuti diskusi');
    } else {
      post.value = snapshot;
      AppTheme.error('Gagal', res.errorText);
    }
  }

  /// Â§6.8/Â§6.9 return `{is_bookmarked}` / `{is_following}`; fall back to the
  /// optimistic value when the server replies 204 without a body.
  bool _toggleValue(dynamic data, String key, bool fallback) {
    if (data is Map<String, dynamic> && data[key] is bool) {
      return data[key] as bool;
    }
    return fallback;
  }

  Future<void> confirmDeletePost() async {
    if (!_guardAuth() || !isOwner) return;
    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration:
                    const BoxDecoration(color: AppColors.softRed, shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline,
                    size: 26, color: AppColors.danger),
              ),
              const SizedBox(height: 14),
              const Text(
                'Hapus diskusi ini?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pertanyaan beserta komentarnya akan hilang permanen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(result: true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Hapus',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Batal',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;

    final res = await ApiClient.delete<dynamic>('/forum/posts/$postId');
    if (res.success) {
      AppTheme.success('Berhasil', 'Diskusi dihapus');
      Get.back(result: true);
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  /// Â§6.10 â€” `reason`: spam | konten_kasar | hoax | lainnya.
  Future<void> reportPost(String reason) async {
    if (!_guardAuth()) return;
    final res = await ApiClient.post<dynamic>(
      '/forum/posts/$postId/report',
      data: {'reason': reason},
    );
    if (res.success) {
      AppTheme.success('Berhasil', 'Laporan dikirim ke moderator');
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  // â”€â”€ comments (Â§6.11â€“Â§6.15) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void setReplyTarget(ForumComment comment) {
    replyTarget.value = comment;
  }

  void clearReplyTarget() {
    replyTarget.value = null;
  }

  Future<void> pickCommentImages() async {
    if (!_guardAuth()) return;
    final picked = await pickForumImages(
      limit: maxCommentImages,
      current: commentImages.length,
    );
    commentImages.addAll(picked);
  }

  void removeCommentImage(int index) {
    if (index < 0 || index >= commentImages.length) return;
    commentImages.removeAt(index);
  }

  Future<void> sendComment() async {
    if (!_guardAuth()) return;
    final text = commentController.text.trim();
    if (text.isEmpty || isSending.value) return;

    final target = replyTarget.value;
    final files = List<File>.from(commentImages);
    final payload = <String, dynamic>{
      // API.md Â§6.11 uses `content_html`; `body` kept as a lenient alias.
      'content_html': text,
      'body': text,
      if (target != null) 'parent_id': target.id,
    };

    isSending.value = true;
    canSend.value = false;

    ApiResult<dynamic> res;
    if (files.isEmpty) {
      res = await ApiClient.post<dynamic>(
        '/forum/posts/$postId/comments',
        data: payload,
      );
    } else {
      final form = FormData.fromMap({
        ...payload,
        'images[]': await toMultipartFiles(files),
      });
      res = await ApiClient.postMultipart<dynamic>(
        '/forum/posts/$postId/comments',
        formData: form,
      );
    }

    isSending.value = false;
    canSend.value = commentController.text.trim().isNotEmpty;

    if (res.success) {
      commentController.clear();
      commentImages.clear();
      replyTarget.value = null;

      final data = res.data;
      ForumComment? created;
      if (data is Map<String, dynamic>) {
        try {
          created = ForumComment.fromJson(data);
        } catch (_) {
          created = null;
        }
      }
      if (created != null && created.id > 0) {
        if (target != null && created.parentId == null) {
          created = _withParent(created, target.id);
        }
        comments.add(created);
        final p = post.value;
        if (p != null) {
          post.value = p.copyWith(commentsCount: p.commentsCount + 1);
        }
      } else {
        await loadDetail();
      }
      AppTheme.success('Berhasil', 'Komentar terkirim');
    } else {
      AppTheme.error(
        'Gagal',
        res.statusCode == 429 && res.message.isEmpty
            ? 'Terlalu banyak permintaan. Coba lagi dalam ${res.retryAfter ?? 60} detik.'
            : res.errorText,
      );
    }
  }

  Future<void> voteComment(ForumComment comment, int value) async {
    if (!_guardAuth() || _busy) return;
    final previous = comment.myVote;
    final next = previous == value ? 0 : value;
    final snapshot = comment;

    _replaceComment(comment.copyWith(
      votesCount: comment.votesCount + (next - previous),
      myVote: next,
    ));

    _busy = true;
    final res = await ApiClient.post<dynamic>(
      '/forum/comments/${comment.id}/vote',
      data: {'value': next},
      parse: VoteResult.fromJson,
    );
    _busy = false;

    if (res.success && res.data is VoteResult) {
      final result = res.data as VoteResult;
      _replaceComment(comment.copyWith(
        votesCount: result.votesCount,
        myVote: result.myVote,
      ));
    } else {
      _replaceComment(snapshot);
      AppTheme.error('Gagal', res.errorText);
    }
  }

  Future<void> confirmDeleteComment(ForumComment comment) async {
    if (!_guardAuth()) return;
    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Hapus komentar ini?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Komentar dan balasannya akan hilang.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Batal',
                      onPressed: () => Get.back(result: false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DangerButton(
                      label: 'Hapus',
                      onPressed: () => Get.back(result: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;

    final res =
        await ApiClient.delete<dynamic>('/forum/comments/${comment.id}');
    if (res.success) {
      final removed = [
        comment.id,
        ...comments.where((c) => c.parentId == comment.id).map((c) => c.id),
      ];
      comments.removeWhere((c) => removed.contains(c.id));
      final p = post.value;
      if (p != null) {
        final decrement = removed.length;
        post.value = p.copyWith(
          commentsCount:
              p.commentsCount - decrement > 0 ? p.commentsCount - decrement : 0,
        );
      }
      AppTheme.success('Berhasil', 'Komentar dihapus');
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  /// Â§6.15 â€” only the post author can mark one best answer.
  Future<void> markBestAnswer(ForumComment comment) async {
    if (!_guardAuth() || !isOwner) return;
    final res = await ApiClient.post<dynamic>(
      '/forum/comments/${comment.id}/best',
    );
    if (res.success) {
      final updated = <ForumComment>[];
      for (final c in comments) {
        updated.add(c.copyWith(isBestAnswer: c.id == comment.id));
      }
      comments.assignAll(updated);
      AppTheme.success('Berhasil', 'Jawaban terbaik ditandai');
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  // â”€â”€ navigation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void openAuthor(ForumAuthor author) {
    if (author.id == null) return;
    Get.toNamed(Routes.publicProfile, arguments: {'id': author.id});
  }

  void openLinkedScan() {
    final scanId =
        post.value?.linkedScan?.scanId ?? post.value?.linkedScanId;
    if (scanId == null || scanId.isEmpty) return;
    Get.toNamed(Routes.scanResult, arguments: {'scanId': scanId});
  }

  void openLogin() => Get.toNamed(Routes.login);
}
