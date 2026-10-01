import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Ngingu theme — SRS §7.2 palette, §7.3 typography.
///
/// Display/headline/title → Nunito (rounded & playful),
/// body/label → Plus Jakarta Sans (readable).
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary.withValues(alpha: 0.15),
      onPrimaryContainer: isDark ? Colors.white : AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondary.withValues(alpha: 0.15),
      onSecondaryContainer: AppColors.secondary,
      error: AppColors.danger,
      onError: Colors.white,
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      onSurface: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      onSurfaceVariant: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
      outline: isDark ? AppColors.darkBorder : AppColors.border,
      shadow: Colors.black,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    // Body & label family first, then Nunito on display/headline/title.
    var textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
    textTheme = textTheme.copyWith(
      displayLarge: _nunito(textTheme.displayLarge, FontWeight.w800),
      displayMedium: _nunito(textTheme.displayMedium, FontWeight.w800),
      displaySmall: _nunito(textTheme.displaySmall, FontWeight.w800),
      headlineLarge: _nunito(textTheme.headlineLarge, FontWeight.w800),
      headlineMedium: _nunito(textTheme.headlineMedium, FontWeight.w700),
      headlineSmall: _nunito(textTheme.headlineSmall, FontWeight.w700),
      titleLarge: _nunito(textTheme.titleLarge, FontWeight.w700),
      titleMedium: _nunito(textTheme.titleMedium, FontWeight.w700),
      titleSmall: _nunito(textTheme.titleSmall, FontWeight.w700),
    );
    textTheme = textTheme.apply(
      bodyColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      displayColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
    );

    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkSurface : AppColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _nunito(
          textTheme.titleLarge,
          FontWeight.w800,
        )?.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontSize: 18),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        shape: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
        hintStyle: TextStyle(
            color: isDark ? const Color(0xFF64748B) : AppColors.textLight,
            fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle:
            _nunito(textTheme.titleSmall, FontWeight.w800)?.copyWith(fontSize: 13.5),
        unselectedLabelStyle:
            textTheme.titleSmall?.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
        dividerColor: border,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? AppColors.darkTextPrimary : AppColors.textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.textLight),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.border),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.primary),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static TextStyle? _nunito(TextStyle? style, FontWeight weight) =>
      style == null ? null : GoogleFonts.nunito(textStyle: style, fontWeight: weight);

  /// Get.snackbar defaults aligned with the palette.
  static void success(String title, String message) {
    Get.snackbar(title, message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.secondary,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3));
  }

  static void error(String title, String message) {
    Get.snackbar(title, message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4));
  }

  static void info(String title, String message) {
    Get.snackbar(title, message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accent,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3));
  }
}
