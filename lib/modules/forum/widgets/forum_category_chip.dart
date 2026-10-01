import 'package:flutter/material.dart';

import '../../../core/models/forum_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_badges.dart';

/// Topic chip for forum categories (API.md §6.1, FR-05.1.1).
///
/// Uses the category's own `icon` glyph when the API supplies one, otherwise
/// falls back to the shared [CategoryChip.icon] helper.
class ForumCategoryChip extends StatelessWidget {
  const ForumCategoryChip({
    super.key,
    required this.label,
    this.category,
    this.selected = false,
    this.subtle = false,
    this.compact = false,
    this.onTap,
  });

  final String label;
  final ForumCategory? category;
  final bool selected;

  /// softSky pill without a border — used inside post cards.
  final bool subtle;

  final bool compact;
  final VoidCallback? onTap;

  ForumCategoryChip.fromCategory(
    ForumCategory category, {
    super.key,
    this.selected = false,
    this.subtle = false,
    this.compact = false,
    this.onTap,
  })  : category = category,
        label = category.name;

  IconData get _fallbackIcon => CategoryChip.icon(category?.slug);

  @override
  Widget build(BuildContext context) {
    final glyph = category?.icon?.trim();
    final hasGlyph = glyph != null && glyph.isNotEmpty && glyph.length <= 4;

    final Color bg;
    final Color fg;
    if (selected) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else if (subtle) {
      bg = AppColors.softSky;
      fg = AppColors.primaryDark;
    } else {
      bg = AppColors.white;
      fg = AppColors.textSecondary;
    }

    final Widget icon = hasGlyph
        ? Text(glyph, style: TextStyle(fontSize: compact ? 11 : 13, height: 1))
        : Icon(_fallbackIcon, size: compact ? 13 : 14, color: fg);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 12, vertical: compact ? 4 : 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : subtle
                    ? Colors.transparent
                    : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
