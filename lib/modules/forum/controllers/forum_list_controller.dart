import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/forum_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../utils/forum_utils.dart';

/// State for the Forum tab (FR-05.1): categories, search, sort, pagination.
///
/// Endpoints (API.md Â§6.1/Â§6.2):
///   GET /api/forum/categories
///   GET /api/forum/posts?q&category|category_id&sort&page
class ForumListController extends GetxController {
  /// `sort` values allowed by API.md Â§6.2 (default `terbaru`).
  static const defaultSort = 'terbaru';
  static const sortOptions = <String>[
    'terbaru',
    'trending',
    'belum_terjawab',
    'mengikuti',
  ];

  static String sortLabel(String value) {
    switch (value) {
      case 'trending':
        return 'Trending';
      case 'belum_terjawab':
        return 'Belum Terjawab';
      case 'mengikuti':
        return 'Mengikuti';
      default:
        return 'Terbaru';
    }
  }

  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  final posts = <ForumPost>[].obs;
  final categories = <ForumCategory>[].obs;
  final selectedCategory = Rxn<ForumCategory>();
  final sort = defaultSort.obs;

  final searchController = TextEditingController();
  final scrollController = ScrollController();

  Timer? _debounce;
  String _query = '';
  int _page = 1;
  int _lastPage = 1;

  bool get isAuthed => AuthService.isAuthed;

  /// Count of non-default filters shown on the header filter icon.
  int get activeFilterCount =>
      (selectedCategory.value == null ? 0 : 1) +
      (sort.value == defaultSort ? 0 : 1);

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    loadCategories();
    reload(showSkeleton: true);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

  // â”€â”€ categories (Â§6.1) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> loadCategories() async {
    final res = await ApiClient.get<dynamic>(
      '/forum/categories',
      parse: (raw) => raw,
    );
    if (res.success) {
      categories.assignAll(parseForumCategories(res.data));
    }
  }

  // â”€â”€ posts (Â§6.2) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> reload({bool showSkeleton = false}) async {
    if (showSkeleton) isLoading.value = true;
    isRefreshing.value = true;
    await _load(page: 1, showSkeleton: showSkeleton);
    isRefreshing.value = false;
  }

  Future<void> retry() => reload(showSkeleton: true);

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || hasError.value) return;
    if (_page >= _lastPage) return;
    isLoadingMore.value = true;
    await _load(page: _page + 1);
    isLoadingMore.value = false;
  }

  Future<void> _load({required int page, bool showSkeleton = false}) async {
    if (showSkeleton) isLoading.value = true;
    final query = <String, dynamic>{
      'sort': sort.value,
      'page': page,
      if (_query.isNotEmpty) 'q': _query,
      ..._categoryQuery,
    };

    final res = await ApiClient.get<List<ForumPost>>(
      '/forum/posts',
      query: query,
      parse: parseForumPosts,
    );

    if (res.success) {
      final items = res.data ?? const <ForumPost>[];
      if (page == 1) {
        posts.assignAll(items);
      } else {
        posts.addAll(items);
      }
      _page = res.currentPage;
      _lastPage = res.lastPage;
      hasError.value = false;
      errorMessage.value = '';
    } else {
      if (page == 1 && posts.isEmpty) {
        hasError.value = true;
        errorMessage.value = res.errorText;
      } else {
        AppTheme.error('Gagal', res.errorText);
      }
    }
    isLoading.value = false;
  }

  /// Â§6.2 filters by `category` (slug); `category_id` is kept as a fallback
  /// for payloads that ship without a slug.
  Map<String, dynamic> get _categoryQuery {
    final category = selectedCategory.value;
    if (category == null) return const {};
    final slug = category.slug;
    if (slug != null && slug.isNotEmpty) return {'category': slug};
    if (category.id != null) return {'category_id': category.id};
    return const {};
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      loadMore();
    }
  }

  // â”€â”€ filters â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = value.trim();
      reload(showSkeleton: true);
    });
  }

  void clearSearch() {
    searchController.clear();
    _debounce?.cancel();
    _query = '';
    reload(showSkeleton: true);
  }

  void selectCategory(ForumCategory? category) {
    if (selectedCategory.value?.id == category?.id &&
        selectedCategory.value?.name == category?.name) {
      return;
    }
    selectedCategory.value = category;
    reload(showSkeleton: true);
  }

  void selectSort(String value) {
    if (sort.value == value) return;
    sort.value = value;
    reload(showSkeleton: true);
  }

  void resetFilters() {
    selectedCategory.value = null;
    if (sort.value != defaultSort) {
      sort.value = defaultSort;
    }
    if (_query.isNotEmpty) {
      searchController.clear();
      _query = '';
    }
    reload(showSkeleton: true);
  }

  // â”€â”€ navigation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> openPost(int id) async {
    await Get.toNamed(Routes.forumDetail, arguments: {'id': id});
    await reload();
  }

  Future<void> openAuthor(ForumAuthor author) async {
    if (author.id == null) return;
    await Get.toNamed(Routes.publicProfile, arguments: {'id': author.id});
  }

  Future<void> openCompose() async {
    if (!AuthService.isAuthed) {
      await showLoginPrompt();
      return;
    }
    await Get.toNamed(Routes.forumCompose);
    await reload();
  }
}
