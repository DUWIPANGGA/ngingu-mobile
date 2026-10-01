import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_fields.dart';
import '../../../core/widgets/app_feedback.dart';
import '../controllers/change_password_controller.dart';

/// Form ubah password: 3 field + toggle lihat password + validasi inline.
class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Ubah Password')),
      body: SafeArea(
        child: Obx(() {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppBanner(
                  icon: Icons.shield_outlined,
                  color: AppColors.primary,
                  message:
                      'Gunakan minimal 8 karakter. Setelah disimpan, semua sesi lain akan tetap aktif sesuai kebijakan keamanan akun.',
                ),
                const SizedBox(height: 22),
                AppTextField(
                  label: 'Password Saat Ini',
                  required: true,
                  controller: controller.currentController,
                  obscure: controller.obscureCurrent.value,
                  prefixIcon: Icons.lock_outline,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                  errorText: controller.currentError.value,
                  suffix: IconButton(
                    onPressed: controller.toggleCurrent,
                    icon: Icon(
                      controller.obscureCurrent.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password Baru',
                  required: true,
                  controller: controller.newController,
                  obscure: controller.obscureNew.value,
                  hint: 'Minimal 8 karakter',
                  prefixIcon: Icons.lock_reset_outlined,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  errorText: controller.newError.value,
                  suffix: IconButton(
                    onPressed: controller.toggleNew,
                    icon: Icon(
                      controller.obscureNew.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Ulangi Password Baru',
                  required: true,
                  controller: controller.confirmController,
                  obscure: controller.obscureConfirm.value,
                  prefixIcon: Icons.lock_outline,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  errorText: controller.confirmError.value,
                  onSubmitted: (_) => controller.save(),
                  suffix: IconButton(
                    onPressed: controller.toggleConfirm,
                    icon: Icon(
                      controller.obscureConfirm.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Simpan Password',
                  loading: controller.isLoading.value,
                  onPressed: controller.canSubmit && !controller.isLoading.value
                      ? controller.save
                      : null,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
