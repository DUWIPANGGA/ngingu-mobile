import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/app_info_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/ngingu_logo.dart';
import '../widgets/profile_widgets.dart';

/// Halaman Tentang — `GET /api/app-info` (publik).
///
/// Berdiri sendiri tanpa controller/get binding (Routes.about tanpa Bindings).
class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  bool _loading = true;
  String? _error;
  AppInfo? _info;
  Map<String, dynamic> _raw = const {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiClient.get<dynamic>('/app-info');
    if (!mounted) return;
    if (res.success && res.data is Map<String, dynamic>) {
      setState(() {
        _raw = res.data as Map<String, dynamic>;
        _info = AppInfo.fromJson(res.data);
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.errorText;
        _loading = false;
      });
    }
  }

  /// Current version — backend `app_info` has no `app_version` column, so the
  /// build version from pubspec (`1.0.0`) is the fallback.
  String get _version => (_raw['app_version'] as String?) ?? '1.0.0';

  Future<void> _launch(String url, {LaunchMode mode = LaunchMode.platformDefault}) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: mode);
      if (!ok && mounted) {
        AppTheme.error('Gagal', 'Tautan tidak dapat dibuka.');
      }
    } catch (_) {
      if (mounted) AppTheme.error('Gagal', 'Tautan tidak dapat dibuka.');
    }
  }

  void _openPolicy({required bool privacy}) {
    final info = _info;
    if (info == null) return;
    final content =
        privacy ? info.privacyPolicyContent : info.termsContent;
    final url = privacy ? info.privacyPolicyUrl : info.termsUrl;
    if (content != null && content.trim().isNotEmpty) {
      _showContentSheet(
        privacy ? 'Kebijakan Privasi' : 'Syarat & Ketentuan',
        content,
      );
    } else if (url != null && url.trim().isNotEmpty) {
      _launch(url);
    } else {
      AppTheme.error('Gagal', 'Dokumen belum tersedia.');
    }
  }

  void _showContentSheet(String title, String content) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _openApk() {
    final apk = _info?.apkPath;
    if (apk == null || apk.trim().isEmpty) return;
    if (apk.startsWith('http')) {
      _launch(apk, mode: LaunchMode.externalApplication);
    } else {
      AppTheme.error('Gagal', 'Tautan APK tidak valid.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Tentang Ngingu')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return _skeleton();
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _fetch);
    }
    final info = _info;
    if (info == null) {
      return const EmptyState(
        icon: Icons.info_outline,
        title: 'Informasi aplikasi belum tersedia',
        subtitle: 'Coba muat ulang beberapa saat lagi.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          if (info.hasApk) ...[
            AppBanner(
              icon: Icons.system_update_alt,
              message: 'Update tersedia'
                  '${(info.apkVersion ?? '').isNotEmpty ? ' (v${info.apkVersion})' : ''}'
                  '${info.apkFilename == 'External Link' ? ' — aplikasi dibuka di browser.' : '.'}',
              actionLabel: 'Perbarui',
              onAction: _openApk,
            ),
            const SizedBox(height: 16),
          ],
          SoftCard(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              children: [
                const NginguLogo(size: 76, animate: false),
                const SizedBox(height: 14),
                Text(
                  info.appName ?? 'Ngingu',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_version.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Versi $_version',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
                if ((info.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    info.description!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Dokumen'),
          SoftCard(
            child: Column(
              children: [
                MenuRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Kebijakan Privasi',
                  subtitle: 'Bagaimana data tambak Anda digunakan',
                  onTap: () => _openPolicy(privacy: true),
                ),
                const Divider(indent: 70),
                MenuRow(
                  icon: Icons.description_outlined,
                  title: 'Syarat & Ketentuan',
                  onTap: () => _openPolicy(privacy: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Informasi Pengembang'),
          SoftCard(
            child: Column(
              children: [
                if ((info.developer ?? '').isNotEmpty)
                  MenuRow(
                    icon: Icons.code_outlined,
                    title: 'Pengembang',
                    subtitle: info.developer,
                    onTap: null,
                    trailing: const SizedBox.shrink(),
                  ),
                if ((info.website ?? '').isNotEmpty) ...[
                  const Divider(indent: 70),
                  MenuRow(
                    icon: Icons.language_outlined,
                    title: 'Website',
                    subtitle: info.website,
                    onTap: () => _launch(info.website!),
                  ),
                ],
                if ((info.supportEmail ?? '').isNotEmpty) ...[
                  const Divider(indent: 70),
                  MenuRow(
                    icon: Icons.mail_outline,
                    title: 'Dukungan',
                    subtitle: info.supportEmail,
                    onTap: () => _launch('mailto:${info.supportEmail}'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Dibuat untuk petambak Indonesia',
              style: TextStyle(fontSize: 11.5, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  /// Loading skeleton (SRS §7.1 — Fast).
  Widget _skeleton() {
    Widget box(double w, double h, {double radius = 12}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        Center(child: box(76, 76, radius: 38)),
        const SizedBox(height: 16),
        Center(child: box(160, 20)),
        const SizedBox(height: 10),
        Center(child: box(90, 14)),
        const SizedBox(height: 20),
        Center(child: box(260, 14)),
        const SizedBox(height: 6),
        Center(child: box(220, 14)),
        const SizedBox(height: 24),
        box(double.infinity, 64),
        const SizedBox(height: 16),
        box(double.infinity, 64),
      ],
    );
  }
}
