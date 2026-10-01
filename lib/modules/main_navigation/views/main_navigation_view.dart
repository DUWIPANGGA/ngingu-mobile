import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../encyclopedia/views/encyclopedia_view.dart';
import '../../forum/views/forum_list_view.dart';
import '../../home/views/home_view.dart';
import '../../profile/views/profile_view.dart';
import '../../scan/views/scan_view.dart';
import '../controllers/main_navigation_controller.dart';

/// 5-tab shell (SRS §7): Beranda · Scan · Forum · Ensiklopedia · Profil.
class MainNavigationView extends GetView<MainNavigationController> {
  const MainNavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.currentIndex.value;
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: IndexedStack(
          index: index,
          children: const [
            HomeView(),
            ScanView(),
            ForumListView(),
            EncyclopediaView(),
            ProfileView(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 12,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Beranda', index),
                  _navItem(1, Icons.center_focus_weak, Icons.center_focus_strong, 'Scan', index),
                  _navItem(2, Icons.forum_outlined, Icons.forum_rounded, 'Forum', index),
                  _navItem(3, Icons.menu_book_outlined, Icons.menu_book_rounded, 'Ensiklopedia', index),
                  _navItem(4, Icons.person_outline, Icons.person_rounded, 'Profil', index),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _navItem(
      int i, IconData icon, IconData activeIcon, String label, int current) {
    final active = current == i;
    return Expanded(
      child: InkWell(
        onTap: () => controller.changeTab(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: active
                  ? const EdgeInsets.symmetric(horizontal: 14, vertical: 4)
                  : const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.softSky : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                active ? activeIcon : icon,
                size: 23,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
