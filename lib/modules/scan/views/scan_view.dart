import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_fields.dart';
import '../../../routes/app_routes.dart';
import '../controllers/scan_controller.dart';

/// Tab Scan (FR-02): pilih 1–5 foto, kolam & jenis ikan opsional,
/// lalu kirim ke `POST /api/scans`.
class ScanView extends GetView<ScanController> {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Scan Penyakit'),
        actions: [
          IconAction(
            icon: Icons.history_outlined,
            tooltip: 'Riwayat scan',
            onPressed: controller.goToHistory,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (!AuthService.isAuthed) return _loginCard();
          controller.ensurePonds();
          return _form();
        }),
      ),
    );
  }

  // ── tamu / belum masuk ───────────────────────────────────────────────────

  Widget _loginCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration:
                    const BoxDecoration(color: AppColors.softSky, shape: BoxShape.circle),
                child: const Icon(Icons.center_focus_weak_rounded,
                    size: 34, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Masuk untuk mulai scan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Foto ikanmu dan biarkan AI Ngingu memprediksi penyakitnya '
                'lengkap dengan skor keyakinan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Masuk',
                icon: Icons.login_rounded,
                onPressed: () => Get.toNamed(Routes.login),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── form scan ────────────────────────────────────────────────────────────

  Widget _form() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(title: 'Foto Ikan'),
              Text(
                '${controller.picked.length}/${ScanController.maxImages}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          _photoGrid(),
          const SizedBox(height: 8),
          const Text(
            'JPG/PNG/WEBP, maksimal 10 MB per foto. '
            'Foto akan dikompresi otomatis sebelum diunggah.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textLight, height: 1.5),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Informasi Tambahan'),
          const SizedBox(height: 4),
          const Text(
            'Kolam',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          _pondDropdown(),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Jenis Ikan',
            controller: controller.fishTypeController,
            hint: 'Lele, Nila, Gurame, Udang…',
            prefixIcon: Icons.pets_outlined,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 10),
          // Statik saja: tidak ada snackbar/pesan saat GPS tidak tersedia —
          // lokasi bersifat opsional (FR-07.3).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: AppColors.textLight),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Lokasi GPS dipakai untuk peta sebaran penyakit di sekitarmu. Opsional — scan tetap jalan tanpa lokasi.',
                  style: TextStyle(
                      fontSize: 11.5, color: AppColors.textLight, height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => PrimaryButton(
                label: 'Mulai Scan',
                icon: Icons.center_focus_weak_rounded,
                loading: controller.isSubmitting.value,
                onPressed:
                    controller.picked.isEmpty ? null : controller.submit,
              )),
          const SizedBox(height: 12),
          const Text(
            'Scan diproses secara asinkron. Hasil biasanya siap kurang dari 10 detik.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.textLight, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _photoGrid() {
    final files = controller.picked;
    return Column(
      children: [
        if (files.isEmpty)
          InkWell(
            onTap: controller.openImageSourceSheet,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1.4,
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 30, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text(
                    'Ambil atau pilih foto ikan',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
            children: [
              for (var i = 0; i < files.length; i++)
                _thumbnail(files[i].path, i),
              if (files.length < ScanController.maxImages) _addTile(),
            ],
          ),
      ],
    );
  }

  Widget _thumbnail(String path, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(path), fit: BoxFit.cover),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () => controller.removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addTile() {
    return InkWell(
      onTap: controller.openImageSourceSheet,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.4,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 30, color: AppColors.primary),
            SizedBox(height: 4),
            Text(
              'Tambah foto',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pondDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedPondId.value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text(
                'Tanpa kolam',
                style: TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
              ),
            ),
            for (final pond in controller.ponds)
              DropdownMenuItem(
                value: pond.id,
                child: Text(
                  pond.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
                ),
              ),
          ],
          onChanged: (value) =>
              controller.selectedPondId.value = value ?? '',
        ),
      ),
    );
  }
}
