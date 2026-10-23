import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/app_fields.dart';
import '../controllers/pond_form_controller.dart';

/// Form tambah/ubah tambak (FR-08.1) — field sesuai API.md §7.3/§7.4,
/// lokasi koordinat opsional lewat peta satelit: marker default di lokasi
/// saat ini (fallback Indramayu), bisa digeser/diketuk manual.
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 260,
                          child: FlutterMap(
                            mapController: controller.mapController,
                            options: MapOptions(
                              initialCenter: PondFormController.indramayuCenter,
                              initialZoom: 11,
                              onMapReady: controller.onMapReady,
                              onTap: controller.onMapTap,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all &
                                    ~InteractiveFlag.rotate,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                userAgentPackageName: 'ngingu.duvi.com',
                                maxNativeZoom: 19,
                              ),
                              if (hasCoords)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(lat, lng),
                                      width: 44,
                                      height: 44,
                                      child: GestureDetector(
                                        onPanUpdate: controller.onMarkerDrag,
                                        child: const Icon(
                                          Icons.place,
                                          size: 44,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 6,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const RichAttributionWidget(
                                attributions: [
                                  TextSourceAttribution(
                                      'Esri, Maxar, Earthstar Geographics'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            hasCoords
                                ? Icons.check_circle_outline
                                : Icons.touch_app_outlined,
                            size: 16,
                            color: hasCoords
                                ? AppColors.secondary
                                : AppColors.textLight,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hasCoords
                                  ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)} • ${_viaLabel(controller.pickedVia.value)}'
                                  : 'Geser marker atau ketuk peta untuk memilih titik.',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (hasCoords)
                            TextButton(
                              onPressed: controller.clearLocation,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Hapus',
                                  style: TextStyle(fontSize: 12.5)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SecondaryButton(
                        label: controller.isLocating.value
                            ? 'Mencari lokasi...'
                            : 'Gunakan lokasi saya',
                        icon: Icons.my_location,
                        expand: false,
                        onPressed: controller.isLocating.value
                            ? null
                            : controller.captureLocation,
                      ),
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

  /// Keterangan asal titik pada readout koordinat.
  String _viaLabel(String? via) => switch (via) {
        'gps' => 'lokasi saat ini',
        'manual' => 'pilih manual',
        'saved' => 'tersimpan',
        _ => 'dipilih',
      };
}
