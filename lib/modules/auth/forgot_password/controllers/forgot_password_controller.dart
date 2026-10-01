import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/app_routes.dart';

class ForgotPasswordController extends GetxController {
  final emailController = TextEditingController();
  final tokenController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final step = 1.obs; // 1 = request link, 2 = paste token + new password
  final isLoading = false.obs;
  final isNewPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;

  final emailSentTo = ''.obs;

  bool get canSubmitEmail => emailController.text.trim().isNotEmpty;
  bool get canReset => tokenController.text.trim().isNotEmpty &&
      newPasswordController.text.length >= 8 &&
      confirmPasswordController.text == newPasswordController.text;

  String? get passwordError {
    final p = newPasswordController.text;
    if (p.isEmpty) return null;
    if (p.length < 8) return 'Minimal 8 karakter';
    return null;
  }

  String? get confirmError {
    final c = confirmPasswordController.text;
    if (c.isEmpty || newPasswordController.text.isEmpty) return null;
    if (c != newPasswordController.text) return 'Password tidak sama';
    return null;
  }

  void toggleNewPasswordVisibility() => isNewPasswordHidden.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordHidden.toggle();

  /// `POST /api/forgot-password` (API.md Ã‚Â§3.5) Ã¢â‚¬â€ always 202 (anti-enumeration).
  Future<void> sendResetLink() async {
    if (!canSubmitEmail || isLoading.value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    final res = await ApiClient.post<dynamic>(
      '/forgot-password',
      data: {'email': emailController.text.trim()},
    );
    isLoading.value = false;
    if (res.success || res.statusCode == 202) {
      emailSentTo.value = emailController.text.trim();
      step.value = 2;
      AppTheme.success('Berhasil', 'Tautan reset dikirim ke email. Periksa inbox (dan spam).');
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  /// `POST /api/reset-password` (API.md Ã‚Â§3.6).
  Future<void> resetPassword() async {
    if (!canReset || isLoading.value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    final res = await ApiClient.post<dynamic>(
      '/reset-password',
      data: {
        'token': tokenController.text.trim(),
        'password': newPasswordController.text,
        'password_confirmation': confirmPasswordController.text,
      },
    );
    isLoading.value = false;
    if (res.success) {
      AppTheme.success('Berhasil', 'Password berhasil diubah. Silakan login.');
      backToLogin();
    } else {
      AppTheme.error('Gagal', res.errorText);
    }
  }

  void backToLogin() => Get.offAllNamed(Routes.login);

  void backToStep1() => step.value = 1;

  @override
  void onClose() {
    emailController.dispose();
    tokenController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
