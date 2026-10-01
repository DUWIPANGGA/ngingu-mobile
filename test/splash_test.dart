import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ngingu_apps/core/network/api_client.dart';
import 'package:ngingu_apps/core/services/auth_service.dart';
import 'package:ngingu_apps/modules/splash/controllers/splash_controller.dart';
import 'package:ngingu_apps/modules/splash/views/splash_view.dart';
import 'package:ngingu_apps/routes/app_routes.dart';

/// Splash HARUS selalu meninggalkan layar — kasus macet (stuck) terdeteksi
/// di sini sebagai pumpAndSettle timeout / exception.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(ApiClient.init);

  Widget buildApp() => GetMaterialApp(
        initialRoute: Routes.splash,
        defaultTransition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
        getPages: [
          GetPage(
            name: Routes.splash,
            page: () => const SplashView(),
            binding: BindingsBuilder(() {
              // Eager, sama seperti app_pages.dart — lazyPut tidak akan jalan
              // selama SplashView tidak menyentuh `controller`.
              Get.put(SplashController());
            }),
          ),
          GetPage(name: Routes.onboarding, page: () => const Text('ONBOARDING')),
          GetPage(name: Routes.welcome, page: () => const Text('WELCOME')),
          GetPage(name: Routes.login, page: () => const Text('LOGIN')),
          GetPage(name: Routes.mainNavigation, page: () => const Text('HOME')),
        ],
      );

  Future<void> runSplash(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    // Spinner splash meng-schedule frame terus-menerus; loop berhenti hanya
    // saat splash benar-benar sudah tidak ada di tumpukan route.
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (!tester.binding.hasScheduledFrame) return;
    }
    fail('Splash masih tampil setelah 30 detik virtual — STUCK.');
  }

  testWidgets('instalasi baru → onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.init();

    await runSplash(tester);

    expect(find.byType(SplashView), findsNothing);
    expect(find.text('ONBOARDING'), findsOneWidget);
  });

  testWidgets('pernah onboarding → welcome', (tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
    await AuthService.init();

    await runSplash(tester);

    expect(find.byType(SplashView), findsNothing);
    expect(find.text('WELCOME'), findsOneWidget);
  });

  testWidgets('mode tamu → langsung ke shell', (tester) async {
    SharedPreferences.setMockInitialValues({'is_guest': true});
    await AuthService.init();

    await runSplash(tester);

    expect(find.byType(SplashView), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('sesi lama + jaringan mati → tetap masuk (tidak stuck)',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'auth_token': '2|expired-token',
      'auth_user':
          '{"id":"1","name":"Budi","email":"budi@example.com","role":"user"}',
    });
    await AuthService.init();
    expect(AuthService.isLoggedIn, isTrue);

    await runSplash(tester);

    // /user gagal (mock HTTP 400, bukan 401) → offline friendly: masuk shell.
    expect(find.byType(SplashView), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });
}
