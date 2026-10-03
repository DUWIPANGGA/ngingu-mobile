import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/notification_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../routes/app_routes.dart';
import '../controllers/notification_settings_controller.dart';
import '../widgets/profile_widgets.dart';

/// Pengaturan notifikasi per tipe — in-app, push, email (API.md §8.5, FR-06.6).
class NotificationSettingsView extends GetView<NotificationSettingsController> {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.page,
      appBar: AppBar(title: const Text('Pengaturan Notifikasi')),
      bottomNavigationBar: SafeArea(
        child: Obx(() {
          final enabled = controller.isDirty && !controller.isSaving.value;
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: PrimaryButton(
              label: 'Simpan',
              loading: controller.isSaving.value,
              onPressed: enabled ? controller.save : null,
            ),
          );
        }),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.needsLogin.value) {
            return EmptyState(
              icon: Icons.lock_outline,
              title: 'Masuk untuk mengatur notifikasi',
              subtitle:
                  'Kanal notifikasi (dalam aplikasi, push, dan email) diatur per akun.',
              actionLabel: 'Masuk',
              onAction: () => Get.offAllNamed(Routes.login),
            );
          }
          if (controller.isLoading.value && controller.settings.isEmpty) {
            return const LoadingState(message: 'Memuat pengaturan...');
          }
          if (controller.settings.isEmpty) {
            final error = controller.errorMessage.value;
            if (error != null) {
              return ErrorState(message: error, onRetry: controller.fetch);
            }
            return EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Pengaturan belum tersedia',
              subtitle: 'Tarik ke bawah untuk memuat ulang.',
              actionLabel: 'Muat Ulang',
              onAction: controller.fetch,
            );
          }
          return RefreshIndicator(
            onRefresh: controller.fetch,
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const AppBanner(
                  icon: Icons.tune,
                  message:
                      'Pilih kanal yang ingin dipakai untuk tiap jenis pemberitahuan.',
                ),
                const SizedBox(height: 14),
                for (final setting in controller.settings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _typeCard(setting),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _typeCard(NotificationSetting setting) {
    return SoftCard(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                IconCircle(
                  icon: NotifType.icon(setting.type),
                  size: 36,
                  iconSize: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    NotifType.label(setting.type),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text(
              'Dalam Aplikasi',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            value: setting.viaInapp,
            onChanged: (v) => controller.toggle(setting.type, 'inapp', v),
          ),
          SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text(
              'Notifikasi Push',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            value: setting.viaPush,
            onChanged: (v) => controller.toggle(setting.type, 'push', v),
          ),
          SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text(
              'Email',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            value: setting.viaEmail,
            onChanged: (v) => controller.toggle(setting.type, 'email', v),
          ),
        ],
      ),
    );
  }
}
