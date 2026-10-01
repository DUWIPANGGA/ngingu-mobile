import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/models/pond_model.dart';
import '../../../core/network/api_client.dart';
import '../../../routes/app_routes.dart';
import '../../main_navigation/controllers/main_navigation_controller.dart';

/// Laporan kesehatan tambak — `GET /api/ponds/{id}/health-report`
/// (API.md §7.6: pond, health_score, trend[], repeat_disease_alert,
/// last_scan) + `GET /api/ponds/{id}` (detail tambak, terbaik-kemungkinan
/// untuk lokasi/luas/jenis ikan di header).
class PondHealthController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final report = Rxn<HealthReport>();
  final pond = Rxn<Pond>();

  String? pondId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) pondId = args['id']?.toString();
    fetch();
  }

  Future<void> fetch() async {
    if (pondId == null || pondId!.isEmpty) {
      errorMessage.value = 'Tambak tidak ditemukan.';
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    errorMessage.value = null;

    final res = await ApiClient.get<HealthReport>(
      '/ponds/$pondId/health-report',
      parse: HealthReport.fromJson,
    );
    if (!res.success || res.data == null) {
      isLoading.value = false;
      errorMessage.value = res.statusCode == 401
          ? 'Sesi berakhir. Silakan masuk kembali.'
          : res.errorText;
      return;
    }
    report.value = res.data;
    isLoading.value = false;

    // Detail tambak untuk lokasi/luas — opsional, kegagalan diabaikan.
    final pondRes = await ApiClient.get<Pond>(
      '/ponds/$pondId',
      parse: Pond.fromJson,
    );
    if (pondRes.success && pondRes.data != null) {
      pond.value = pondRes.data;
    }
  }

  void openDisease(int? diseaseId) {
    if (diseaseId == null) return;
    Get.toNamed(Routes.diseaseDetail, arguments: {'id': diseaseId});
  }

  void openScan() {
    final scanId = report.value?.lastScan?.scanId;
    if (scanId == null || scanId.isEmpty) return;
    Get.toNamed(Routes.scanResult, arguments: {'scanId': scanId});
  }

  /// CTA "Scan Baru" → shell utama, tab Scan (index 1).
  void startScan() {
    Get.offAllNamed(Routes.mainNavigation);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<MainNavigationController>()) {
        Get.find<MainNavigationController>().changeTab(1);
      }
    });
  }
}
