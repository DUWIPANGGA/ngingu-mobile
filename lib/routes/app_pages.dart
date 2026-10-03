import 'package:get/get.dart';

import '../modules/encyclopedia/controllers/disease_detail_controller.dart';
import '../modules/encyclopedia/controllers/encyclopedia_controller.dart';
import '../modules/articles/controllers/article_detail_controller.dart';
import '../modules/articles/controllers/article_list_controller.dart';
import '../modules/articles/views/article_detail_view.dart';
import '../modules/articles/views/article_list_view.dart';
import '../modules/encyclopedia/views/disease_detail_view.dart';import '../modules/forum/controllers/forum_compose_controller.dart';
import '../modules/forum/controllers/forum_detail_controller.dart';
import '../modules/forum/controllers/forum_list_controller.dart';
import '../modules/forum/views/forum_compose_view.dart';
import '../modules/forum/views/forum_detail_view.dart';
import '../modules/help/controllers/help_controller.dart';
import '../modules/help/views/help_view.dart';
import '../modules/home/controllers/home_controller.dart';
import '../modules/heatmap/controllers/heatmap_controller.dart';
import '../modules/heatmap/views/heatmap_view.dart';
import '../modules/main_navigation/controllers/main_navigation_controller.dart';
import '../modules/main_navigation/views/main_navigation_view.dart';
import '../modules/notification/controllers/notification_controller.dart';
import '../modules/notification/views/notification_view.dart';
import '../modules/onboarding/controllers/onboarding_controller.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/ponds/controllers/pond_form_controller.dart';
import '../modules/ponds/controllers/pond_health_controller.dart';
import '../modules/ponds/controllers/ponds_controller.dart';
import '../modules/ponds/views/pond_form_view.dart';
import '../modules/ponds/views/pond_health_view.dart';
import '../modules/ponds/views/ponds_view.dart';
import '../modules/profile/controllers/change_password_controller.dart';
import '../modules/profile/controllers/edit_profile_controller.dart';
import '../modules/profile/controllers/notification_settings_controller.dart';
import '../modules/profile/controllers/profile_controller.dart';
import '../modules/profile/controllers/public_profile_controller.dart';
import '../modules/profile/views/about_view.dart';
import '../modules/profile/views/change_password_view.dart';
import '../modules/profile/views/edit_profile_view.dart';
import '../modules/profile/views/notification_settings_view.dart';
import '../modules/profile/views/public_profile_view.dart';
import '../modules/scan/controllers/scan_controller.dart';
import '../modules/scan/controllers/scan_history_controller.dart';
import '../modules/scan/controllers/scan_processing_controller.dart';
import '../modules/scan/controllers/scan_result_controller.dart';
import '../modules/scan/views/scan_history_view.dart';
import '../modules/scan/views/scan_processing_view.dart';
import '../modules/scan/views/scan_result_view.dart';
import '../modules/splash/controllers/splash_controller.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/auth/forgot_password/controllers/forgot_password_controller.dart';
import '../modules/auth/forgot_password/views/forgot_password_view.dart';
import '../modules/auth/login/controllers/login_controller.dart';
import '../modules/auth/login/views/login_view.dart';
import '../modules/auth/register/controllers/register_controller.dart';
import '../modules/auth/register/views/register_view.dart';
import '../modules/welcome/views/welcome_view.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = Routes.splash;

  static final routes = [
    // â”€â”€ Entry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        // Get.put (eager): SplashView tidak menyentuh `controller`, jadi
        // lazyPut tak akan pernah menginstansiasi → onInit/_decide tak jalan.
        Get.put(SplashController());
      }),
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<OnboardingController>(() => OnboardingController());
      }),
    ),
    GetPage(
      name: Routes.welcome,
      page: () => const WelcomeView(),
    ),

    // â”€â”€ Auth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LoginController>(() => LoginController());
      }),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<RegisterController>(() => RegisterController());
      }),
    ),
    GetPage(
      name: Routes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController());
      }),
    ),

    // â”€â”€ Shell (5 tabs) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: Routes.mainNavigation,
      page: () => const MainNavigationView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MainNavigationController>(() => MainNavigationController());
        Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
        Get.lazyPut<ScanController>(() => ScanController(), fenix: true);
        Get.lazyPut<ForumListController>(() => ForumListController(), fenix: true);
        Get.lazyPut<EncyclopediaController>(() => EncyclopediaController(), fenix: true);
        Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
      }),
    ),

    // â”€â”€ Scan â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: Routes.scanProcessing,
      page: () => const ScanProcessingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ScanProcessingController>(() => ScanProcessingController());
      }),
    ),
    GetPage(
      name: Routes.scanResult,
      page: () => const ScanResultView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ScanResultController>(() => ScanResultController());
      }),
    ),
    GetPage(
      name: Routes.scanHistory,
      page: () => const ScanHistoryView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ScanHistoryController>(() => ScanHistoryController());
      }),
    ),

    // â”€â”€ Encyclopedia â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: Routes.diseaseDetail,
      page: () => const DiseaseDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DiseaseDetailController>(() => DiseaseDetailController());
      }),
    ),
    GetPage(
      name: Routes.articles,
      page: () => const ArticleListView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ArticleListController>(() => ArticleListController());
      }),
    ),
    GetPage(
      name: Routes.articleDetail,
      page: () => const ArticleDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ArticleDetailController>(() => ArticleDetailController());
      }),
    ),

    // â”€â”€ Forum â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: Routes.forumDetail,
      page: () => const ForumDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ForumDetailController>(() => ForumDetailController());
      }),
    ),
    GetPage(
      name: Routes.forumCompose,
      page: () => const ForumComposeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ForumComposeController>(() => ForumComposeController());
      }),
    ),

    // â”€â”€ Notifications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: Routes.notifications,
      page: () => const NotificationView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<NotificationController>(() => NotificationController());
      }),
    ),
    GetPage(
      name: Routes.notificationSettings,
      page: () => const NotificationSettingsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<NotificationSettingsController>(
            () => NotificationSettingsController());
      }),
    ),

    // â”€â”€ Profile & farm â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: Routes.editProfile,
      page: () => const EditProfileView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<EditProfileController>(() => EditProfileController());
      }),
    ),
    GetPage(
      name: Routes.changePassword,
      page: () => const ChangePasswordView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ChangePasswordController>(() => ChangePasswordController());
      }),
    ),
    GetPage(
      name: Routes.publicProfile,
      page: () => const PublicProfileView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PublicProfileController>(() => PublicProfileController());
      }),
    ),
    GetPage(
      name: Routes.ponds,
      page: () => const PondsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PondsController>(() => PondsController());
      }),
    ),
    GetPage(
      name: Routes.pondForm,
      page: () => const PondFormView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PondFormController>(() => PondFormController());
      }),
    ),
    GetPage(
      name: Routes.pondHealth,
      page: () => const PondHealthView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PondHealthController>(() => PondHealthController());
      }),
    ),
    GetPage(
      name: Routes.heatmap,
      page: () => const HeatmapView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HeatmapController>(() => HeatmapController());
      }),
    ),
    GetPage(
      name: Routes.help,
      page: () => const HelpView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HelpController>(() => HelpController());
      }),
    ),
    GetPage(
      name: Routes.about,
      page: () => const AboutView(),
    ),
  ];
}
