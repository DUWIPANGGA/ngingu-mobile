import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

/// Mode tampilan aplikasi (Terang / Gelap / Ikuti sistem).
///
/// Didaftarkan permanen di `main()` sebelum `runApp`, pilihan disimpan
/// di SharedPreferences dan diterapkan via `Get.changeThemeMode`.
class ThemeController extends GetxController {
  static const _key = 'theme_mode';

  final mode = ThemeMode.system.obs;

  static ThemeController get to => Get.find();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value = _parse(prefs.getString(_key));
    Get.changeThemeMode(mode.value);
  }

  Future<void> setMode(ThemeMode next) async {
    if (mode.value == next) return;
    mode.value = next;
    Get.changeThemeMode(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next.name);
  }

  String get label => switch (mode.value) {
        ThemeMode.dark => 'Gelap',
        ThemeMode.light => 'Terang',
        ThemeMode.system => 'Ikuti sistem',
      };

  static ThemeMode _parse(String? raw) => ThemeMode.values
      .firstWhere((e) => e.name == raw, orElse: () => ThemeMode.system);

  /// Bottom sheet pilihan tema — dipakai profil (masuk & tamu).
  void showPicker() {
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tampilan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                for (final entry in _options)
                  _OptionTile(
                    icon: entry.icon,
                    title: entry.title,
                    subtitle: entry.subtitle,
                    selected: mode.value == entry.mode,
                    onTap: () {
                      Get.back();
                      setMode(entry.mode);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _ThemeOption {
  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final ThemeMode mode;
  final IconData icon;
  final String title;
  final String subtitle;
}

const _options = [
  _ThemeOption(
    mode: ThemeMode.light,
    icon: Icons.light_mode_outlined,
    title: 'Terang',
    subtitle: 'Selalu terang',
  ),
  _ThemeOption(
    mode: ThemeMode.dark,
    icon: Icons.dark_mode_outlined,
    title: 'Gelap',
    subtitle: 'Nyaman di malam hari',
  ),
  _ThemeOption(
    mode: ThemeMode.system,
    icon: Icons.settings_suggest_outlined,
    title: 'Ikuti sistem',
    subtitle: 'Mengikuti pengaturan HP',
  ),
];

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.softSky,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
