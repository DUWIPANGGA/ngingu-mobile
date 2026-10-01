import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/notification_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';

/// Pusat notifikasi in-app — `GET/PATCH /api/notifications` (API.md §8.1–§8.3, FR-06).
///
/// Daftar berpaginasi (`meta.current_page`/`last_page`), filter `unread_only`,
/// tandai dibaca per item / sekaligus, dan sinkronisasi badge lonceng lewat
/// [NotificationService].
class NotificationController extends GetxController {
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasError = false.obs;
  final errorMessage = RxnString();
  final unreadOnly = false.obs;
  final needsLogin = false.obs;

  final items = <AppNotification>[].obs;

  /// Jumlah belum dibaca dari `meta.unread_count` (API.md §8.1).
  final unreadCount = 0.obs;

  final ScrollController scrollController = ScrollController();

  int _page = 1;
  int _lastPage = 1;

  bool get isAuthed => AuthService.isAuthed;

  bool get hasUnread => items.isNotEmpty && items.any((n) => !n.isRead);

  /// "Tandai semua" hanya untuk pengguna masuk yang masih punya yang belum dibaca.
  bool get canMarkAll => isAuthed && hasUnread;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    if (!isAuthed) {
      isLoading.value = false;
      needsLogin.value = true;
      return;
    }
    reload(showSkeleton: true);
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  // ── muat data (API.md §8.1) ───────────────────────────────────────────────

  Future<void> reload({bool showSkeleton = false}) async {
    if (showSkeleton) isLoading.value = true;
    await _load(page: 1, showSkeleton: showSkeleton);
  }

  /// Tarik-ke-bawah: tampilkan indikator tanpa menyembunyikan daftar.
  Future<void> onRefresh() => reload();

  Future<void> retry() => reload(showSkeleton: true);

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || hasError.value) return;
    if (_page >= _lastPage) return;
    isLoadingMore.value = true;
    await _load(page: _page + 1);
    isLoadingMore.value = false;
  }

  Future<void> _load({required int page, bool showSkeleton = false}) async {
    if (!isAuthed) {
      isLoading.value = false;
      needsLogin.value = true;
      return;
    }
    if (showSkeleton) isLoading.value = true;

    final res = await ApiClient.get<List<AppNotification>>(
      '/notifications',
      query: <String, dynamic>{
        'page': page,
        if (unreadOnly.value) 'unread_only': 'true',
      },
      parse: (raw) =>
          (raw as List).map(AppNotification.fromJson).toList(),
    );
    isLoading.value = false;

    if (res.success) {
      final loaded = res.data ?? const <AppNotification>[];
      if (page == 1) {
        items.assignAll(loaded);
      } else {
        items.addAll(loaded);
      }
      _page = res.currentPage;
      _lastPage = res.lastPage;
      hasError.value = false;
      errorMessage.value = null;
      needsLogin.value = false;
      if (res.meta?['unread_count'] != null) _pushBadge(res.unreadCount);
      return;
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      needsLogin.value = true;
      return;
    }
    if (page == 1 && items.isEmpty) {
      hasError.value = true;
      errorMessage.value = res.errorText;
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) loadMore();
  }

  // ── filter ────────────────────────────────────────────────────────────────

  Future<void> setUnreadOnly(bool value) async {
    if (unreadOnly.value == value) return;
    unreadOnly.value = value;
    await reload(showSkeleton: true);
  }

  // ── tandai dibaca (API.md §8.2 / §8.3) ────────────────────────────────────

  /// Ketuk notifikasi: tandai dibaca (bila belum) lalu buka tujuannya.
  void onTap(AppNotification notification) {
    if (!notification.isRead) {
      markRead(notification); // optimistis, tanpa menunda navigasi
    }
    _navigate(notification);
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead || !isAuthed) return;
    final previousUnread = unreadCount.value;

    _replace(_readCopy(notification, DateTime.now().toIso8601String()));
    _pushBadge(previousUnread > 0 ? previousUnread - 1 : 0);

    final res =
        await ApiClient.patch<dynamic>('/notifications/${notification.id}/read');
    if (res.success) {
      _refreshBadge();
      return;
    }
    // Gagal → kembalikan ke keadaan semula.
    _replace(notification);
    _pushBadge(previousUnread);
    if (res.statusCode == 401 || res.statusCode == 403) {
      needsLogin.value = true;
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  Future<void> markAllRead() async {
    if (!canMarkAll) return;
    final previous = items.toList();
    final now = DateTime.now().toIso8601String();
    for (var i = 0; i < items.length; i++) {
      if (!items[i].isRead) items[i] = _readCopy(items[i], now);
    }
    _pushBadge(0);

    final res = await ApiClient.patch<dynamic>('/notifications/read-all');
    if (res.success) {
      _refreshBadge();
      AppTheme.success('Berhasil', 'Semua notifikasi ditandai dibaca');
      if (unreadOnly.value) await reload();
      return;
    }

    items.assignAll(previous);
    _pushBadge(previous.where((n) => !n.isRead).length);
    if (res.statusCode == 401 || res.statusCode == 403) {
      needsLogin.value = true;
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  // ── tujuan navigasi per tipe (payload `data` — API.md §8.1) ───────────────

  void _navigate(AppNotification notification) {
    final data = notification.data;
    switch (notification.type) {
      case NotifType.scanResult:
        final scanId = data['scan_id']?.toString();
        if (scanId != null && scanId.isNotEmpty) {
          Get.toNamed(Routes.scanResult, arguments: {'scanId': scanId});
        }
      case NotifType.forumReply:
      case NotifType.mention:
        final postId = _asInt(data['post_id']);
        if (postId != null) {
          Get.toNamed(Routes.forumDetail, arguments: {'id': postId});
        }
      case NotifType.outbreak:
        Get.toNamed(Routes.heatmap);
      case NotifType.tips:
        final diseaseId = _asInt(data['disease_id']);
        if (diseaseId != null) {
          Get.toNamed(Routes.diseaseDetail, arguments: {'id': diseaseId});
        }
      default:
        // weekly, security, dan tipe tak dikenal: tanpa navigasi.
        break;
    }
  }

  static int? _asInt(dynamic raw) {
    if (raw is num) return raw.toInt();
    final text = raw?.toString();
    if (text == null || text.isEmpty) return null;
    return int.tryParse(text);
  }

  // ── badge lonceng (NotificationService) ───────────────────────────────────

  void _pushBadge(int value) {
    unreadCount.value = value < 0 ? 0 : value;
    if (Get.isRegistered<NotificationService>()) {
      NotificationService.to.unreadCount.value = unreadCount.value;
    }
  }

  void _refreshBadge() {
    if (Get.isRegistered<NotificationService>()) {
      NotificationService.to.fetchUnread();
    }
  }

  static AppNotification _readCopy(AppNotification n, String readAt) =>
      AppNotification(
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        data: n.data,
        readAt: readAt,
        createdAt: n.createdAt,
      );

  void _replace(AppNotification updated) {
    final index = items.indexWhere((n) => n.id == updated.id);
    if (index != -1) items[index] = updated;
  }
}
