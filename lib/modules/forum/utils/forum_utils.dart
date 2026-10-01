import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';

import '../../../core/models/forum_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../routes/app_routes.dart';

/// `content_html` â†’ plain text. The dependency set has no HTML renderer, so
/// post/comment bodies are stripped of tags before display (API.md Â§6.3/Â§6.4).
String stripHtml(String? html) {
  if (html == null || html.isEmpty) return '';
  var text = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>|</div>|</li>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  return text.trim();
}

/// First usable line of a post body (list excerpt fallback).
String excerptOf(ForumPost post, {int max = 140}) {
  final raw = (post.excerpt != null && post.excerpt!.trim().isNotEmpty)
      ? post.excerpt!
      : stripHtml(post.contentHtml);
  if (raw.isEmpty) return '';
  return raw.length > max ? '${raw.substring(0, max).trim()}â€¦' : raw;
}

/// `GET /api/forum/posts` â†’ `data` list (Â§6.2). Tolerant of shape changes.
List<ForumPost> parseForumPosts(dynamic raw) {
  if (raw is! List) return const [];
  final out = <ForumPost>[];
  for (final item in raw) {
    try {
      out.add(ForumPost.fromJson(item));
    } catch (_) {
      // skip malformed row instead of failing the whole page
    }
  }
  return out;
}

/// `GET /api/forum/categories` â†’ `data` list (Â§6.1). Accepts either a plain
/// list or a wrapper map (`categories` / `data`) since Â§6.1 has no sample body.
List<ForumCategory> parseForumCategories(dynamic raw) {
  dynamic list = raw;
  if (raw is Map<String, dynamic>) {
    list = raw['categories'] ?? raw['data'] ?? const [];
  }
  if (list is! List) return const [];
  final out = <ForumCategory>[];
  for (final item in list) {
    try {
      out.add(ForumCategory.fromJson(item));
    } catch (_) {
      // skip malformed row
    }
  }
  return out;
}

/// `GET /api/scans` â†’ summary list (Â§4.2), keeping `done` scans only.
List<T> parseList<T>(dynamic raw, T Function(dynamic) fromJson) {
  if (raw is! List) return const [];
  final out = <T>[];
  for (final item in raw) {
    try {
      out.add(fromJson(item));
    } catch (_) {
      // skip malformed row
    }
  }
  return out;
}

/// Guest gate for every auth-only forum action (FR-05.2.1 / FR-05.3.1).
/// Returns `true` when the user continued to the login screen.
Future<bool> showLoginPrompt() async {
  final goLogin = await Get.dialog<bool>(
    Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration:
                  const BoxDecoration(color: AppColors.softSky, shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline, size: 26, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            const Text(
              'Masuk dulu ya',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fitur komunitas ini perlu akun Ngingu agar diskusi tetap aman dan terpercaya.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Masuk',
              onPressed: () => Get.back(result: true),
            ),
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text(
                'Nanti saja',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (goLogin == true) {
    Get.toNamed(Routes.login);
    return true;
  }
  return false;
}

/// Image picker capped at [limit] (Â§2.7: 5/post, 3/comment), compressed
/// client-side to the NFR-01.7 budget before upload.
Future<List<File>> pickForumImages({required int limit, int current = 0}) async {
  final remaining = limit - current;
  if (remaining <= 0) return const [];
  try {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return const [];
    final files = <File>[];
    for (final x in picked.take(remaining)) {
      files.add(await compressImage(File(x.path)));
    }
    return files;
  } catch (_) {
    AppTheme.error('Gagal', 'Foto tidak dapat dipilih. Coba lagi.');
    return const [];
  }
}

/// `images[]` multipart entries for forum uploads (Â§2.7 photo limits).
Future<List<MultipartFile>> toMultipartFiles(List<File> files) async {
  final out = <MultipartFile>[];
  for (final f in files) {
    out.add(await MultipartFile.fromFile(f.path));
  }
  return out;
}

/// Small numeric footer label (1.2k).
String compactCount(int value) {
  if (value < 1000) return '$value';
  if (value < 100000) return '${(value / 1000).toStringAsFixed(1)}k';
  return '${(value / 1000).floor()}k';
}
