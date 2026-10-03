import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/pond_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_fields.dart';
import '../../ponds/widgets/pond_common.dart';
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
          _pondSection(),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Jenis Ikan',
            controller: controller.fishTypeController,
            hint: 'Lele, Nila, Gurame, Udang…',
            prefixIcon: Icons.pets_outlined,
            textInputAction: TextInputAction.done,
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

  /// Pilihan kolam: tanpa kolam selalu tersedia, daftar kolam user bila
  /// ada, plus jalan pintas tambah kolam bila daftar masih kosong.
  Widget _pondSection() {
    return Obx(() {
      final loading =
          controller.pondsLoading.value && controller.ponds.isEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Kolam (opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (!loading && controller.ponds.isNotEmpty)
                TextButton(
                  onPressed: controller.openPondForm,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '＋ Kolam baru',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (loading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Memuat kolam…',
                style: TextStyle(
                    fontSize: 14.5, color: AppColors.textSecondary),
              ),
            )
          else if (controller.ponds.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.water_outlined,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Scan tanpa kolam',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Belum ada kolam. Hasil scan tetap tersimpan, '
                    'tapi tren kesehatan per tambak butuh kolam.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: 'Buat Kolam',
                    icon: Icons.add_rounded,
                    expand: false,
                    onPressed: controller.openPondForm,
                  ),
                ],
              ),
            )
          else
            _pondDropdown(),
          if (!loading && controller.ponds.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Pilih kolam asal ikan, atau biarkan "Tanpa kolam".',
              style: TextStyle(fontSize: 11.5, color: AppColors.textLight),
            ),
          ],
          Obx(() {
            final selected = controller.selectedPond;
            if (selected == null) return const SizedBox.shrink();
            return _selectedPondCard(selected);
          }),
        ],
      );
    });
  }

  /// Kartu ringkasan kolam terpilih — gaya sama seperti kartu Tanpa kolam.
  Widget _selectedPondCard(Pond pond) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.softGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_outlined,
                    size: 18, color: AppColors.secondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pond.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Kolam dipakai untuk scan ini',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (pond.healthScore != null)
                HealthScoreRing(score: pond.healthScore, size: 44),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (pond.areaM2 != null)
                PondInfoChip(
                  icon: Icons.straighten_outlined,
                  label: '${idNumber(pond.areaM2!)} m²',
                ),
              if (pond.capacity != null)
                PondInfoChip(
                  icon: Icons.group_outlined,
                  label: '${idNumber(pond.capacity!)} ekor',
                ),
              for (final fish in pond.fishTypes.take(3))
                PondInfoChip(icon: Icons.pets_outlined, label: fish),
              if (pond.scansCount != null)
                PondInfoChip(
                  icon: Icons.center_focus_weak,
                  label: '${pond.scansCount} scan',
                ),
            ],
          ),
          if ((pond.locationLabel ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined,
                    size: 14, color: AppColors.textLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    pond.locationLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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
