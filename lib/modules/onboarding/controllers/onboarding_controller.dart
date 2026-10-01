import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_routes.dart';

class OnboardingPage {
  const OnboardingPage(this.title, this.description, this.icon);

  final String title;
  final String description;
  final IconData icon;
}

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  final List<OnboardingPage> pages = const [
    OnboardingPage(
      'Scan penyakit ikan dalam hitungan detik',
      'Cukup foto ikanmu — AI kami memprediksi penyakitnya lengkap dengan skor keyakinan.',
      Icons.camera_alt_outlined,
    ),
    OnboardingPage(
      'Ensiklopedia & panduan penanganan',
      'Kenali gejala, penyebab, dan langkah penanganan step-by-step untuk puluhan penyakit ikan.',
      Icons.menu_book_outlined,
    ),
    OnboardingPage(
      'Komunitas tambak yang saling membantu',
      'Tanya hasil scan ke forum, dapatkan jawaban dari petani dan ahli lainnya.',
      Icons.forum_outlined,
    ),
  ];

  void onPageChanged(int index) => currentPage.value = index;

  Future<void> nextPage() async {
    if (currentPage.value < pages.length - 1) {
      await pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      await _finish();
    }
  }

  Future<void> skip() => _finish();

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    Get.offAllNamed(Routes.welcome);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
