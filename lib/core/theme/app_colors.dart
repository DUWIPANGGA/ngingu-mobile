import 'package:flutter/material.dart';

/// Ngingu design tokens — SRS §7.2 Color Palette.
///
/// Prefer these names in new code. Legacy aliases at the bottom keep older
/// views compiling while they are migrated.
class AppColors {
  AppColors._();

  // ── SRS §7.2 core tokens ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF0EA5E9); // Sky Blue — CTA, links
  static const Color primaryDark = Color(0xFF0369A1); // hover, headers
  static const Color secondary = Color(0xFF10B981); // Emerald — success/healthy
  static const Color accent = Color(0xFFF59E0B); // Amber — warning/medium
  static const Color danger = Color(0xFFEF4444); // Red — critical/error
  static const Color surface = Color(0xFFF0F9FF); // light blue-gray bg
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color border = Color(0xFFE2E8F0);

  // ── Extras ────────────────────────────────────────────────────────────────
  static const Color white = Colors.white;
  static const Color textLight = Color(0xFF94A3B8); // slate-400, hints
  static const Color orange = Color(0xFFF97316); // severe (between accent & danger)
  static const Color softSky = Color(0xFFE0F2FE); // icon circles, chips bg
  static const Color softAmber = Color(0xFFFEF3C7);
  static const Color softRed = Color(0xFFFEE2E2);
  static const Color softGreen = Color(0xFFD1FAE5);

  // ── Dark mode tokens (SRS §7.2) ───────────────────────────────────────────
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkBorder = Color(0xFF334155);

  // ── Severity badges (FR-03.1.2): Ringan/Sedang/Berat/Kritis ───────────────
  static const Color severityRingan = secondary; // hijau
  static const Color severitySedang = Color(0xFFEAB308); // kuning
  static const Color severityBerat = orange; // oranye
  static const Color severityKritis = danger; // merah

  static Color severity(String? severity) {
    switch (severity) {
      case 'ringan':
        return severityRingan;
      case 'sedang':
        return severitySedang;
      case 'berat':
        return severityBerat;
      case 'kritis':
        return severityKritis;
      default:
        return textSecondary;
    }
  }

  // ── Legacy aliases (old flood-era views) ──────────────────────────────────
  static const Color primaryBlue = primaryDark;
  static const Color primaryOrange = accent;
  static const Color backgroundLight = surface;
  static const Color textDark = textPrimary;
  static const Color dangerRed = danger;
  static const Color primaryTeal = primary;
  static const Color softTeal = softSky;
}
