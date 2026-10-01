import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_fields.dart';
import '../controllers/forgot_password_controller.dart';

/// Email-link reset (API.md §3.5/§3.6): step 1 requests the link,
/// step 2 pastes the token from the email + sets the new password.
class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

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
            'Lupa Password',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Obx(() => controller.step.value == 1
                ? _requestStep()
                : _resetStep()),
          ),
        ),
      ),
    );
  }

  Widget _requestStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softSky,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.mark_email_read_outlined, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Masukkan email akunmu. Kami akan mengirim tautan reset yang berlaku 60 menit.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: 'Email',
          controller: controller.emailController,
          hint: 'nama@email.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.mail_outline,
          required: true,
          onSubmitted: (_) => controller.sendResetLink(),
        ),
        const SizedBox(height: 26),
        Obx(() => PrimaryButton(
              label: 'Kirim Tautan Reset',
              loading: controller.isLoading.value,
              onPressed: controller.canSubmitEmail
                  ? controller.sendResetLink
                  : null,
            )),
      ],
    );
  }

  Widget _resetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: AppColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Text('Tautan dikirim',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontSize: 14)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Kami mengirim tautan ke ${controller.emailSentTo.value}. '
                'Buka email, salin kode resetnya, lalu tempel di bawah.',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: 'Kode Reset dari Email',
          controller: controller.tokenController,
          hint: 'Tempel kode / token di sini',
          prefixIcon: Icons.vpn_key_outlined,
          required: true,
        ),
        const SizedBox(height: 16),
        Obx(() => AppTextField(
              label: 'Password Baru',
              controller: controller.newPasswordController,
              hint: 'Minimal 8 karakter',
              obscure: controller.isNewPasswordHidden.value,
              prefixIcon: Icons.lock_outline,
              errorText: controller.passwordError,
              suffix: IconButton(
                icon: Icon(
                  controller.isNewPasswordHidden.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: controller.toggleNewPasswordVisibility,
              ),
            )),
        const SizedBox(height: 16),
        Obx(() => AppTextField(
              label: 'Konfirmasi Password Baru',
              controller: controller.confirmPasswordController,
              hint: 'Ulangi password baru',
              obscure: controller.isConfirmPasswordHidden.value,
              prefixIcon: Icons.lock_outline,
              errorText: controller.confirmError,
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
              label: 'Simpan Password Baru',
              loading: controller.isLoading.value,
              onPressed: controller.canReset ? controller.resetPassword : null,
            )),
        TextButton(
          onPressed: controller.backToStep1,
          child: const Text(
            'Ganti email / kirim ulang',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
