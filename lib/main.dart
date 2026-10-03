import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'core/network/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await AuthService.init();
  ApiClient.init();

  // Session expired (401) → drop credentials & return to login.
  ApiClient.onUnauthorized = () {
    if (AuthService.isLoggedIn) {
      AuthService.clearSession();
      Get.offAllNamed(Routes.login);
      Get.snackbar(
        'Sesi Berakhir',
        'Silakan masuk kembali untuk melanjutkan.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
      );
    }
  };

  // Badge poller (API.md §9.2 — HTTP polling, no WebSocket).
  await Get.putAsync<NotificationService>(
    () => NotificationService().init(),
    permanent: true,
  );

  // Mode tampilan tersimpan (Terang/Gelap/Ikuti sistem).
  await Get.putAsync<ThemeController>(
    () async {
      final c = ThemeController();
      await c.init();
      return c;
    },
    permanent: true,
  );

  runApp(const NginguApp());
}

class NginguApp extends StatelessWidget {
  const NginguApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Ngingu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200), // SRS §7.6
    );
  }
}
