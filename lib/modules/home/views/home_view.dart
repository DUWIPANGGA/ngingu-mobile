import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/dashboard_model.dart';
import '../../../core/models/forum_model.dart';
import '../../../core/models/scan_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../articles/views/article_list_view.dart';
import '../controllers/home_controller.dart';

/// Beranda / dashboard (API.md §7.1, FR-07).
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Obx(() {
          final data = controller.dashboard.value;
          final loading = controller.isLoading.value;
          final needsLogin = controller.needsLogin.value;
          final error = controller.errorMessage.value;

          if (data == null && needsLogin) {
            return _refreshable([
              _greeting(),
              _guestHero(),
              _quickActions(),
              _articlesSection(),
            ]);
          }
          if (data == null && loading) {
            return const LoadingState(message: 'Memuat dashboard...');
          }
          if (data == null && error != null) {
            return ErrorState(
              message: error,
              onRetry: () => controller.load(),
            );
          }
          if (data == null) {
            return const LoadingState();
          }

          return _refreshable(_sections(data));
        }),
      ),
    );
  }

  // ── Layout helpers ────────────────────────────────────────────────────────

  Widget _refreshable(List<Widget> children) {
    return RefreshIndicator(
      onRefresh: () => controller.load(silent: true),
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: children,
      ),
    );
  }

  List<Widget> _sections(Dashboard data) {
    return [
      _greeting(),
      _stats(data.statCards),
      _quickActions(),
      _articlesSection(),
      _trendCard(data.diseaseTrend),
      if (data.topDisease != null) _topDiseaseCard(data.topDisease!),
      _recentScansCard(data.recentScans),
      if (data.trendingPosts.isNotEmpty) _trendingPostsCard(data.trendingPosts),
      if (data.activityFeed.isNotEmpty) _activityCard(data.activityFeed),
    ];
  }

  // ── Greeting ──────────────────────────────────────────────────────────────

  Widget _greeting() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hai, ${controller.greetingName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  controller.greetingSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            final unread =
                Get.find<NotificationService>().unreadCount.value;
            return IconAction(
              icon: Icons.notifications_outlined,
              badge: unread,
              tooltip: 'Notifikasi',
              onPressed: controller.openNotifications,
            );
          }),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => controller.changeTab(4),
            child: AppAvatar(
              url: controller.avatarUrl,
              name: controller.greetingName,
              radius: 21,
            ),
          ),
        ],
      ),
    );
  }

  // ── Guest hero ────────────────────────────────────────────────────────────

  Widget _guestHero() {
    return _SectionCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.softSky,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.dashboard_outlined,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          const Text(
            'Masuk untuk lihat dashboard',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ringkasan scan, tren penyakit, dan aktivitas tambak kamu muncul di sini setelah masuk.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Masuk',
            icon: Icons.login_rounded,
            expand: false,
            onPressed: controller.openLogin,
          ),
        ],
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Widget _stats(StatCards s) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Ringkasan Tambak'),
          SizedBox(
            height: 132,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _statBox(StatCard(
                  label: 'Total Scan',
                  value: s.totalScans,
                  icon: Icons.center_focus_weak,
                  color: AppColors.primary,
                  onTap: controller.openScanHistory,
                )),
                _statBox(StatCard(
                  label: 'Penyakit Terdeteksi',
                  value: s.diseasesDetected,
                  icon: Icons.coronavirus_outlined,
                  color: AppColors.accent,
                  onTap: () => controller.changeTab(3),
                )),
                _statBox(StatCard(
                  label: 'Tanya Jawab',
                  value: s.questionsAnswered,
                  icon: Icons.forum_outlined,
                  color: AppColors.secondary,
                  onTap: () => controller.changeTab(2),
                )),
                _statBox(StatCard(
                  label: 'Tambak Aktif',
                  value: s.activePonds,
                  icon: Icons.water_drop_outlined,
                  color: AppColors.primaryDark,
                  onTap: controller.openPonds,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(Widget child) =>
      Padding(padding: const EdgeInsets.only(right: 12), child: child);

  // ── Quick actions ─────────────────────────────────────────────────────────

  Widget _quickActions() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Aksi Cepat'),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.center_focus_weak,
                  label: 'Mulai Scan',
                  color: AppColors.primary,
                  onTap: () => controller.changeTab(1),
                ),
              ),
              Expanded(
                child: _QuickAction(
                  icon: Icons.history,
                  label: 'Riwayat Scan',
                  color: AppColors.primaryDark,
                  onTap: controller.openScanHistory,
                ),
              ),
              Expanded(
                child: _QuickAction(
                  icon: Icons.map_outlined,
                  label: 'Peta Sebaran',
                  color: AppColors.secondary,
                  onTap: controller.openHeatmap,
                ),
              ),
              Expanded(
                child: _QuickAction(
                  icon: Icons.forum_outlined,
                  label: 'Tanya Forum',
                  color: AppColors.accent,
                  onTap: () => controller.changeTab(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Artikel edukasi ───────────────────────────────────────────────────────

  Widget _articlesSection() {
    final items = controller.articles;
    if (items.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(title: 'Artikel Edukasi'),
              ),
              TextButton(
                onPressed: controller.openArticles,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final a = items[i];
                return InkWell(
                  onTap: () => controller.openArticle(a),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 230,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softAmber.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((a.category ?? '').isNotEmpty)
                          Text(
                            a.category!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        if ((a.category ?? '').isNotEmpty)
                          const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            a.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ArticleMeta(item: a),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Trend chart ───────────────────────────────────────────────────────────

  Widget _trendCard(List<TrendPoint> points) {
    final period = controller.period.value;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Tren Penyakit (${points.length} hari)'),
          Row(
            children: [
              for (final value in HomeController.periods)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PeriodChip(
                    label: HomeController.periodLabel(value),
                    selected: period == value,
                    onTap: () => controller.setPeriod(value),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _TrendChart(points: points),
        ],
      ),
    );
  }

  // ── Top disease ───────────────────────────────────────────────────────────

  Widget _topDiseaseCard(TopDisease top) {
    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.softSky,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '#1',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Penyakit terbanyak minggu ini',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textLight),
                ),
                const SizedBox(height: 2),
                Text(
                  top.name ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${top.count} kasus terdeteksi',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MiniButton(label: 'Lihat', onTap: () => controller.openDisease(top.id)),
        ],
      ),
    );
  }

  // ── Recent scans ──────────────────────────────────────────────────────────

  Widget _recentScansCard(List<ScanSummary> scans) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Scan Terbaru'),
          if (scans.isEmpty)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.softSky,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_camera_outlined,
                      size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Belum ada scan. Mulai scan untuk prediksi penyakit ikan kamu.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _MiniButton(
                  label: 'Mulai Scan',
                  onTap: () => controller.changeTab(1),
                ),
              ],
            )
          else
            SizedBox(
              height: 178,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final scan in scans)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 150,
                        child: _ScanCard(
                          scan: scan,
                          onTap: () => controller.openScan(scan.scanId),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Trending forum ────────────────────────────────────────────────────────

  Widget _trendingPostsCard(List<ForumPost> posts) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Sedang Hangat di Forum'),
          for (var i = 0; i < posts.length; i++) ...[
            if (i > 0)
              const Divider(color: AppColors.border, height: 20),
            _PostTile(
              post: posts[i],
              onTap: () => controller.openPost(posts[i].id),
            ),
          ],
        ],
      ),
    );
  }

  // ── Activity feed ─────────────────────────────────────────────────────────

  Widget _activityCard(List<ActivityItem> feed) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Aktivitas Terbaru'),
          for (var i = 0; i < feed.length; i++) ...[
            if (i > 0)
              const Divider(color: AppColors.border, height: 18),
            _ActivityTile(item: feed[i]),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Pieces
// ═══════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple animated bar chart — no chart library (FR-07.2).
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Belum ada data tren.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    var maxCount = 1;
    for (final p in points) {
      if (p.count > maxCount) maxCount = p.count;
    }
    final labelStep =
        points.length <= 6 ? 1 : (points.length / 6).ceil();
    const double chartHeight = 116;
    const double cellHeight = 152;

    return SizedBox(
      height: cellHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < points.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (points.length <= 14 && points[i].count > 0)
                      Text(
                        '${points[i].count}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      )
                    else
                      const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: points[i].count / maxCount),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Container(
                        height: math.max(4.0, value * chartHeight),
                        decoration: BoxDecoration(
                          color: i == points.length - 1
                              ? AppColors.primaryDark
                              : AppColors.primary.withValues(alpha: 0.85),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 14,
                      child: Center(
                        child: Text(
                          i % labelStep == 0 ? shortDate(points[i].date) : '',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.scan, required this.onTap});

  final ScanSummary scan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = resolveImageUrl(scan.thumbnailUrl);
    final diseaseName = scan.disease?.name ?? 'Menunggu prediksi';
    final confidence = scan.confidence;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: double.infinity,
                height: 76,
                child: url.isEmpty
                    ? const _ThumbFallback()
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const _ThumbFallback(),
                        errorWidget: (_, _, _) => const _ThumbFallback(),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              diseaseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              confidence == null
                  ? (scan.fishType ?? '—')
                  : 'Keyakinan ${confidence.toStringAsFixed(0)}%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 7),
            _StatusChip(status: scan.status),
          ],
        ),
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softSky,
      alignment: Alignment.center,
      child: const Icon(Icons.center_focus_weak,
          size: 26, color: AppColors.primary),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    switch (status) {
      case 'done':
        color = AppColors.secondary;
        label = 'Selesai';
      case 'processing':
      case 'pending':
        color = AppColors.accent;
        label = 'Diproses';
      case 'failed':
        color = AppColors.danger;
        label = 'Gagal';
      default:
        color = AppColors.textSecondary;
        label = (status ?? '-').toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post, required this.onTap});

  final ForumPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final author = post.author;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              url: author?.avatarUrl,
              name: author?.name ?? '?',
              radius: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          author?.name ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Text(' • ',
                          style: TextStyle(
                              fontSize: 11.5, color: AppColors.textLight)),
                      Text(
                        timeAgo(post.createdAt),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textLight,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_upward_rounded,
                          size: 13, color: AppColors.textLight),
                      const SizedBox(width: 3),
                      Text(
                        '${post.votesCount}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.mode_comment_outlined,
                          size: 13, color: AppColors.textLight),
                      const SizedBox(width: 3),
                      Text(
                        '${post.commentsCount}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
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
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final ActivityItem item;

  static IconData _iconFor(String? type) {
    switch (type) {
      case 'scan':
      case 'scan_result':
        return Icons.center_focus_weak;
      case 'forum':
      case 'forum_reply':
      case 'reply':
      case 'mention':
        return Icons.forum_outlined;
      case 'pond':
        return Icons.water_drop_outlined;
      case 'outbreak':
        return Icons.warning_amber_outlined;
      case 'tips':
        return Icons.tips_and_updates_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.softSky,
              shape: BoxShape.circle,
            ),
            child: Icon(_iconFor(item.type), size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo(item.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
