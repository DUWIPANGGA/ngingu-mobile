import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/app_routes.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordHidden = true.obs;
  final rememberMe = true.obs;
  final isFormValid = false.obs;
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;

  /// Client ID Web (client type 3) dari Google Cloud project `ngingu-fd854`.
  /// - Android: dipakai sebagai `serverClientId` (audience `id_token`).
  /// - Web: dipakai sebagai `clientId` (wajib diisi di web, kalau tidak
  ///   `signIn()` langsung gagal).
  /// Override saat build bila perlu:
  /// `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=<id>.apps.googleusercontent.com`
  static const _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '436124496187-j1k910d7spdtdihd0c972bvasa1ku904.apps.googleusercontent.com',
  );

  final _googleSignIn = kIsWeb
      ? GoogleSignIn(
          scopes: const ['email', 'profile'],
          clientId: _webClientId,
          serverClientId: _webClientId,
        )
      : GoogleSignIn(
          scopes: const ['email', 'profile'],
          serverClientId: _webClientId,
        );

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(_validate);
    passwordController.addListener(_validate);
  }

  void _validate() {
    isFormValid.value =
        emailController.text.trim().isNotEmpty && passwordController.text.isNotEmpty;
  }

  void togglePasswordVisibility() => isPasswordHidden.toggle();
  void toggleRememberMe() => rememberMe.toggle();

  /// `POST /api/login` (API.md Ãƒâ€šÃ‚Â§3.3).
  Future<void> login() async {
    if (!isFormValid.value || isLoading.value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    final res = await ApiClient.post<dynamic>(
      '/login',
      data: {
        'email': emailController.text.trim(),
        'password': passwordController.text,
        'remember_me': rememberMe.value,
      },
    );
    isLoading.value = false;
    await _handleSession(res, 'Login berhasil');
  }

  /// `POST /api/auth/google` (API.md Ãƒâ€šÃ‚Â§3.2) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â backend expects `id_token`.
  Future<void> loginWithGoogle() async {
    if (isGoogleLoading.value || isLoading.value) return;
    isGoogleLoading.value = true;
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // cancelled
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        AppTheme.error('Gagal', 'Gagal mendapatkan token Google. Coba lagi.');
        return;
      }
      final res = await ApiClient.post<dynamic>(
        '/auth/google',
        data: {'id_token': idToken},
      );
      await _handleSession(res, 'Login dengan Google berhasil');
    } on PlatformException catch (e) {
      AppTheme.error('Gagal', _googleErrorText(e));
    } catch (e) {
      AppTheme.error('Gagal', 'Login Google gagal. Coba lagi. ($e)');
    } finally {
      isGoogleLoading.value = false;
    }
  }

  /// Terjemahkan error plugin Google (google_sign_in 6.x melempar
  /// `PlatformException`) jadi pesan yang bisa ditindaklanjuti.
  /// `sign_in_failed` di Android hampir selalu berarti package name + SHA-1
  /// belum terdaftar atau tidak cocok di Firebase (ApiException "10").
  String _googleErrorText(PlatformException e) {
    final detail = e.message == null ? e.code : '${e.code} — ${e.message}';
    switch (e.code) {
      case 'canceled':
        return 'Login Google dibatalkan.';
      case 'sign_in_failed':
        return 'Login Google gagal (sign_in_failed). Pastikan aplikasi sudah '
            'terdaftar di Firebase dengan package + SHA-1 yang cocok. '
            'Detail: $detail';
      case 'network_error':
        return 'Jaringan bermasalah saat menghubungi Google. Coba lagi. '
            'Detail: $detail';
      default:
        return 'Login Google gagal. Detail: $detail';
    }
  }

  Future<void> _handleSession(ApiResult res, String successMsg) async {
    if (res.success && res.data is Map<String, dynamic>) {
      await AuthService.setSession(AuthSession.fromJson(res.data));
      AppTheme.success('Berhasil', successMsg);
      Get.offAllNamed(Routes.mainNavigation);
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  /// FR-03.1.5 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â encyclopedia is browsable without an account.
  Future<void> loginAsGuest() async {
    await AuthService.setGuestMode();
    Get.offAllNamed(Routes.mainNavigation);
  }

  void goToRegister() => Get.toNamed(Routes.register);
  void goToForgotPassword() => Get.toNamed(Routes.forgotPassword);

  @override
  void onClose() {
    emailController.removeListener(_validate);
    passwordController.removeListener(_validate);
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
