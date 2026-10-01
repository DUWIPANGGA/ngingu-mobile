import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_buttons.dart';

/// Full-screen / inline loading spinner.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(message!,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// Empty-state placeholder with icon + hint.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.softSky,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              SecondaryButton(label: actionLabel!, onPressed: onAction, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with retry.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration:
                  const BoxDecoration(color: AppColors.softRed, shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            Text(
              'Ups, terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              SecondaryButton(label: 'Coba Lagi', onPressed: onRetry, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline banner (warnings like low-confidence — FR-02.2.3).
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color = AppColors.accent,
    this.bgColor,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final Color color;
  final Color? bgColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final bg = bgColor ?? color.withValues(alpha: 0.1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: color,
                      padding: const EdgeInsets.only(left: 0, top: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(actionLabel!,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
