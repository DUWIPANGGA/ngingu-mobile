import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/pond_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../widgets/pond_common.dart';

/// Daftar tambak — `GET /api/ponds` (API.md §7.2) + hapus
/// `DELETE /api/ponds/{id}` (API.md §7.5). Tamu → CTA login (FR-03.1.5).
class PondsController extends GetxController {
  static const int _perPage = 15;
  static const int _loadMoreThreshold = 400;

  final RxList<Pond> items = <Pond>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();

  final ScrollController scrollController = ScrollController();

  int _page = 1;
  int _lastPage = 1;

  /// `updated_at` mentah per id — model [Pond] tidak menyimpannya.
  final Map<String, String> _updatedAt = {};

  bool get isGuest => AuthService.isGuest;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    if (AuthService.isAuthed) reload();
  }

  /// Tanggal "diperbarui" terbaik yang tersedia untuk sebuah tambak.
  String? updatedAtOf(Pond pond) => _updatedAt[pond.id] ?? pond.createdAt;

  void goToLogin() => Get.toNamed(Routes.login);
  void openCreate() => Get.toNamed(Routes.pondForm);
  void openEdit(Pond pond) =>
      Get.toNamed(Routes.pondForm, arguments: {'id': pond.id});
  void openHealth(Pond pond) =>
      Get.toNamed(Routes.pondHealth, arguments: {'id': pond.id});

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) loadMore();
  }

  /// Muat ulang dari halaman pertama (juga dipanggil PondFormController
  /// setelah simpan — guarded oleh `Get.isRegistered` di sana).
  Future<void> reload() async {
    if (!AuthService.isAuthed) {
      items.clear();
      isLoading.value = false;
      errorMessage.value = null;
      return;
    }
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
      errorMessage.value = null;
    }
    final res = await ApiClient.get<List<Pond>>(
      '/ponds',
      query: {'page': page, 'per_page': _perPage},
      parse: (json) {
        final ponds = <Pond>[];
        for (final raw in (json as List)) {
          final pond = Pond.fromJson(raw);
          if (raw is Map<String, dynamic>) {
            final updated = raw['updated_at'] as String?;
            if (updated != null) _updatedAt[pond.id] = updated;
          }
          ponds.add(pond);
        }
        return ponds;
      },
    );
    if (append) {
      isLoadingMore.value = false;
    } else {
      isLoading.value = false;
    }
    if (res.success && res.data != null) {
      _page = res.currentPage;
      _lastPage = res.lastPage < 1 ? 1 : res.lastPage;
      if (append) {
        items.addAll(res.data!);
      } else {
        items.assignAll(res.data!);
      }
    } else if (!append) {
      errorMessage.value = res.statusCode == 401
          ? 'Sesi berakhir. Silakan masuk kembali.'
          : res.errorText;
    }
  }

  /// `DELETE /api/ponds/{id}` (API.md §7.5) dengan konfirmasi.
  Future<void> deletePond(Pond pond) async {
    final confirmed = await confirmPondDestructive(
      title: 'Hapus tambak ini?',
      message: 'Data tambak "${pond.name}" akan dihapus permanen.',
    );
    if (!confirmed) return;
    final res = await ApiClient.delete<dynamic>('/ponds/${pond.id}');
    if (res.success) {
      items.removeWhere((p) => p.id == pond.id);
      AppTheme.success('Berhasil', 'Tambak berhasil dihapus.');
    } else {
      AppTheme.error(
        'Gagal',
        res.statusCode == 401
            ? 'Sesi berakhir. Silakan masuk kembali.'
            : res.errorText,
      );
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
