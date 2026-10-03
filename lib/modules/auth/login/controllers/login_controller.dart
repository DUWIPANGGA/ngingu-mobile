import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/google_auth_service.dart';
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

  /// `POST /api/auth/google` (API.md §3.2) — backend expects `id_token`.
  Future<void> loginWithGoogle() async {
    if (isGoogleLoading.value || isLoading.value) return;
    isGoogleLoading.value = true;
    try {
      final idToken = await GoogleAuthService.signInAndGetIdToken();
      if (idToken == null) return; // cancelled
      final res = await ApiClient.post<dynamic>(
        '/auth/google',
        data: {'id_token': idToken},
      );
      await _handleSession(res, 'Login dengan Google berhasil');
    } catch (e) {
      AppTheme.error('Gagal', GoogleAuthService.friendlyErrorMessage(e));
    } finally {
      isGoogleLoading.value = false;
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
