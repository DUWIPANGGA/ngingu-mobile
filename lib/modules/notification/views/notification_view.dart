import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/notification_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../routes/app_routes.dart';
import '../controllers/notification_controller.dart';

/// Pusat notifikasi in-app — daftar, filter "Semua / Belum dibaca",
/// tandai dibaca, dan tujuan navigasi per tipe (API.md §8.1–§8.3, FR-06).
class NotificationView extends GetView<NotificationController> {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          Obx(() {
            if (!controller.canMarkAll) return const SizedBox.shrink();
            return TextButton(
              onPressed: controller.markAllRead,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Tandai semua',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: Obx(_body)),
    );
  }

  // ── keadaan ───────────────────────────────────────────────────────────────

  Widget _body() {
    if (controller.needsLogin.value) return _guest();
    if (controller.isLoading.value && controller.items.isEmpty) {
      return const LoadingState(message: 'Memuat notifikasi...');
    }
    if (controller.hasError.value && controller.items.isEmpty) {
      return ErrorState(
        message: controller.errorMessage.value ?? 'Gagal memuat notifikasi.',
        icon: Icons.notifications_none,
        onRetry: controller.retry,
      );
    }
    if (controller.items.isEmpty) return _empty();
    return _list();
  }

  Widget _empty() {
    final filtered = controller.unreadOnly.value;
    return RefreshIndicator(
      onRefresh: controller.onRefresh,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 72),
          filtered
              ? const EmptyState(
                  icon: Icons.done_all_rounded,
                  title: 'Semua sudah dibaca',
                  subtitle: 'Tidak ada notifikasi baru yang menunggu Anda.',
                )
              : const EmptyState(
                  icon: Icons.notifications_none,
                  title: 'Tidak ada notifikasi',
                  subtitle: 'Semua sudah beres.',
                ),
        ],
      ),
    );
  }

  Widget _guest() {
    return RefreshIndicator(
      onRefresh: controller.onRefresh,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 56),
          const EmptyState(
            icon: Icons.notifications_none,
            title: 'Masuk untuk lihat notifikasi',
            subtitle:
                'Hasil scan, balasan forum, dan alert wabah di wilayah Anda muncul di sini.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: PrimaryButton(
              label: 'Masuk',
              icon: Icons.login_rounded,
              expand: false,
              onPressed: () => Get.toNamed(Routes.login),
            ),
          ),
        ],
      ),
    );
  }

  // ── daftar ────────────────────────────────────────────────────────────────

  Widget _list() {
    return RefreshIndicator(
      onRefresh: controller.onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: controller.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: controller.items.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) return _filterHeader();
          if (index == controller.items.length + 1) return _footer();
          return _tile(controller.items[index - 1]);
        },
      ),
    );
  }

  Widget _filterHeader() {
    final unread = controller.unreadCount.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _chip(
            label: 'Semua',
            selected: !controller.unreadOnly.value,
            onTap: () => controller.setUnreadOnly(false),
          ),
          _chip(
            label: 'Belum dibaca',
            selected: controller.unreadOnly.value,
            onTap: () => controller.setUnreadOnly(true),
          ),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.softSky,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$unread belum dibaca',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _tile(AppNotification notification) {
    final unread = !notification.isRead;
    final body = (notification.body ?? '').trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: unread
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unread
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.onTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.softSky,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    NotifType.icon(notification.type),
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.35,
                          fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            timeAgo(notification.createdAt),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                          _typeChip(notification.type),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.softSky,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        NotifType.label(type),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _footer() {
    if (!controller.isLoadingMore.value) return const SizedBox(height: 8);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
