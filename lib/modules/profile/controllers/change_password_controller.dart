import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

/// Ubah password — `PUT /api/user/password`
/// {current_password, password, password_confirmation}.
///
/// NOTE: endpoint ini tidak tercantum di API.md v1.0.2 (gap kontrak) —
/// mengikuti pola Laravel/Sanctum standar yang dipakai backend.
class ChangePasswordController extends GetxController {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  final obscureCurrent = true.obs;
  final obscureNew = true.obs;
  final obscureConfirm = true.obs;
  final isLoading = false.obs;

  final currentError = Rxn<String>();
  final newError = Rxn<String>();
  final confirmError = Rxn<String>();

  static const int minLength = 8;

  bool get canSubmit =>
      currentController.text.isNotEmpty &&
      newController.text.isNotEmpty &&
      confirmController.text.isNotEmpty;

  void toggleCurrent() => obscureCurrent.toggle();
  void toggleNew() => obscureNew.toggle();
  void toggleConfirm() => obscureConfirm.toggle();

  Future<void> save() async {
    if (isLoading.value) return;
    FocusManager.instance.primaryFocus?.unfocus();

    currentError.value = null;
    newError.value = null;
    confirmError.value = null;

    var invalid = false;
    if (currentController.text.isEmpty) {
      currentError.value = 'Password saat ini wajib diisi.';
      invalid = true;
    }
    if (newController.text.length < minLength) {
      newError.value = 'Password baru minimal $minLength karakter.';
      invalid = true;
    } else if (newController.text == currentController.text) {
      newError.value = 'Password baru tidak boleh sama dengan yang lama.';
      invalid = true;
    }
    if (confirmController.text != newController.text) {
      confirmError.value = 'Konfirmasi password tidak sama.';
      invalid = true;
    }
    if (invalid) return;

    isLoading.value = true;
    final res = await ApiClient.put<dynamic>(
      '/user/password',
      data: {
        'current_password': currentController.text,
        'password': newController.text,
        'password_confirmation': confirmController.text,
      },
    );
    isLoading.value = false;

    if (res.success) {
      currentController.clear();
      newController.clear();
      confirmController.clear();
      AppTheme.success('Berhasil', 'Password berhasil diubah');
      Get.back();
      return;
    }

    currentError.value = res.fieldError('current_password');
    newError.value = res.fieldError('password');
    confirmError.value = res.fieldError('password_confirmation');
    if (!res.hasFieldErrors) {
      if (res.statusCode == 401 || res.statusCode == 403) {
        currentError.value = 'Password saat ini salah.';
      } else {
        AppTheme.error('Gagal', res.errorText);
      }
    }
  }

  @override
  void onClose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}
