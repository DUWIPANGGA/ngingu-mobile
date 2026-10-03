import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Warna adaptif terang/gelap.
///
/// Di mode terang mengembalikan nilai persis desain saat ini (tidak ada
/// perubahan visual); di mode gelap memakai token `dark*` SRS §7.2.
extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get card => isDark ? AppColors.darkCard : AppColors.white;

  Color get page => Theme.of(this).colorScheme.surface;

  Color get line => isDark ? AppColors.darkBorder : AppColors.border;

  Color get ink => isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get inkSecondary =>
      isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
}
