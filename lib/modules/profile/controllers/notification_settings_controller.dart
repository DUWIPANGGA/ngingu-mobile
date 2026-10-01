import 'package:get/get.dart';

import '../../../core/models/notification_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';

/// Preferensi kanal notifikasi (API.md §8.4 — §8.5, FR-06.6).
///
/// `GET /api/notification-settings` → 7 baris `NotificationSetting`;
/// `PUT /api/notification-settings` → `{settings: [{type, via_push, via_email, via_inapp}]}`.
class NotificationSettingsController extends GetxController {
  final settings = <NotificationSetting>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final needsLogin = false.obs;
  final errorMessage = Rxn<String>();

  List<NotificationSetting> _original = const [];

  bool get isDirty {
    if (settings.length != _original.length) return true;
    for (var i = 0; i < settings.length; i++) {
      final a = settings[i];
      final b = _original[i];
      if (a.type != b.type ||
          a.viaPush != b.viaPush ||
          a.viaEmail != b.viaEmail ||
          a.viaInapp != b.viaInapp) {
        return true;
      }
    }
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    if (!AuthService.isAuthed) {
      needsLogin.value = true;
      return;
    }
    isLoading.value = true;
    final res = await ApiClient.get<dynamic>('/notification-settings');
    isLoading.value = false;
    if (res.statusCode == 401 || res.statusCode == 403) {
      needsLogin.value = true;
      return;
    }
    if (res.success && res.data is List) {
      needsLogin.value = false;
      errorMessage.value = null;
      _apply(res.data as List);
    } else {
      errorMessage.value = res.errorText;
    }
  }

  void toggle(String type, String channel, bool value) {
    final index = settings.indexWhere((s) => s.type == type);
    if (index < 0) return;
    final current = settings[index];
    final updated = channel == 'inapp'
        ? current.copyWith(viaInapp: value)
        : channel == 'push'
            ? current.copyWith(viaPush: value)
            : current.copyWith(viaEmail: value);
    settings[index] = updated;
    settings.refresh();
  }

  Future<void> save() async {
    if (!isDirty || isSaving.value) return;
    isSaving.value = true;
    final res = await ApiClient.put<dynamic>(
      '/notification-settings',
      data: {
        'settings': settings.map((s) => s.toRequest()).toList(),
      },
    );
    isSaving.value = false;
    if (res.success) {
      if (res.data is List) _apply(res.data as List);
      AppTheme.success('Berhasil', 'Pengaturan notifikasi disimpan');
    } else if (res.statusCode == 401 || res.statusCode == 403) {
      needsLogin.value = true;
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  void _apply(List<dynamic> rows) {
    final parsed = rows.map(NotificationSetting.fromJson).toList();
    settings.assignAll(parsed);
    _original = List<NotificationSetting>.from(parsed);
  }
}
