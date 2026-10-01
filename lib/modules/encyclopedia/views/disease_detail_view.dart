import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/disease_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_feedback.dart';
import '../controllers/disease_detail_controller.dart';

/// Detail penyakit — `GET /api/diseases/{id}` (API.md §5.2, FR-03.2).
class DiseaseDetailView extends GetView<DiseaseDetailController> {
  const DiseaseDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Detail Penyakit')),
      body: Obx(() {
        final data = controller.detail.value;

        if (controller.isLoading.value && data == null) {
          return const LoadingState(message: 'Memuat detail penyakit...');
        }
        if (controller.errorMessage.value != null && data == null) {
          return ErrorState(
            message: controller.errorMessage.value!,
            onRetry: () => controller.retry(),
          );
        }
        if (data == null) {
          return const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'Penyakit tidak ditemukan',
          );
        }
        return _content(data);
      }),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _content(DiseaseDetail data) {
    final medicines = <Medicine>[];
    for (final treatment in data.treatments) {
      medicines.addAll(treatment.medicines);
    }

    return ListView(
      controller: controller.scrollController,
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _gallery(data),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(data),
              if (data.description != null &&
                  data.description!.trim().isNotEmpty)
                _textSection('Tentang', data.description!),
              if (data.symptoms.isNotEmpty) _symptomSection(data.symptoms),
              if (data.causes != null && data.causes!.trim().isNotEmpty)
                _textSection('Penyebab', data.causes!),
              if (data.treatments.isNotEmpty)
                _treatmentSection(data.treatments),
              if (data.preventions.isNotEmpty)
                _preventionSection(data.preventions),
              if (medicines.isNotEmpty) _medicineSection(medicines),
              if (data.recoveryDays != null)
                _recoveryCard(data.recoveryDays!),
              if (data.images.length > 1) _otherImages(data.images),
              if (controller.similar.isNotEmpty) _similarSection(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Gallery ───────────────────────────────────────────────────────────────

  Widget _gallery(DiseaseDetail data) {
    final images = data.images;
    if (images.isEmpty) {
      return Container(
        height: 190,
        color: AppColors.softSky,
        alignment: Alignment.center,
        child: const Icon(Icons.coronavirus_outlined,
            size: 54, color: AppColors.primary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 230,
          child: Stack(
            children: [
              PageView.builder(
                controller: controller.heroController,
                itemCount: images.length,
                onPageChanged: controller.onImageChanged,
                itemBuilder: (context, index) {
                  final url = resolveImageUrl(images[index].url);
                  if (url.isEmpty) return const _ImagePlaceholder();
                  return CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _ImagePlaceholder(),
                    errorWidget: (_, _, _) => const _ImagePlaceholder(),
                  );
                },
              ),
              if (images.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Obx(() {
                    final active = controller.currentImage.value;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < images.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == active ? 18 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == active
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
            ],
          ),
        ),
        Obx(() {
          var index = controller.currentImage.value;
          if (index < 0 || index >= images.length) index = 0;
          final caption = images[index].caption;
          if (caption == null || caption.trim().isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Header card ───────────────────────────────────────────────────────────

  Widget _headerCard(DiseaseDetail data) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.name,
            style: const TextStyle(
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SeverityBadge(severity: data.severity),
              CategoryChip(category: data.category),
            ],
          ),
          if (data.fishTypes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Ikan yang rentan',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final fish in data.fishTypes)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      fish,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  // ── Generic text section ──────────────────────────────────────────────────

  Widget _textSection(String title, String body) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Symptoms ──────────────────────────────────────────────────────────────

  Widget _symptomSection(List<String> symptoms) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Gejala'),
          for (var i = 0; i < symptoms.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _BulletRow(
              icon: Icons.health_and_safety_outlined,
              color: AppColors.accent,
              text: symptoms[i],
            ),
          ],
        ],
      ),
    );
  }

  // ── Treatments ────────────────────────────────────────────────────────────

  Widget _treatmentSection(List<Treatment> treatments) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Penanganan'),
          for (var i = 0; i < treatments.length; i++)
            _TimelineStep(
              step: treatments[i],
              index: i,
              isLast: i == treatments.length - 1,
            ),
        ],
      ),
    );
  }

  // ── Preventions ───────────────────────────────────────────────────────────

  Widget _preventionSection(List<String> preventions) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Pencegahan'),
          for (var i = 0; i < preventions.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _BulletRow(
              icon: Icons.shield_outlined,
              color: AppColors.secondary,
              text: preventions[i],
            ),
          ],
        ],
      ),
    );
  }

  // ── Medicines ─────────────────────────────────────────────────────────────

  Widget _medicineSection(List<Medicine> medicines) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Obat & Dosis'),
          for (var i = 0; i < medicines.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _MedicineCard(medicine: medicines[i]),
          ],
        ],
      ),
    );
  }

  // ── Recovery ──────────────────────────────────────────────────────────────

  Widget _recoveryCard(RecoveryDays days) {
    return _Card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.softSky,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule_rounded,
                size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perkiraan Sembuh',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  days.label,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Other images ──────────────────────────────────────────────────────────

  Widget _otherImages(List<DiseaseImage> images) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Gambar Lainnya'),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 1; i < images.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () {
                        if (controller.heroController.hasClients) {
                          controller.heroController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: _Thumb(url: images[i].url, width: 130, height: 86),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Similar ───────────────────────────────────────────────────────────────

  Widget _similarSection() {
    final similar = controller.similar;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Penyakit Serupa'),
          SizedBox(
            height: 168,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final item in similar)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 150,
                      child: InkWell(
                        onTap: () => controller.openSimilar(item.id),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Thumb(
                                url: item.thumbnailUrl,
                                width: double.infinity,
                                height: 76,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SeverityBadge(
                                severity: item.severity,
                                small: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Pieces
// ═══════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softSky,
      alignment: Alignment.center,
      child: const Icon(Icons.coronavirus_outlined,
          size: 54, color: AppColors.primary),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.width, required this.height});

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveImageUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        height: height,
        child: resolved.isEmpty
            ? const _ImagePlaceholder()
            : CachedNetworkImage(
                imageUrl: resolved,
                fit: BoxFit.cover,
                placeholder: (_, _) => const _ImagePlaceholder(),
                errorWidget: (_, _, _) => const _ImagePlaceholder(),
              ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.step,
    required this.index,
    required this.isLast,
  });

  final Treatment step;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final number = step.stepOrder ?? index + 1;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title ?? 'Langkah $number',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (step.description != null &&
                      step.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.description!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (step.durationDays != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.softSky,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Lama ${step.durationDays} hari',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication_outlined,
                  size: 17, color: AppColors.primary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  medicine.name ?? '-',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (medicine.dose != null && medicine.dose!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MedicineRow(label: 'Dosis', value: medicine.dose!),
          ],
          if (medicine.frequency != null && medicine.frequency!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _MedicineRow(label: 'Frekuensi', value: medicine.frequency!),
          ],
          if (medicine.notes != null && medicine.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _MedicineRow(label: 'Catatan', value: medicine.notes!),
          ],
        ],
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
