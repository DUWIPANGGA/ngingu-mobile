import 'package:get/get.dart';

import '../../../core/models/article_model.dart';
import '../../../core/network/api_client.dart';
import '../../../routes/app_routes.dart';

/// Daftar artikel edukasi — publik, bisa dibuka tamu.
class ArticleListController extends GetxController {
  final RxList<Article> items = <Article>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  int _page = 1;
  bool _requesting = false;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() => fetch(reset: true);

  Future<void> fetch({required bool reset}) async {
    if (_requesting) return;
    _requesting = true;
    if (reset) {
      _page = 1;
      errorMessage.value = null;
      if (items.isEmpty) isLoading.value = true;
    }
    final res = await ApiClient.get<List<Article>>(
      '/articles',
      query: {'page': _page, 'per_page': 20},
      parse: (json) =>
          (json as List).map(Article.fromJson).toList(),
    );
    _requesting = false;
    if (res.success) {
      if (reset) {
        items.assignAll(res.data ?? const <Article>[]);
      } else {
        items.addAll(res.data ?? const <Article>[]);
      }
    } else if (items.isEmpty) {
      errorMessage.value = res.errorText;
    }
    isLoading.value = false;
  }

  void openDetail(Article item) {
    final id = item.id;
    if (id == null && (item.slug ?? '').isEmpty) return;
    Get.toNamed(
      Routes.articleDetail,
      arguments: {'id': id ?? item.slug},
    );
  }
}
