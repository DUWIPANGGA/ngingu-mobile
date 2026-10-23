import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/ngingu_logo.dart';
import '../../../routes/app_routes.dart';

/// Landing page after onboarding: login / register / continue as guest.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 3),
                const Center(child: NginguLogo(size: 180, animate: false)),
                const SizedBox(height: 28),
                const Text(
                  'Deteksi penyakit ikan sejak dini,\nrawat tambakmu bersama komunitas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const Spacer(flex: 3),
                PrimaryButton(
                  label: 'Masuk',
                  onPressed: () => Get.toNamed(Routes.login),
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Daftar Akun Baru',
                  onPressed: () => Get.toNamed(Routes.register),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await AuthService.setGuestMode();
                    Get.offAllNamed(Routes.mainNavigation);
                  },
                  child: const Text(
                    'Jelajahi sebagai Tamu',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
