import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/help_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

/// Pusat Bantuan — `GET /api/help` (contacts + FAQs, publik).
class HelpController extends GetxController {
  final isLoading = false.obs;
  final data = Rxn<HelpData>();
  final errorMessage = Rxn<String>();

  List<HelpContact> get contacts => data.value?.contacts ?? const [];
  List<Faq> get faqs => data.value?.faqs ?? const [];

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    final res = await ApiClient.get<HelpData>('/help', parse: HelpData.fromJson);
    isLoading.value = false;
    if (res.success && res.data is HelpData) {
      data.value = res.data;
      errorMessage.value = null;
    } else {
      errorMessage.value = res.errorText;
    }
  }

  /// Launch a contact via the right scheme (tel / wa.me / mailto / https).
  Future<void> openContact(HelpContact contact) async {
    final raw = (contact.value ?? '').trim();
    if (raw.isEmpty) {
      AppTheme.error('Gagal', 'Kontak belum tersedia.');
      return;
    }
    final url = _resolveUrl(raw, (contact.type ?? '').toLowerCase());
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppTheme.error('Gagal', 'Kontak tidak valid.');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) AppTheme.error('Gagal', 'Tidak dapat membuka aplikasi kontak.');
    } catch (_) {
      AppTheme.error('Gagal', 'Tidak dapat membuka aplikasi kontak.');
    }
  }

  String _resolveUrl(String value, String type) {
    if (type == 'phone' || type == 'tel') {
      return 'tel:${value.replaceAll(RegExp(r'[\s\-()]'), '')}';
    }
    if (type == 'wa' || type == 'whatsapp') {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      final international = digits.startsWith('0')
          ? '62${digits.substring(1)}'
          : digits;
      return 'https://wa.me/$international';
    }
    if (type == 'email') {
      return 'mailto:$value';
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return 'https://${value.replaceFirst(RegExp(r'^www\.'), '')}';
  }
}
