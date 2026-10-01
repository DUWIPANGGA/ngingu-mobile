import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/pond_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/app_feedback.dart';
import '../controllers/ponds_controller.dart';
import '../widgets/pond_common.dart';

/// Daftar tambak saya (FR-08.1) — kartu skor kesehatan, aksi Ubah/Hapus,
/// pull-to-refresh + pagination; tamu → CTA login.
class PondsView extends GetView<PondsController> {
  const PondsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Tambak Saya'),
        actions: [
          IconButton(
            tooltip: 'Tambah tambak',
            onPressed: controller.openCreate,
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            style: IconButton.styleFrom(backgroundColor: AppColors.softSky),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(child: Obx(_body)),
    );
  }

  Widget _body() {
    if (AuthService.isGuest) {
      return EmptyState(
        icon: Icons.water_outlined,
        title: 'Masuk untuk kelola tambak',
        subtitle:
            'Kelola kolam, pantau skor kesehatan, dan lihat tren penyakit setelah masuk ke akunmu.',
        actionLabel: 'Masuk Sekarang',
        onAction: controller.goToLogin,
      );
    }
    if (controller.isLoading.value && controller.items.isEmpty) {
      return const LoadingState(message: 'Memuat tambak...');
    }
    if (controller.errorMessage.value != null &&
        controller.items.isEmpty) {
      return ErrorState(
        message: controller.errorMessage.value!,
        onRetry: controller.reload,
      );
    }
    if (controller.items.isEmpty) {
      return EmptyState(
        icon: Icons.water_outlined,
        title: 'Belum ada tambak',
        subtitle: 'Tambahkan tambak pertamamu untuk mulai memantau kesehatan kolam.',
        actionLabel: 'Tambah Tambak Pertama',
        onAction: controller.openCreate,
      );
    }
    return RefreshIndicator(
      onRefresh: controller.reload,
      color: AppColors.primary,
      child: ListView.builder(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: controller.items.length + 1,
        itemBuilder: (context, index) {
          if (index == controller.items.length) {
            return controller.isLoadingMore.value
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(height: 8);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _pondCard(controller.items[index]),
          );
        },
      ),
    );
  }

  Widget _pondCard(Pond pond) {
    final updatedAt = controller.updatedAtOf(pond);
    return Container(
      decoration: pondCardDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => controller.openHealth(pond),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HealthScoreRing(score: pond.healthScore, size: 62),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pond.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Aksi tambak',
                          icon: const Icon(Icons.more_vert_rounded,
                              size: 20, color: AppColors.textSecondary),
                          onSelected: (value) {
                            if (value == 'edit') {
                              controller.openEdit(pond);
                            } else if (value == 'delete') {
                              controller.deletePond(pond);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 16, color: AppColors.textSecondary),
                                  SizedBox(width: 8),
                                  Text('Ubah',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline,
                                      size: 16, color: AppColors.danger),
                                  SizedBox(width: 8),
                                  Text('Hapus',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.danger)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if ((pond.locationLabel ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
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
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                        if (pond.healthScore != null)
                          PondInfoChip(
                            icon: Icons.favorite_outline,
                            label:
                                '${healthScoreLabel(pond.healthScore)} · ${pond.healthScore}%',
                          ),
                        for (final fish in pond.fishTypes.take(3))
                          PondInfoChip(icon: Icons.pets_outlined, label: fish),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.center_focus_weak,
                                size: 14, color: AppColors.textLight),
                            const SizedBox(width: 4),
                            Text(
                              '${pond.scansCount ?? 0} scan',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (updatedAt != null && updatedAt.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule,
                                  size: 14, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Text(
                                'Diperbarui ${timeAgo(updatedAt)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
