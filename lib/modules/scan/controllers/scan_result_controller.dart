import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/scan_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../scan_shared.dart';
import 'scan_history_controller.dart';

/// Detail hasil scan `GET /api/scans/{id}?gradcam=1` (API.md §4.3).
class ScanResultController extends GetxController {
  static const int _maxPollAttempts = 6;

  late final String scanId;

  final Rxn<ScanDetail> detail = Rxn<ScanDetail>();
  final RxBool isLoading = false.obs;
  final RxBool isPolling = false.obs;
  final RxBool isExporting = false.obs;
  final RxBool isDeleting = false.obs;
  final RxBool showGradcam = true.obs;
  final RxString errorMessage = ''.obs;
  final RxBool canRetryPoll = false.obs;

  CancelToken? _token;
  bool _closed = false;

  @override
  void onInit() {
    super.onInit();
    scanId = scanIdFromArguments();
    load();
  }

  /// Muat hasil; bila masih `pending`/`processing` → long-poll sampai selesai.
  Future<void> load({bool showLoading = true}) async {
    if (showLoading) isLoading.value = true;
    errorMessage.value = '';
    canRetryPoll.value = false;
    final res = await ApiClient.get<ScanDetail>(
      '/scans/$scanId',
      query: {'gradcam': 1},
      parse: ScanDetail.fromJson,
    );
    if (_closed) return;
    isLoading.value = false;
    if (res.success && res.data != null) {
      detail.value = res.data;
      if (res.data!.isProcessing) await _pollUntilSettled();
      return;
    }
    errorMessage.value = res.errorText;
  }

  Future<void> _pollUntilSettled() async {
    if (isPolling.value || _closed) return;
    isPolling.value = true;
    _token = CancelToken();
    var attempts = 0;
    try {
      while (!_closed && attempts < _maxPollAttempts) {
        attempts++;
        final res = await ApiClient.get<ScanDetail>(
          '/scans/$scanId',
          longPoll: true,
          query: {'wait': AppConfig.scanWaitSeconds, 'gradcam': 1},
          parse: ScanDetail.fromJson,
          cancelToken: _token,
        );
        if (_closed) return;
        if (res.success && res.data != null) {
          detail.value = res.data;
          if (!res.data!.isProcessing) return;
        }
      }
      if (!_closed && detail.value?.isProcessing == true) canRetryPoll.value = true;
    } finally {
      if (!_closed) isPolling.value = false;
    }
  }

  // ── aksi ─────────────────────────────────────────────────────────────────

  /// Buka ensiklopedia penyakit (API.md §5.2 — `{id, slug}`).
  void openDisease() {
    final disease = detail.value?.disease;
    if (disease == null) return;
    Get.toNamed(
      Routes.diseaseDetail,
      arguments: {'id': disease.id, 'slug': disease.slug},
    );
  }

  /// `GET /api/scans/{id}/export-pdf` (API.md §4.5) → share sheet.
  Future<void> exportPdf() async {
    if (isExporting.value) return;
    isExporting.value = true;
    try {
      await downloadAndShare(
        path: '/scans/$scanId/export-pdf',
        saveName: 'hasil-scan-$scanId.pdf',
        title: 'Hasil Scan Ngingu',
      );
    } catch (_) {
      AppTheme.error('Gagal', 'Export PDF gagal. Coba lagi.');
    } finally {
      isExporting.value = false;
    }
  }

  /// `DELETE /api/scans/{id}` (API.md §4.4) → kembali ke tab scan.
  Future<void> deleteScan() async {
    if (isDeleting.value) return;
    final confirmed = await confirmDestructive(
      title: 'Hapus scan ini?',
      message: 'Foto dan hasil prediksi akan dihapus permanen.',
    );
    if (!confirmed) return;
    isDeleting.value = true;
    final res = await ApiClient.delete<dynamic>('/scans/$scanId');
    isDeleting.value = false;
    if (res.success) {
      if (Get.isRegistered<ScanHistoryController>()) {
        Get.find<ScanHistoryController>()
            .items
            .removeWhere((s) => s.scanId == scanId);
      }
      AppTheme.success('Berhasil', 'Scan berhasil dihapus.');
      Get.back();
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  /// Kembali ke tab Scan untuk memulai scan baru.
  void scanAgain() => Get.back();

  @override
  void onClose() {
    _closed = true;
    _token?.cancel();
    super.onClose();
  }
}
