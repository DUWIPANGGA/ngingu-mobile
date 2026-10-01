import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/scan_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../scan_shared.dart';

/// Riwayat scan `GET /api/scans` (API.md §4.2) — paginasi + filter status
/// lokal, hapus per-item, dan export CSV/PDF (API.md §4.6).
class ScanHistoryController extends GetxController {
  static const int _perPage = 15;
  static const int _loadMoreThreshold = 400;

  final RxList<ScanSummary> items = <ScanSummary>[].obs;
  final RxString filter = 'all'.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isExporting = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt total = 0.obs;

  final ScrollController scrollController = ScrollController();

  int _page = 1;
  int _lastPage = 1;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    if (AuthService.isAuthed) refreshList();
  }

  /// Item yang lolos chip filter (API.md §4.2 tidak mendukung query `status`).
  List<ScanSummary> get visibleItems {
    switch (filter.value) {
      case 'pending':
        return items
            .where((s) => s.status == 'pending' || s.status == 'processing')
            .toList();
      case 'done':
        return items.where((s) => s.status == 'done').toList();
      case 'failed':
        return items.where((s) => s.status == 'failed').toList();
      default:
        return items.toList();
    }
  }

  void setFilter(String value) {
    if (filter.value == value) return;
    filter.value = value;
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) {
      loadMore();
    }
  }

  Future<void> refreshList() async {
    _page = 1;
    await _fetch(1, append: false);
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value) return;
    if (_page >= _lastPage) return;
    await _fetch(_page + 1, append: true);
  }

  Future<void> _fetch(int page, {required bool append}) async {
    if (append) {
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
      errorMessage.value = '';
    }
    final res = await ApiClient.get<List<ScanSummary>>(
      '/scans',
      query: {'page': page, 'per_page': _perPage},
      parse: (json) => (json as List).map(ScanSummary.fromJson).toList(),
    );
    if (append) {
      isLoadingMore.value = false;
    } else {
      isLoading.value = false;
    }
    if (res.success && res.data != null) {
      _page = res.currentPage;
      _lastPage = res.lastPage < 1 ? 1 : res.lastPage;
      total.value = res.total;
      if (append) {
        items.addAll(res.data!);
      } else {
        items.assignAll(res.data!);
      }
    } else if (!append) {
      errorMessage.value = res.errorText;
    }
  }

  /// `DELETE /api/scans/{id}` (API.md §4.4).
  Future<void> deleteScan(ScanSummary summary) async {
    final confirmed = await confirmDestructive(
      title: 'Hapus scan ini?',
      message: 'Foto dan hasil prediksi akan dihapus permanen.',
    );
    if (!confirmed) return;
    final res = await ApiClient.delete<dynamic>('/scans/${summary.scanId}');
    if (res.success) {
      items.removeWhere((s) => s.scanId == summary.scanId);
      if (total.value > 0) total.value = total.value - 1;
      AppTheme.success('Berhasil', 'Scan berhasil dihapus.');
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  /// `GET /api/scans/export?format=csv|pdf` (API.md §4.6) → share sheet.
  Future<void> exportHistory(String format) async {
    if (isExporting.value) return;
    isExporting.value = true;
    try {
      await downloadAndShare(
        path: '/scans/export',
        saveName: 'riwayat-scan.$format',
        title: 'Riwayat Scan Ngingu',
        query: {'format': format},
      );
    } catch (_) {
      AppTheme.error('Gagal', 'Export gagal. Coba lagi.');
    } finally {
      isExporting.value = false;
    }
  }

  void goToLogin() => Get.toNamed(Routes.login);

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
