import 'package:get/get.dart';

import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';

/// Profil publik pengguna lain — `GET /api/users/{id}` (API.md §7.10, FR-08.4).
class PublicProfileController extends GetxController {
  final isLoading = false.obs;
  final profile = Rxn<PublicProfile>();
  final errorMessage = Rxn<String>();

  String userId = '';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      userId = '${args['id'] ?? ''}';
    } else if (args != null) {
      userId = '$args';
    }
    fetch();
  }

  Future<void> fetch() async {
    if (userId.isEmpty) {
      errorMessage.value = 'Profil pengguna tidak ditemukan.';
      return;
    }
    isLoading.value = true;
    final res = await ApiClient.get<dynamic>('/users/$userId');
    isLoading.value = false;
    if (res.success && res.data is Map<String, dynamic>) {
      profile.value = PublicProfile.fromJson(res.data);
      errorMessage.value = null;
    } else {
      errorMessage.value = res.errorText;
    }
  }
}
