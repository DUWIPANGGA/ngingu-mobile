import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/app_fields.dart';
import '../controllers/pond_form_controller.dart';

/// Form tambah/ubah tambak (FR-08.1) — field sesuai API.md §7.3/§7.4,
/// lokasi koordinat opsional via tombol "Ambil lokasi saat ini".
class PondFormView extends GetView<PondFormController> {
  const PondFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(controller.isEdit ? 'Ubah Tambak' : 'Tambah Tambak'),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isEdit && controller.isLoading.value) {
            return const LoadingState(message: 'Memuat data tambak...');
          }
          if (controller.isEdit && controller.loadFailed.value) {
            return ErrorState(
              message: controller.formError.value ?? 'Gagal memuat tambak.',
              onRetry: controller.loadPond,
            );
          }
          return _form(context);
        }),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Nama tambak',
                  required: true,
                  controller: controller.nameController,
                  hint: 'Contoh: Kolam A',
                  prefixIcon: Icons.water_outlined,
                  textInputAction: TextInputAction.next,
                  errorText: controller.nameError.value,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Lokasi',
                  controller: controller.locationController,
                  hint: 'Contoh: Indramayu, Jawa Barat',
                  prefixIcon: Icons.place_outlined,
                  textInputAction: TextInputAction.next,
                  errorText: controller.locationLabelError.value,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Luas (m²)',
                        controller: controller.areaController,
                        hint: '120',
                        prefixIcon: Icons.straighten_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        errorText: controller.areaError.value,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Kapasitas (ekor)',
                        controller: controller.capacityController,
                        hint: '5000',
                        prefixIcon: Icons.group_outlined,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        errorText: controller.capacityError.value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Jenis ikan',
                  controller: controller.fishTypesController,
                  hint: 'Lele, Nila, Gurame',
                  prefixIcon: Icons.pets_outlined,
                  textInputAction: TextInputAction.next,
                  errorText: controller.fishTypesError.value,
                ),
                if (controller.fishChips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final fish in controller.fishChips)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.softSky,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            fish,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Deskripsi',
                  controller: controller.descriptionController,
                  hint: 'Catatan tambahan tentang tambak (opsional)',
                  prefixIcon: Icons.notes_outlined,
                  maxLines: 4,
                  minLines: 3,
                  textInputAction: TextInputAction.newline,
                  errorText: controller.descriptionError.value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Koordinat tambak (opsional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dipakai untuk peta sebaran penyakit. Bisa dilewati.',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final lat = controller.locationLat.value;
                  final lng = controller.locationLng.value;
                  final hasCoords = lat != null && lng != null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SecondaryButton(
                        label: controller.isLocating.value
                            ? 'Mencari lokasi...'
                            : 'Ambil lokasi saat ini',
                        icon: Icons.my_location,
                        expand: false,
                        onPressed: controller.isLocating.value
                            ? null
                            : controller.captureLocation,
                      ),
                      if (hasCoords) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 16, color: AppColors.secondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: controller.clearLocation,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Hapus',
                                  style: TextStyle(fontSize: 12.5)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final error = controller.formError.value;
            if (error == null) return const SizedBox.shrink();
            return AppBanner(
              message: error,
              icon: Icons.error_outline,
              color: AppColors.danger,
            );
          }),
          const SizedBox(height: 16),
          Obx(() => PrimaryButton(
                label: controller.isEdit ? 'Simpan Perubahan' : 'Tambah Tambak',
                icon: Icons.check_rounded,
                loading: controller.isSaving.value,
                onPressed: controller.save,
              )),
        ],
      ),
    );
  }
}
