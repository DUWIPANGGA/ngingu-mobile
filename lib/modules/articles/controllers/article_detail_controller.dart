import 'package:get/get.dart';

import '../../../core/models/article_model.dart';
import '../../../core/network/api_client.dart';

/// Isi artikel — argumen `{'id'}` (int id atau slug).
class ArticleDetailController extends GetxController {
  final Rxn<ArticleDetail> detail = Rxn<ArticleDetail>();
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  String get _id {
    final args = Get.arguments;
    if (args is Map && args['id'] != null) return '${args['id']}';
    return '';
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (_id.isEmpty) {
      errorMessage.value = 'Artikel tidak ditemukan.';
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    errorMessage.value = null;
    final res = await ApiClient.get<ArticleDetail>(
      '/articles/$_id',
      parse: ArticleDetail.fromJson,
    );
    isLoading.value = false;
    if (res.success && res.data != null) {
      detail.value = res.data;
    } else {
      errorMessage.value = res.errorText;
    }
  }
}
