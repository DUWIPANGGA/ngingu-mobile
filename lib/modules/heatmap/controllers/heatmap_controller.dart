import 'package:get/get.dart';

import '../../../core/models/alert_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';

/// Peta sebaran penyakit (FR-07.3).
///
/// Endpoints (API.md §7.11 + §8.7):
///  * `GET /api/map/heatmap?days=7|30|90` — titik sebaran per provinsi.
///  * `GET /api/outbreaks` — feed alert wabah aktif (dipakai untuk daftar
///    "Laporan Terbaru" di bawah peta).
class HeatmapController extends GetxController {
  /// Opsi rentang waktu yang didukung param `days` (API.md §7.11).
  static const List<int> rangeOptions = [7, 30, 90];

  // ── heatmap state ─────────────────────────────────────────────────────────
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = Rxn<String>();
  final points = <HeatmapPoint>[].obs;
  final selectedPoint = Rxn<HeatmapPoint>();
  final selectedRange = 30.obs;

  // ── outbreak list state ──────────────────────────────────────────────────
  final outbreaksLoading = false.obs;
  final outbreaks = <Outbreak>[].obs;
  final outbreaksError = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  /// Re-fetch heatmap + outbreak list (refresh action / retry).
  Future<void> fetchAll() async {
    await Future.wait([fetchHeatmap(), fetchOutbreaks()]);
  }

  void clearSelection() => selectedPoint.value = null;

  void selectPoint(HeatmapPoint point) => selectedPoint.value = point;

  /// Ubah rentang `days` lalu muat ulang heatmap.
  Future<void> setRange(int days) async {
    if (selectedRange.value == days) return;
    selectedRange.value = days;
    selectedPoint.value = null;
    await fetchHeatmap();
  }

  Future<void> fetchHeatmap() async {
    isLoading.value = true;
    final res = await ApiClient.get<List<HeatmapPoint>>(
      '/map/heatmap',
      query: {'days': selectedRange.value},
      parse: _parsePoints,
    );
    isLoading.value = false;
    if (res.success) {
      points.assignAll(res.data ?? const <HeatmapPoint>[]);
      hasError.value = false;
      errorMessage.value = null;
      final selected = selectedPoint.value;
      if (selected != null && !points.contains(selected)) {
        selectedPoint.value = null;
      }
    } else {
      hasError.value = true;
      errorMessage.value = res.errorText;
    }
  }

  Future<void> fetchOutbreaks() async {
    outbreaksLoading.value = true;
    final res = await ApiClient.get<List<Outbreak>>(
      '/outbreaks',
      parse: (json) =>
          json is List ? json.map(Outbreak.fromJson).toList() : const <Outbreak>[],
    );
    outbreaksLoading.value = false;
    if (res.success) {
      outbreaks.assignAll(res.data ?? const <Outbreak>[]);
      outbreaksError.value = null;
    } else {
      outbreaksError.value = res.errorText;
    }
  }

  // ── navigation ───────────────────────────────────────────────────────────

  /// Heatmap payload (API.md §7.11) hanya memuat `top_disease` (nama, tanpa
  /// id) — id penyakit dicocokkan dari feed `/api/outbreaks`.
  int? resolveDiseaseId(HeatmapPoint? point) {
    final name = (point?.topDisease ?? '').trim();
    if (name.isEmpty || outbreaks.isEmpty) return null;
    for (final o in outbreaks) {
      final other = (o.diseaseName ?? '').trim();
      if (other.isNotEmpty && other.toLowerCase() == name.toLowerCase()) {
        return o.diseaseId;
      }
    }
    return null;
  }

  void openPointDisease() {
    final id = resolveDiseaseId(selectedPoint.value);
    if (id == null) {
      AppTheme.error('Tidak tersedia', 'Detail penyakit belum dapat ditemukan.');
      return;
    }
    Get.toNamed(Routes.diseaseDetail, arguments: {'id': id});
  }

  void openOutbreak(Outbreak outbreak) {
    if (outbreak.diseaseId == null) {
      AppTheme.error('Tidak tersedia', 'Detail penyakit belum dapat ditemukan.');
      return;
    }
    Get.toNamed(Routes.diseaseDetail, arguments: {'id': outbreak.diseaseId});
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  /// Heatmap payload tidak punya field severity → tingkat diambil dari
  /// jumlah kasus (palet SeverityBadge: ringan/sedang/berat/kritis).
  static String severityForCases(int cases) {
    if (cases >= 20) return 'kritis';
    if (cases >= 10) return 'berat';
    if (cases >= 5) return 'sedang';
    return 'ringan';
  }

  /// Ukuran marker menyesuaikan jumlah kasus.
  static double markerSize(int cases) {
    if (cases >= 20) return 46;
    if (cases >= 10) return 40;
    if (cases >= 5) return 34;
    return 28;
  }

  static List<HeatmapPoint> _parsePoints(dynamic json) {
    if (json is! List) return const <HeatmapPoint>[];
    return json.map(HeatmapPoint.fromJson).toList();
  }
}
