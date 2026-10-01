import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/disease_model.dart';
import '../../../core/network/api_client.dart';

/// Disease detail controller — `GET /api/diseases/{id}` (API.md §5.2).
class DiseaseDetailController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<DiseaseDetail> detail = Rxn<DiseaseDetail>();
  final RxList<DiseaseItem> similar = <DiseaseItem>[].obs;
  final RxInt currentImage = 0.obs;

  final PageController heroController = PageController();
  final ScrollController scrollController = ScrollController();

  int? _currentId;

  /// Id currently (or last) rendered — used by retry and by similar-disease taps.
  int? get currentId => _currentId;

  @override
  void onInit() {
    super.onInit();
    load(_readId());
  }

  int? _readId() {
    final args = Get.arguments;
    if (args is Map) return (args['id'] as num?)?.toInt();
    if (args is num) return args.toInt();
    return null;
  }

  @override
  void onClose() {
    heroController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Loads (or replaces) the current disease. Reused by "Penyakit Serupa"
  /// so the same route/controller instance can swap content in place.
  Future<void> load(int? id) async {
    if (id == null) {
      isLoading.value = false;
      errorMessage.value = 'Penyakit tidak ditemukan.';
      return;
    }
    _currentId = id;
    isLoading.value = true;
    errorMessage.value = null;
    detail.value = null;
    similar.clear();
    currentImage.value = 0;
    if (heroController.hasClients) heroController.jumpToPage(0);

    final res = await ApiClient.get<DiseaseDetail>(
      '/diseases/$id',
      parse: DiseaseDetail.fromJson,
    );

    isLoading.value = false;
    final loaded = res.data;
    if (res.success && loaded != null) {
      detail.value = loaded;
      _loadSimilar(loaded.slug);
      return;
    }
    errorMessage.value = res.statusCode == 404
        ? 'Penyakit tidak ditemukan.'
        : res.errorText;
  }

  /// `GET /api/diseases/{slug}/similar` (API.md §5.4).
  Future<void> _loadSimilar(String slug) async {
    if (slug.isEmpty) return;
    final res = await ApiClient.get<List<DiseaseItem>>(
      '/diseases/$slug/similar',
      parse: _parseList,
    );
    if (res.success && res.data != null) {
      similar.assignAll(res.data!);
    }
  }

  static List<DiseaseItem> _parseList(dynamic json) =>
      (json as List).map(DiseaseItem.fromJson).toList();

  void onImageChanged(int index) => currentImage.value = index;

  /// Swap the page content for another disease (no new route).
  void openSimilar(int? id) {
    if (id == null || id == _currentId) return;
    load(id);
    if (scrollController.hasClients) scrollController.jumpTo(0);
  }

  Future<void> retry() => load(_currentId);
}
