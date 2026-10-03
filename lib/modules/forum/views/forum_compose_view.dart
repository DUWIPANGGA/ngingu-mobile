import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_fields.dart';
import '../controllers/forum_compose_controller.dart';
import '../widgets/forum_category_chip.dart';
import '../widgets/forum_images.dart';

/// New-question form (FR-05.2, API.md §6.3): title, body, category,
/// optional linked scan and up to 5 photos.
class ForumComposeView extends GetView<ForumComposeController> {
  const ForumComposeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.page,
      appBar: AppBar(title: const Text('Buat Pertanyaan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Judul ────────────────────────────────────────────────
              Obx(
                () => AppTextField(
                  label: 'Judul',
                  required: true,
                  controller: controller.titleController,
                  hint: 'Contoh: Ikan lele muncul bintik putih, kenapa ya?',
                  errorText: controller.titleError.value,
                  onChanged: controller.onTitleChanged,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),

              // ── Isi ──────────────────────────────────────────────────
              Obx(
                () => AppTextField(
                  label: 'Isi',
                  required: true,
                  controller: controller.bodyController,
                  hint: 'Ceritakan kondisi tambak, gejala, dan apa yang sudah dicoba...',
                  minLines: 5,
                  maxLines: 8,
                  errorText: controller.bodyError.value,
                  onChanged: controller.onBodyChanged,
                ),
              ),
              const SizedBox(height: 16),

              // ── Kategori ─────────────────────────────────────────────
              _CategoryField(controller: controller),
              const SizedBox(height: 16),

              // ── Tautan scan ──────────────────────────────────────────
              if (controller.isAuthed) ...[
                const Text('Tautkan ke scan saya',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                const Text(
                  'Opsional — bantu komunitas melihat hasil prediksi Anda.',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                const SizedBox(height: 8),
                _ScanPicker(controller: controller),
                const SizedBox(height: 16),
              ],

              // ── Foto ─────────────────────────────────────────────────
              Row(
                children: [
                  const Text('Foto',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                  const SizedBox(width: 6),
                  Text(
                    'maks. ${ForumComposeController.maxImages}',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(() => controller.images.isEmpty
                  ? _Dropzone(onTap: controller.pickImages)
                  : ForumPickedImages(
                      files: controller.images,
                      onRemove: controller.removeImage,
                      onAdd: controller.pickImages,
                      max: ForumComposeController.maxImages,
                      size: 84,
                    )),
              const SizedBox(height: 26),

              Obx(
                () => PrimaryButton(
                  label: 'Publikasikan',
                  icon: Icons.send_rounded,
                  loading: controller.isSubmitting.value,
                  onPressed:
                      controller.isSubmitting.value ? null : controller.submit,
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Post baru dari akun baru dapat dimoderasi lebih dulu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

void _showCategorySheet(ForumComposeController controller) {
  Get.bottomSheet(
      SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih kategori',
                  style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kategori membantu ahli yang tepat menemukan pertanyaan Anda.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                if (controller.isLoadingCategories.value)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: AppColors.primary),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in controller.categories)
                        ForumCategoryChip.fromCategory(
                          category,
                          selected:
                              controller.selectedCategory.value?.id == category.id,
                          onTap: () {
                            Get.back();
                            controller.selectCategory(category);
                          },
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.white,
    );
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({required this.controller});

  final ForumComposeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final selected = controller.selectedCategory.value;
        final error = controller.categoryError.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('Kategori',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                Text(' *',
                    style: TextStyle(
                        color: AppColors.danger, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: controller.isLoadingCategories.value
                  ? null
                  : () => _showCategorySheet(controller),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: error != null ? AppColors.danger : AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: selected == null
                          ? const Text('Pilih kategori',
                              style: TextStyle(
                                  fontSize: 15, color: AppColors.textLight))
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: ForumCategoryChip.fromCategory(
                                selected,
                                subtle: true,
                              ),
                            ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 22, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(error,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.danger)),
              ),
          ],
        );
      },
    );
  }
}

/// Selected scan chip / picker trigger (FR-05.2.3).
class _ScanPicker extends StatelessWidget {
  const _ScanPicker({required this.controller});

  final ForumComposeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final scan = controller.selectedScan.value;
      if (scan == null) {
        return OutlinedButton.icon(
          onPressed: controller.isLoadingScans.value
              ? null
              : () => _showPicker(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            side: BorderSide(
                color: AppColors.primaryDark.withValues(alpha: 0.5)),
            minimumSize: const Size.fromHeight(48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: controller.isLoadingScans.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.document_scanner_outlined, size: 19),
          label: Text(controller.isLoadingScans.value
              ? 'Memuat riwayat scan...'
              : 'Pilih scan saya'),
        );
      }

      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.softSky,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: scan.thumbnailUrl == null
                  ? Container(
                      width: 46,
                      height: 46,
                      color: AppColors.white,
                      child: const Icon(Icons.pets_outlined,
                          size: 22, color: AppColors.primary),
                    )
                  : CachedNetworkImage(
                      imageUrl: resolveImageUrl(scan.thumbnailUrl),
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(width: 46, height: 46, color: AppColors.white),
                      errorWidget: (_, _, _) => Container(
                        width: 46,
                        height: 46,
                        color: AppColors.white,
                        child: const Icon(Icons.pets_outlined,
                            size: 22, color: AppColors.primary),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.disease?.name ?? 'Hasil scan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    [
                      if (scan.fishType != null) scan.fishType!,
                      if (scan.disease?.confidence != null)
                        'Confidence ${scan.disease!.confidence!.toStringAsFixed(1)}%',
                      shortDate(scan.createdAt),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Hapus tautan scan',
              onPressed: controller.clearSelectedScan,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 19, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    });
  }

  void _showPicker(BuildContext context) {
    if (controller.scans.isEmpty) controller.loadScans();
    Get.bottomSheet(
      SafeArea(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 460),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tautkan hasil scan',
                  style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                if (controller.isLoadingScans.value)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: AppColors.primary),
                      ),
                    ),
                  )
                else if (controller.scans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: Center(
                      child: Text(
                        'Belum ada scan berstatus selesai.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: controller.scans.length,
                      separatorBuilder: (_, _) =>
                          const Divider(color: AppColors.border),
                      itemBuilder: (_, index) {
                        final scan = controller.scans[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: scan.thumbnailUrl == null
                                ? Container(
                                    width: 44,
                                    height: 44,
                                    color: AppColors.softSky,
                                    child: const Icon(Icons.pets_outlined,
                                        size: 20, color: AppColors.primary),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: resolveImageUrl(scan.thumbnailUrl),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) => Container(
                                      width: 44,
                                      height: 44,
                                      color: AppColors.softSky,
                                      child: const Icon(Icons.pets_outlined,
                                          size: 20, color: AppColors.primary),
                                    ),
                                  ),
                          ),
                          title: Text(
                            scan.disease?.name ?? 'Hasil scan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              if (scan.fishType != null) scan.fishType!,
                              if (scan.disease?.confidence != null)
                                '${scan.disease!.confidence!.toStringAsFixed(1)}%',
                              shortDate(scan.createdAt),
                            ].join(' · '),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: controller.selectedScan.value?.scanId ==
                                  scan.scanId
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 20)
                              : null,
                          onTap: () {
                            Get.back();
                            controller.selectedScan.value = scan;
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.white,
    );
  }
}

/// Playful dashed "dropzone" for photos.
class _Dropzone extends StatelessWidget {
  const _Dropzone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: DashedRoundedPainter(
          color: AppColors.primary.withValues(alpha: 0.55),
          radius: 16,
          strokeWidth: 1.5,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
          child: const Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.softSky,
                child: Icon(Icons.add_photo_alternate_outlined,
                    size: 26, color: AppColors.primary),
              ),
              SizedBox(height: 10),
              Text(
                'Ketuk untuk menambah foto',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              SizedBox(height: 4),
              Text(
                'JPG, PNG, atau WEBP — maksimum 5 foto',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
