import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  /// Brand delay minimum sebelum keputusan navigasi (SRS 7.6).
  static const Duration splashDelay = Duration(milliseconds: 1600);

  /// Batas cek sesi online — splash TIDAK BOLEH menunggu timeout Dio (15s).
  static const Duration sessionCheckBudget = Duration(seconds: 4);

  bool _navigated = false;

  @override
  void onInit() {
    super.onInit();
    _decide();
  }

  Future<void> _decide() async {
    try {
      await Future.delayed(splashDelay);

      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      if (AuthService.isGuest) {
        return _go(Routes.mainNavigation);
      }

      if (AuthService.isLoggedIn) {
        // Verify token online; gagal/offline → tetap masuk (offline friendly),
        // 401 → buang sesi dan ke login. Dibatasi [sessionCheckBudget] supaya
        // splash selalu selesai dalam < ~6 detik, berapa pun kondisi jaringan.
        final res = await ApiClient.get<dynamic>('/user')
            .timeout(sessionCheckBudget);
        if (res.statusCode == 401) {
          await AuthService.clearSession();
          return _go(Routes.login);
        }
        return _go(Routes.mainNavigation);
      }

      _go(hasSeenOnboarding ? Routes.welcome : Routes.onboarding);
    } catch (e, st) {
      // Apa pun yang gagal (jaringan, prefs, dsb.) HARUS tetap meninggalkan
      // splash — jangan pernah membiarkan pengguna terjebak di layar ini.
      debugPrint('[Splash] decide gagal: $e\n$st');
      _go(AuthService.isLoggedIn ? Routes.mainNavigation : Routes.welcome);
    }
  }

  /// Navigasi one-shot: aman dari race onUnauthorized (interceptor bisa saja
  /// sudah menavigasi ke login lebih dulu saat /user menjawab 401).
  void _go(String route) {
    if (_navigated) return;
    debugPrint('[Splash] navigasi → $route');
    try {
      Get.offAllNamed(route);
      _navigated = true;
    } catch (e) {
      debugPrint('[Splash] navigasi ke $route GAGAL: $e');
    }
  }
}
