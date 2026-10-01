import 'package:get/get.dart';

import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';

/// Profil tab — session state, refresh (API.md §7.7 / §7.10) and logout (§3.4).
class ProfileController extends GetxController {
  final isLoading = false.obs;

  /// Extra public payload for the signed-in user (`GET /api/users/{id}`) —
  /// badges + contribution counts that `GET /api/user` does not return.
  final publicInfo = Rxn<PublicProfile>();

  final errorMessage = Rxn<String>();

  bool get isGuest => AuthService.isGuest;
  bool get isAuthed => AuthService.isAuthed;

  @override
  void onInit() {
    super.onInit();
    refreshProfile();
  }

  /// `GET /api/user` (API.md §7.7) → `AuthService.updateUser`, then the public
  /// payload for badges / stats (API.md §7.10).
  Future<void> refreshProfile() async {
    if (!isAuthed) return;
    isLoading.value = true;
    final res = await ApiClient.get<dynamic>('/user');
    if (res.success && res.data is Map<String, dynamic>) {
      final updated = User.fromJson(res.data);
      await AuthService.updateUser(updated);
      errorMessage.value = null;
      await _fetchPublicInfo(updated.id);
    } else {
      errorMessage.value =
          AuthService.currentUser.value == null ? res.errorText : null;
    }
    isLoading.value = false;
  }

  Future<void> _fetchPublicInfo(String id) async {
    if (id.isEmpty) return;
    final res = await ApiClient.get<dynamic>('/users/$id');
    if (res.success && res.data is Map<String, dynamic>) {
      publicInfo.value = PublicProfile.fromJson(res.data);
    }
  }

  /// `POST /api/logout` (API.md §3.4) — failures are ignored, local session is
  /// always cleared.
  Future<void> logout() async {
    await ApiClient.post<dynamic>('/logout');
    publicInfo.value = null;
    errorMessage.value = null;
    await AuthService.clearSession();
    Get.offAllNamed(Routes.login);
  }
}
