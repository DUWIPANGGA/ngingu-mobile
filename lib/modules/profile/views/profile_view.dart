import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/ngingu_logo.dart';
import '../../../routes/app_routes.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_widgets.dart';

/// Profil tab (FR-08): header akun, statistik, menu pengaturan, keluar.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.page,
      body: SafeArea(
        child: Obx(() {
          if (AuthService.isGuest) return _guestBody();
          final user = AuthService.currentUser.value;
          if (user == null && controller.isLoading.value) {
            return const LoadingState(message: 'Memuat profil...');
          }
          if (user == null) {
            return ErrorState(
              message: (controller.errorMessage.value ?? '').isEmpty
                  ? 'Profil gagal dimuat. Tarik ke bawah untuk mencoba lagi.'
                  : controller.errorMessage.value!,
              onRetry: controller.refreshProfile,
            );
          }
          return _authedBody(context, user);
        }),
      ),
    );
  }

  // ── Guest ────────────────────────────────────────────────────────────────

  Widget _guestBody() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        SoftCard(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          child: Column(
            children: [
              const NginguLogo(size: 72, animate: false),
              const SizedBox(height: 16),
              const Text(
                'Masuk ke Ngingu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Simpan riwayat scan, kelola tambak, dan ikut diskusi komunitas petambak Indonesia.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Masuk',
                icon: Icons.login_rounded,
                onPressed: () => Get.offAllNamed(Routes.login),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const AppBanner(
          icon: Icons.explore_outlined,
          message:
              'Mode Tamu: ensiklopedia penyakit tetap dapat dijelajahi tanpa akun. Scan, forum, dan pengaturan notifikasi memerlukan masuk.',
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Tetap Bermanfaat'),
        SoftCard(
          child: Column(
            children: [
              MenuRow(
                icon: Icons.help_outline,
                title: 'Pusat Bantuan',
                subtitle: 'Kontak dan pertanyaan umum',
                onTap: () => Get.toNamed(Routes.help),
              ),
              const Divider(indent: 70),
              Obx(
                () => MenuRow(
                  icon: Icons.dark_mode_outlined,
                  title: 'Tampilan',
                  subtitle: ThemeController.to.label,
                  onTap: ThemeController.to.showPicker,
                ),
              ),
              const Divider(indent: 70),
              MenuRow(
                icon: Icons.info_outline,
                title: 'Tentang Ngingu',
                subtitle: 'Versi, kebijakan, dan pengembang',
                onTap: () => Get.toNamed(Routes.about),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const IconCircle(icon: Icons.person_off_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mode Tamu aktif',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Anda menjelajahi Ngingu tanpa akun. Riwayat scan dan diskusi tidak tersimpan.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SecondaryButton(
                        label: 'Masuk ke Akun',
                        expand: false,
                        onPressed: () => Get.offAllNamed(Routes.login),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Signed in ────────────────────────────────────────────────────────────

  Widget _authedBody(BuildContext context, User user) {
    final info = controller.publicInfo.value;
    return RefreshIndicator(
      onRefresh: controller.refreshProfile,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _headerCard(user, info),
          if (info != null) ...[
            const SizedBox(height: 16),
            _statsRow(info),
          ],
          const SizedBox(height: 20),
          const SectionHeader(title: 'Akun'),
          SoftCard(
            child: Column(
              children: [
                MenuRow(
                  icon: Icons.person_outline,
                  title: 'Ubah Profil',
                  subtitle: 'Nama, bio, provinsi, jenis ikan',
                  onTap: () => Get.toNamed(Routes.editProfile),
                ),
                const Divider(indent: 70),
                MenuRow(
                  icon: Icons.lock_outline,
                  title: 'Ubah Password',
                  onTap: () => Get.toNamed(Routes.changePassword),
                ),
                const Divider(indent: 70),
                MenuRow(
                  icon: Icons.notifications_none_outlined,
                  title: 'Pengaturan Notifikasi',
                  onTap: () => Get.toNamed(Routes.notificationSettings),
                ),
                const Divider(indent: 70),
                Obx(
                  () => MenuRow(
                    icon: Icons.dark_mode_outlined,
                    title: 'Tampilan',
                    subtitle: ThemeController.to.label,
                    onTap: ThemeController.to.showPicker,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Aktivitas'),
          SoftCard(
            child: Column(
              children: [
                MenuRow(
                  icon: Icons.history,
                  title: 'Riwayat Scan',
                  subtitle: 'Hasil prediksi penyakit ikan',
                  onTap: () => Get.toNamed(Routes.scanHistory),
                ),
                const Divider(indent: 70),
                MenuRow(
                  icon: Icons.map_outlined,
                  title: 'Peta Sebaran',
                  subtitle: 'Sebaran penyakit per provinsi',
                  onTap: () => Get.toNamed(Routes.heatmap),
                ),
                const Divider(indent: 70),
                MenuRow(
                  icon: Icons.article_outlined,
                  title: 'Artikel Edukasi',
                  subtitle: 'Panduan budidaya & kesehatan ikan',
                  onTap: () => Get.toNamed(Routes.articles),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Lainnya'),
          SoftCard(
            child: Column(
              children: [
                MenuRow(
                  icon: Icons.help_outline,
                  title: 'Pusat Bantuan',
                  onTap: () => Get.toNamed(Routes.help),
                ),
                const Divider(indent: 70),
                MenuRow(
                  icon: Icons.info_outline,
                  title: 'Tentang Ngingu',
                  onTap: () => Get.toNamed(Routes.about),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DangerButton(label: 'Keluar', onPressed: () => _confirmLogout(context)),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Ngingu — prediksi penyakit ikan & komunitas tambak',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard(User user, PublicProfile? info) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(url: user.avatarUrl, name: user.name, radius: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconAction(
                          icon: Icons.edit_outlined,
                          tooltip: 'Ubah Profil',
                          onPressed: () => Get.toNamed(Routes.editProfile),
                        ),
                      ],
                    ),
                    if ((user.username ?? '').isNotEmpty)
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if ((user.province ?? '').isNotEmpty)
                          InfoChip(
                            icon: Icons.place_outlined,
                            label: user.province!,
                          ),
                        InfoChip(
                          icon: Icons.emoji_events_outlined,
                          label:
                              '${user.reputationPoints} • ${user.reputationLevel}',
                          bg: AppColors.softAmber,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((user.bio ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              user.bio!,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          if (info != null && info.badges.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'BADGE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: info.badges.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => InfoChip(
                  icon: Icons.verified_rounded,
                  label: info.badges[index].label,
                  bg: AppColors.softGreen,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.textLight),
              const SizedBox(width: 6),
              Text(
                'Bergabung ${formatDate(user.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsRow(PublicProfile info) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Postingan',
            value: info.postsCount,
            icon: Icons.forum_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Jawaban Terbaik',
            value: info.bestAnswersCount,
            icon: Icons.check_circle_outline,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Sesi Anda akan diakhiri di perangkat ini. Anda bisa masuk kembali kapan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.logout();
  }
}
