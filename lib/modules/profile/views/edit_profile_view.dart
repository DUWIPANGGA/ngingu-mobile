import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_fields.dart';
import '../../../core/widgets/app_feedback.dart';
import '../controllers/edit_profile_controller.dart';

/// Form ubah profil: foto, nama, bio, provinsi, jenis ikan (FR-08.3).
class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.page,
      appBar: AppBar(title: const Text('Ubah Profil')),
      body: SafeArea(
        child: Obx(() {
          final picked = controller.avatarPicked.value;
          final current = AuthService.currentUser.value;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: picked != null
                            ? CircleAvatar(
                                radius: 48,
                                backgroundImage: FileImage(picked),
                              )
                            : AppAvatar(
                                url: current?.avatarUrl,
                                name: current?.name ?? 'Ngingu',
                                radius: 48,
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: AppColors.primary,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: controller.pickAvatar,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.camera_alt_outlined,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: controller.pickAvatar,
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(
                      picked == null ? 'Pilih Foto Profil' : 'Ganti Foto',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const Text(
                  'JPG, PNG, atau WEBP — maksimal 2 MB',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textLight),
                ),
                if (controller.formError.value != null) ...[
                  const SizedBox(height: 16),
                  AppBanner(
                    icon: Icons.error_outline,
                    color: AppColors.danger,
                    message: controller.formError.value!,
                  ),
                ],
                const SizedBox(height: 22),
                AppTextField(
                  label: 'Nama',
                  required: true,
                  controller: controller.nameController,
                  hint: 'Nama lengkap',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  errorText: controller.nameError.value,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Bio',
                  controller: controller.bioController,
                  hint: 'Ceritakan sedikit tentang Anda dan tambak Anda',
                  maxLines: 4,
                  minLines: 3,
                  errorText: controller.bioError.value,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${controller.bioLength.value}/${EditProfileController.bioMax}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: controller.bioLength.value >
                              EditProfileController.bioMax - 20
                          ? AppColors.danger
                          : AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Provinsi',
                  controller: controller.provinceController,
                  hint: 'Contoh: Jawa Barat',
                  prefixIcon: Icons.place_outlined,
                  textInputAction: TextInputAction.next,
                  errorText: controller.provinceError.value,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Jenis Ikan',
                  controller: controller.fishTypesController,
                  hint: 'Pisahkan dengan koma — Contoh: Lele, Nila, Udang',
                  prefixIcon: Icons.set_meal_outlined,
                  textInputAction: TextInputAction.done,
                  errorText: controller.fishTypesError.value,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Simpan Perubahan',
                  loading: controller.isLoading.value,
                  onPressed:
                      controller.isLoading.value ? null : controller.save,
                ),
                if (picked != null) ...[
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Batalkan Foto Baru',
                    onPressed: () => controller.avatarPicked.value = null,
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}
