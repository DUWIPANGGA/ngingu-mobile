import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_fields.dart';
import '../../../../core/widgets/ngingu_logo.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Center(child: NginguLogo(size: 76, animate: false)),
                const SizedBox(height: 20),
                const Text(
                  'Masuk ke Ngingu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lanjutkan prediksi penyakit ikan dan diskusi tambakmu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 30),
                AppTextField(
                  label: 'Email',
                  controller: controller.emailController,
                  hint: 'nama@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.mail_outline,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 16),
                Obx(() => AppTextField(
                      label: 'Password',
                      controller: controller.passwordController,
                      hint: 'Minimal 8 karakter',
                      obscure: controller.isPasswordHidden.value,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.lock_outline,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => controller.login(),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Obx(() => Checkbox(
                          value: controller.rememberMe.value,
                          onChanged: (_) => controller.toggleRememberMe(),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        )),
                    const Text('Ingat saya',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const Spacer(),
                    TextButton(
                      onPressed: controller.goToForgotPassword,
                      child: const Text(
                        'Lupa password?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(() => PrimaryButton(
                      label: 'Masuk',
                      loading: controller.isLoading.value,
                      onPressed:
                          controller.isFormValid.value ? controller.login : null,
                    )),
                const SizedBox(height: 22),
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
                const SizedBox(height: 22),
                Obx(() => OutlinedButton.icon(
                      onPressed: controller.isGoogleLoading.value ||
                              controller.isLoading.value
                          ? null
                          : controller.loginWithGoogle,
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
                          : const Icon(Icons.g_mobiledata_rounded,
                              size: 28, color: AppColors.textPrimary),
                      label: const Text(
                        'Lanjutkan dengan Google',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    )),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: controller.loginAsGuest,
                  child: const Text(
                    'Jelajahi sebagai Tamu',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun?',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: controller.goToRegister,
                      child: const Text(
                        'Daftar',
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
