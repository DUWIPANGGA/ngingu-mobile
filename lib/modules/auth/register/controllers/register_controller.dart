import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/app_routes.dart';

class RegisterController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;
  final isFormValid = false.obs;
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    for (final c in [nameController, emailController, passwordController, confirmPasswordController]) {
      c.addListener(_validate);
    }
  }

  void _validate() {
    isFormValid.value = nameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        passwordController.text.length >= 8 &&
        confirmPasswordController.text == passwordController.text;
  }

  void togglePasswordVisibility() => isPasswordHidden.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordHidden.toggle();

  String? get passwordError {
    final p = passwordController.text;
    if (p.isEmpty) return null;
    if (p.length < 8) return 'Minimal 8 karakter';
    return null;
  }

  String? get confirmError {
    final c = confirmPasswordController.text;
    if (c.isEmpty || passwordController.text.isEmpty) return null;
    if (c != passwordController.text) return 'Password tidak sama';
    return null;
  }

  /// `POST /api/register` (API.md Ã‚Â§3.1).
  Future<void> register() async {
    if (!isFormValid.value || isLoading.value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    final res = await ApiClient.post<dynamic>(
      '/register',
      data: {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text,
        'password_confirmation': confirmPasswordController.text,
      },
    );
    isLoading.value = false;
    if (res.success && res.data is Map<String, dynamic>) {
      await AuthService.setSession(AuthSession.fromJson(res.data));
      AppTheme.success('Berhasil', res.message.isNotEmpty ? res.message : 'Registrasi berhasil');
      Get.offAllNamed(Routes.mainNavigation);
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  void goToLogin() => Get.back();

  /// `POST /api/auth/google` — akun baru otomatis didaftarkan backend,
  /// akun lama langsung login (satu tombol untuk daftar + masuk).
  Future<void> registerWithGoogle() async {
    if (isGoogleLoading.value || isLoading.value) return;
    isGoogleLoading.value = true;
    try {
      final idToken = await GoogleAuthService.signInAndGetIdToken();
      if (idToken == null) return; // user batal pilih akun
      final res = await ApiClient.post<dynamic>(
        '/auth/google',
        data: {'id_token': idToken},
      );
      if (res.success && res.data is Map<String, dynamic>) {
        await AuthService.setSession(AuthSession.fromJson(res.data));
        AppTheme.success('Berhasil', 'Pendaftaran dengan Google berhasil');
        Get.offAllNamed(Routes.mainNavigation);
      } else {
        AppTheme.error('Gagal', res.errorText);
      }
    } catch (e) {
      AppTheme.error('Gagal', GoogleAuthService.friendlyErrorMessage(e));
    } finally {
      isGoogleLoading.value = false;
    }
  }

  @override
  void onClose() {
    for (final c in [nameController, emailController, passwordController, confirmPasswordController]) {
      c.removeListener(_validate);
      c.dispose();
    }
    super.onClose();
  }
}
