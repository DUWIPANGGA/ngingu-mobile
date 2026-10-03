import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/disease_model.dart';
import '../../../core/network/api_client.dart';
import '../../../routes/app_routes.dart';

/// Encyclopedia list controller — `GET /api/diseases` (API.md §5.1, FR-03.1).
class EncyclopediaController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final RxList<DiseaseItem> items = <DiseaseItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxnString errorMessage = RxnString();
  final RxString severityFilter = ''.obs;
  final RxBool hasQuery = false.obs;

  /// True bila daftar berasal dari cache offline.
  final RxBool isOffline = false.obs;

  /// Filter chips — API.md §5.1 `severity=ringan|sedang|berat|kritis`.
  static const List<Map<String, String>> severityOptions =
      <Map<String, String>>[
    {'value': '', 'label': 'Semua'},
    {'value': 'ringan', 'label': 'Ringan'},
    {'value': 'sedang', 'label': 'Sedang'},
    {'value': 'berat', 'label': 'Berat'},
    {'value': 'kritis', 'label': 'Kritis'},
  ];

  static const int _perPage = 15;

  int _page = 1;
  int _lastPage = 1;
  bool _requesting = false;
  bool _pendingReset = false;
  String _query = '';
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    fetch(reset: true);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

  // ── Search & filters ──────────────────────────────────────────────────────

  /// Debounced search (400ms) → `?q=`.
  void onSearchChanged(String value) {
    hasQuery.value = value.isNotEmpty;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = value.trim();
      fetch(reset: true);
    });
  }

  void clearSearch() {
    searchController.clear();
    hasQuery.value = false;
    _debounce?.cancel();
    _query = '';
    fetch(reset: true);
  }

  void setSeverity(String value) {
    if (severityFilter.value == value) return;
    severityFilter.value = value;
    fetch(reset: true);
  }

  // ── Fetching ──────────────────────────────────────────────────────────────

  Future<void> reload() => fetch(reset: true);

  Future<void> loadMore() async {
    if (_requesting || isLoadingMore.value || _page >= _lastPage) return;
    _page++;
    await fetch(reset: false);
  }

  Future<void> fetch({required bool reset}) async {
    if (_requesting) {
      // A list request is already running — remember that the list must be
      // re-fetched from page 1 as soon as it settles (debounced search can
      // land while the first page is still loading).
      if (reset) _pendingReset = true;
      return;
    }
    _requesting = true;

    if (reset) {
      _page = 1;
      errorMessage.value = null;
      if (items.isEmpty) isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }

    final query = <String, dynamic>{
      'page': _page,
      'per_page': _perPage,
    };
    if (_query.isNotEmpty) query['q'] = _query;
    if (severityFilter.value.isNotEmpty) {
      query['severity'] = severityFilter.value;
    }

    final res = await ApiClient.get<List<DiseaseItem>>(
      '/diseases',
      query: query,
      parse: _parseList,
    );

    _requesting = false;

    if (res.success) {
      final list = res.data ?? const <DiseaseItem>[];
      if (reset) {
        items.assignAll(list);
        isOffline.value = false;
        if (_query.isEmpty && severityFilter.value.isEmpty && _page == 1) {
          _saveCache(list);
        }
      } else {
        items.addAll(list);
      }
      _lastPage = res.lastPage < 1 ? 1 : res.lastPage;
    } else {
      if (!reset) _page--; // keep pagination in sync after a failed load-more
      if (items.isEmpty) {
        final cached = await _loadCache();
        if (cached.isNotEmpty) {
          items.assignAll(cached);
          isOffline.value = true;
        } else {
          errorMessage.value = res.errorText;
        }
      }
    }

    isLoading.value = false;
    isLoadingMore.value = false;

    if (_pendingReset) {
      _pendingReset = false;
      await fetch(reset: true);
    }
  }

  static List<DiseaseItem> _parseList(dynamic json) =>
      (json as List).map(DiseaseItem.fromJson).toList();

  static const _cacheKey = 'diseases_cache_v1';

  Future<void> _saveCache(List<DiseaseItem> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _cacheKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (_) {
      // Cache opsional — abaikan.
    }
  }

  Future<List<DiseaseItem>> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return const [];
      return (jsonDecode(raw) as List).map(DiseaseItem.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) loadMore();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void goToDetail(DiseaseItem item) {
    final id = item.id;
    if (id == null) return;
    Get.toNamed(Routes.diseaseDetail, arguments: {'id': id});
  }
}
