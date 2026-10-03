import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_fields.dart';
import '../../../../core/widgets/google_logo.dart';
import '../controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Daftar Akun',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Buat akun Ngingu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Satu akun untuk scan penyakit, forum, dan ensiklopedia ikan.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Nama Lengkap',
                  controller: controller.nameController,
                  hint: 'Budi Santoso',
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.person_outline,
                  required: true,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  controller: controller.emailController,
                  hint: 'nama@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.mail_outline,
                  autofillHints: const [AutofillHints.email],
                  required: true,
                ),
                const SizedBox(height: 16),
                Obx(() => AppTextField(
                      label: 'Password',
                      controller: controller.passwordController,
                      hint: 'Minimal 8 karakter',
                      obscure: controller.isPasswordHidden.value,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.lock_outline,
                      errorText: controller.passwordError,
                      suffix: IconButton(
                        icon: Icon(
                          controller.isPasswordHidden.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    )),
                const SizedBox(height: 16),
                Obx(() => AppTextField(
                      label: 'Konfirmasi Password',
                      controller: controller.confirmPasswordController,
                      hint: 'Ulangi password',
                      obscure: controller.isConfirmPasswordHidden.value,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.lock_outline,
                      errorText: controller.confirmError,
                      onSubmitted: (_) => controller.register(),
                      suffix: IconButton(
                        icon: Icon(
                          controller.isConfirmPasswordHidden.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: controller.toggleConfirmPasswordVisibility,
                      ),
                    )),
                const SizedBox(height: 26),
                Obx(() => PrimaryButton(
                      label: 'Daftar',
                      loading: controller.isLoading.value,
                      onPressed:
                          controller.isFormValid.value ? controller.register : null,
                    )),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('atau',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 18),
                Obx(() => OutlinedButton.icon(
                      onPressed: controller.isGoogleLoading.value ||
                              controller.isLoading.value
                          ? null
                          : controller.registerWithGoogle,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: AppColors.border),
                        backgroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: controller.isGoogleLoading.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const GoogleLogo(size: 22),
                      label: const Text(
                        'Daftar dengan Google',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    )),
                const SizedBox(height: 14),
                const Text(
                  'Dengan mendaftar, kamu menyetujui syarat penggunaan dan kebijakan privasi Ngingu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.5),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun?',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: controller.goToLogin,
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
