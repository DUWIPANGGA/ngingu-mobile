import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_badges.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/app_fields.dart';
import '../controllers/forum_list_controller.dart';
import '../widgets/forum_category_chip.dart';
import '../widgets/forum_post_card.dart';

/// Forum tab (bottom-nav, FR-05.1) â€” list, search, category & sort filters.
class ForumListView extends GetView<ForumListController> {
  const ForumListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: controller.openCompose,
        backgroundColor: AppColors.primary,
        elevation: 3,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(controller: controller, onFilter: () => _showFilterSheet(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller.searchController,
                builder: (_, value, _) => AppSearchField(
                  controller: controller.searchController,
                  hint: 'Cari judul atau isi diskusi',
                  onChanged: controller.onSearchChanged,
                  onClear: controller.clearSearch,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CategoryRow(controller: controller),
            const SizedBox(height: 6),
            Expanded(child: _PostList(controller: controller)),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
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
                const SectionHeader(title: 'Urutkan'),
                for (final option in ForumListController.sortOptions)
                  _SortTile(
                    label: ForumListController.sortLabel(option),
                    selected: controller.sort.value == option,
                    onTap: () {
                      Get.back();
                      controller.selectSort(option);
                    },
                  ),
                const SizedBox(height: 4),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),
                const SectionHeader(title: 'Kategori'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ForumCategoryChip(
                      label: 'Semua',
                      selected: controller.selectedCategory.value == null,
                      onTap: () {
                        Get.back();
                        controller.selectCategory(null);
                      },
                    ),
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
                if (controller.activeFilterCount > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        Get.back();
                        controller.resetFilters();
                      },
                      child: const Text(
                        'Reset filter',
                        style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w800,
                            fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.white,
      isScrollControlled: true,
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.onFilter});

  final ForumListController controller;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Forum Tambak',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
          ),
          Obx(
            () => IconAction(
              icon: Icons.tune_rounded,
              tooltip: 'Filter & urutan',
              badge: controller.activeFilterCount,
              onPressed: onFilter,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.controller});

  final ForumListController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            ForumCategoryChip(
              label: 'Semua',
              selected: controller.selectedCategory.value == null,
              compact: true,
              onTap: () => controller.selectCategory(null),
            ),
            const SizedBox(width: 8),
            for (final category in controller.categories) ...[
              ForumCategoryChip.fromCategory(
                category,
                compact: true,
                selected:
                    controller.selectedCategory.value?.id == category.id,
                onTap: () => controller.selectCategory(category),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  const _PostList({required this.controller});

  final ForumListController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.posts.isEmpty) {
        return const _ForumSkeletonList();
      }
      if (controller.hasError.value && controller.posts.isEmpty) {
        return ErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.retry,
        );
      }
      if (controller.posts.isEmpty) {
        return EmptyState(
          icon: Icons.forum_outlined,
          title: 'Belum ada diskusi',
          subtitle: controller.isAuthed
              ? 'Jadilah yang pertama bertanya kepada komunitas tambak.'
              : 'Belum ada pertanyaan yang dibuat pengguna lain.',
          actionLabel: controller.isAuthed ? 'Buat Pertanyaan' : null,
          onAction: controller.isAuthed ? controller.openCompose : null,
        );
      }

      final posts = controller.posts;
      return RefreshIndicator(
        onRefresh: controller.reload,
        color: AppColors.primary,
        child: ListView.separated(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 96),
          itemCount: posts.length + (controller.isLoadingMore.value ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            if (index >= posts.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: AppColors.primary),
                  ),
                ),
              );
            }
            final post = posts[index];
            final author = post.author;
            return ForumPostCard(
              post: post,
              onTap: () => controller.openPost(post.id),
              onAuthorTap:
                  author == null ? null : () => controller.openAuthor(author),
            );
          },
        ),
      );
    });
  }
}

/// Pulsing placeholder rows while the first page loads.
class _ForumSkeletonList extends StatelessWidget {
  const _ForumSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 0.95,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _Block(width: 32, height: 32, radius: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Block(width: 110, height: 11),
                      SizedBox(height: 6),
                      _Block(width: 70, height: 9),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _Block(width: 90, height: 18, radius: 999),
            const SizedBox(height: 10),
            const _Block(width: double.infinity, height: 14),
            const SizedBox(height: 6),
            const _Block(width: 200, height: 14),
            const SizedBox(height: 12),
            const _Block(width: 160, height: 11),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.width, required this.height, this.radius = 6});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.softSky,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
