import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Severity badge — Ringan/Sedang/Berat/Kritis (FR-03.1.2: hijau/kuning/oranye/merah).
class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity, this.small = false});

  final String? severity;
  final bool small;

  String get _label {
    switch (severity) {
      case 'ringan':
        return 'RINGAN';
      case 'sedang':
        return 'SEDANG';
      case 'berat':
        return 'BERAT';
      case 'kritis':
        return 'KRITIS';
      default:
        return (severity ?? '-').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.severity(severity);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 7 : 10, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Category chip (bacteria/virus/parasite/fungi/other).
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, this.selected = false, this.onTap});

  final String? category;
  final bool selected;
  final VoidCallback? onTap;

  static String label(String? category) {
    switch (category) {
      case 'bacteria':
        return 'Bakteri';
      case 'virus':
        return 'Virus';
      case 'parasite':
        return 'Parasit';
      case 'fungi':
        return 'Jamur';
      default:
        return 'Lainnya';
    }
  }

  static IconData icon(String? category) {
    switch (category) {
      case 'bacteria':
        return Icons.bug_report_outlined;
      case 'virus':
        return Icons.coronavirus_outlined;
      case 'parasite':
        return Icons.bubble_chart_outlined;
      case 'fungi':
        return Icons.grain_outlined;
      default:
        return Icons.scatter_plot_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon(category),
                size: 14, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label(category),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated confidence bar — fills 0 → value in 500ms (SRS §7.6).
class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({super.key, required this.value, this.height = 10, this.showLabel = true});

  /// 0–100.
  final double value;
  final double height;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0, 100).toDouble();
    final color = clamped < 60
        ? AppColors.accent
        : clamped < 80
            ? AppColors.primary
            : AppColors.secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Confidence',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: clamped),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (context, v, _) => Text(
                    '${v.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped / 100),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: height,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dashboard stat card with count-up number (FR-07.2, SRS §7.6).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                v.round().toString(),
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header with optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
