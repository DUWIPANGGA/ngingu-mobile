import 'package:get/get.dart';

import '../../../core/models/article_model.dart';
import '../../../core/models/dashboard_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../main_navigation/controllers/main_navigation_controller.dart';

/// Dashboard controller — `GET /api/dashboard` (API.md §7.1, FR-07).
class HomeController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool needsLogin = false.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<Dashboard> dashboard = Rxn<Dashboard>();
  final RxString period = '7d'.obs;

  /// Artikel edukasi terbaru (publik — tampil juga untuk tamu).
  final RxList<Article> articles = <Article>[].obs;

  /// `?period=` switcher values (API.md FR-07.4).
  static const List<String> periods = <String>['7d', '30d', '90d'];

  static String periodLabel(String value) {
    switch (value) {
      case '30d':
        return '30 hari';
      case '90d':
        return '90 hari';
      default:
        return '7 hari';
    }
  }

  @override
  void onInit() {
    super.onInit();
    load();
    loadArticles();
  }

  /// Artikel terbaru untuk seksi home (gagal diam-diam — seksi disembunyikan).
  Future<void> loadArticles() async {
    final res = await ApiClient.get<List<Article>>(
      '/articles',
      query: {'per_page': 5},
      parse: (json) => (json as List).map(Article.fromJson).toList(),
    );
    if (res.success && res.data != null) {
      articles.assignAll(res.data!);
    }
  }

  /// Fetches the dashboard. [silent] keeps the current data on screen
  /// (used by pull-to-refresh) instead of showing the full-screen loader.
  Future<void> load({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    errorMessage.value = null;

    final res = await ApiClient.get<Dashboard>(
      '/dashboard',
      query: {'period': period.value},
      parse: Dashboard.fromJson,
    );

    isLoading.value = false;

    if (res.success && res.data != null) {
      needsLogin.value = false;
      dashboard.value = res.data;
      return;
    }
    // Dashboard is an [Auth] endpoint (API.md §7.1) — guests get 401/403.
    if (res.statusCode == 401 || res.statusCode == 403) {
      needsLogin.value = true;
      dashboard.value = null;
      return;
    }
    if (!silent) errorMessage.value = res.errorText;
  }

  Future<void> setPeriod(String value) async {
    if (period.value == value) return;
    period.value = value;
    await load();
  }

  // ── Greeting ──────────────────────────────────────────────────────────────

  String get greetingName {
    final name = AuthService.currentUser.value?.name ?? '';
    return name.isEmpty ? 'Petambak' : name;
  }

  String get greetingSubtitle {
    final province = AuthService.currentUser.value?.province ?? '';
    if (province.isNotEmpty) return province;
    return 'Prediksi penyakit ikan & komunitas tambak';
  }

  String? get avatarUrl => AuthService.currentUser.value?.avatarUrl;

  // ── Navigation ────────────────────────────────────────────────────────────

  void changeTab(int index) {
    if (Get.isRegistered<MainNavigationController>()) {
      Get.find<MainNavigationController>().changeTab(index);
    }
  }

  void openNotifications() => Get.toNamed(Routes.notifications);

  void openLogin() => Get.toNamed(Routes.login);

  void openScanHistory() => Get.toNamed(Routes.scanHistory);

  void openHeatmap() => Get.toNamed(Routes.heatmap);

  void openPonds() => Get.toNamed(Routes.ponds);

  void openScan(String scanId) =>
      Get.toNamed(Routes.scanResult, arguments: {'scanId': scanId});

  void openPost(int id) =>
      Get.toNamed(Routes.forumDetail, arguments: {'id': id});

  void openDisease(int? id) {
    if (id == null) return;
    Get.toNamed(Routes.diseaseDetail, arguments: {'id': id});
  }

  void openArticles() => Get.toNamed(Routes.articles);

  void openArticle(Article item) => Get.toNamed(
        Routes.articleDetail,
        arguments: {'id': item.id ?? item.slug},
      );
}
