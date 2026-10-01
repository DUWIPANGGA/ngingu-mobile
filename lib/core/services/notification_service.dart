import 'dart:async';

import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../config/app_config.dart';
import '../models/notification_model.dart';
import '../network/api_client.dart';
import 'auth_service.dart';

/// Foreground badge poller (API.md §9.2, FR-06.1/FR-06.3).
///
/// Polls `GET /api/notifications` every 60s while a user is logged in and
/// exposes `unreadCount` for the bell badge. No WebSocket — pure HTTP polling.
class NotificationService extends GetxService {
  final RxInt unreadCount = 0.obs;
  Timer? _timer;
  bool _fetching = false;

  static NotificationService get to => Get.find();

  /// Boot from main(); starts polling automatically when a session exists.
  Future<NotificationService> init() async {
    if (AuthService.isLoggedIn) start();
    return this;
  }

  void start() {
    stop();
    fetchUnread();
    _timer = Timer.periodic(AppConfig.notificationPollInterval, (_) => fetchUnread());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> fetchUnread() async {
    if (_fetching || !AuthService.isLoggedIn) return;
    _fetching = true;
    try {
      final res = await ApiClient.get<dynamic>(
        '/notifications',
        query: {'unread_only': 'true', 'per_page': 1},
      );
      if (res.success) {
        unreadCount.value = res.unreadCount;
      }
    } finally {
      _fetching = false;
    }
  }

  /// Open the notification center and refresh.
  Future<void> openCenter() async {
    await Get.toNamed(Routes.notifications);
    fetchUnread();
  }

  /// Mark one as read locally (controller calls API first).
  void markReadLocally(AppNotification n) {
    if (!n.isRead && unreadCount.value > 0) unreadCount.value--;
  }

  @override
  void onClose() => stop();
}
