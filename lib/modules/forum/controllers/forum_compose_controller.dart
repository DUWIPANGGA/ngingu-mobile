import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

import '../../../core/models/forum_model.dart';
import '../../../core/models/scan_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../utils/forum_utils.dart';

/// Compose state for a new question (FR-05.2, API.md Â§6.3).
class ForumComposeController extends GetxController {
  static const minBodyLength = 10;
  static const maxImages = 5; // FR-05.2.1 / Â§2.7

  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  final categories = <ForumCategory>[].obs;
  final isLoadingCategories = true.obs;
  final selectedCategory = Rxn<ForumCategory>();

  final titleError = Rxn<String>();
  final bodyError = Rxn<String>();
  final categoryError = Rxn<String>();

  /// `GET /api/scans?status=done&per_page=20` picker (FR-05.2.3).
  final scans = <ScanSummary>[].obs;
  final isLoadingScans = false.obs;
  final selectedScan = Rxn<ScanSummary>();

  final images = <File>[].obs;
  final isSubmitting = false.obs;

  bool get isAuthed => AuthService.isAuthed;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    if (AuthService.isAuthed) loadScans();
  }

  @override
  void onClose() {
    titleController.dispose();
    bodyController.dispose();
    super.onClose();
  }

  // â”€â”€ data â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> loadCategories() async {
    isLoadingCategories.value = true;
    final res = await ApiClient.get<dynamic>(
      '/forum/categories',
      parse: (raw) => raw,
    );
    if (res.success) {
      categories.assignAll(parseForumCategories(res.data));
    }
    isLoadingCategories.value = false;
  }

  Future<void> loadScans() async {
    if (!AuthService.isAuthed) return;
    isLoadingScans.value = true;
    final res = await ApiClient.get<List<ScanSummary>>(
      '/scans',
      // Â§4.2 documents no `status` filter â€” the client filters locally too.
      query: {'status': 'done', 'per_page': 20},
      parse: (raw) => parseList(raw, ScanSummary.fromJson),
    );
    if (res.success) {
      final done = (res.data ?? const <ScanSummary>[])
          .where((s) => s.status == null || s.status == 'done')
          .toList();
      scans.assignAll(done);
    }
    isLoadingScans.value = false;
  }

  // â”€â”€ field edits â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void onTitleChanged(String _) => titleError.value = null;

  void onBodyChanged(String _) => bodyError.value = null;

  void selectCategory(ForumCategory? category) {
    selectedCategory.value = category;
    categoryError.value = null;
  }

  void clearSelectedScan() => selectedScan.value = null;

  Future<void> pickImages() async {
    final picked = await pickForumImages(
      limit: maxImages,
      current: images.length,
    );
    images.addAll(picked);
  }

  void removeImage(int index) {
    if (index < 0 || index >= images.length) return;
    images.removeAt(index);
  }

  // â”€â”€ submit (Â§6.3) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  bool _validate() {
    titleError.value = null;
    bodyError.value = null;
    categoryError.value = null;

    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    var valid = true;
    if (title.isEmpty) {
      titleError.value = 'Judul wajib diisi';
      valid = false;
    } else if (title.length < 10) {
      titleError.value = 'Judul minimal 10 karakter';
      valid = false;
    }
    if (body.length < minBodyLength) {
      bodyError.value = 'Isi minimal $minBodyLength karakter';
      valid = false;
    }
    if (selectedCategory.value?.id == null) {
      categoryError.value = 'Pilih kategori terlebih dahulu';
      valid = false;
    }
    return valid;
  }

  Future<void> submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (isSubmitting.value) return;
    if (!_validate()) return;

    final category = selectedCategory.value;
    final scan = selectedScan.value;
    final files = List<File>.from(images);

    final payload = <String, dynamic>{
      'type': 'question',
      'title': titleController.text.trim(),
      // API.md Â§6.3 field is `content_html`; `body` is kept as a lenient alias.
      'content_html': bodyController.text.trim(),
      'body': bodyController.text.trim(),
      'category_id': category!.id,
      if (scan != null && scan.scanId.isNotEmpty)
        'linked_scan_id': scan.scanId,
      if (files.isEmpty) 'image_urls': <String>[],
    };

    isSubmitting.value = true;
    ApiResult<dynamic> res;
    if (files.isEmpty) {
      res = await ApiClient.post<dynamic>('/forum/posts', data: payload);
    } else {
      final form = FormData.fromMap({
        ...payload,
        'images[]': await toMultipartFiles(files),
      });
      res = await ApiClient.postMultipart<dynamic>(
        '/forum/posts',
        formData: form,
      );
    }
    isSubmitting.value = false;

    if (res.success) {
      Get.back(result: true);
      AppTheme.success('Berhasil', 'Pertanyaan dipublikasikan');
      return;
    }

    titleError.value = res.fieldError('title');
    bodyError.value =
        res.fieldError('content_html') ?? res.fieldError('body');
    categoryError.value = res.fieldError('category_id');

    final hasInlineError = titleError.value != null ||
        bodyError.value != null ||
        categoryError.value != null;
    if (!hasInlineError || res.statusCode == 429) {
      AppTheme.error(
        'Gagal',
        res.statusCode == 429 && res.message.isEmpty
            ? 'Terlalu banyak permintaan. Coba lagi dalam ${res.retryAfter ?? 60} detik.'
            : res.errorText,
      );
    }
  }
}
