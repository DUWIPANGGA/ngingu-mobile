/// Named route table for the Ngingu app (GetX).
class Routes {
  Routes._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';

  // Auth
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Shell
  static const mainNavigation = '/home';

  // Scan flow (FR-02/FR-04)
  static const scanProcessing = '/scan/processing'; // args: scanId
  static const scanResult = '/scan/result'; // args: scanId
  static const scanHistory = '/scan/history';

  // Encyclopedia (FR-03)
  static const diseaseDetail = '/disease'; // args: slug

  // Forum (FR-05)
  static const forumDetail = '/forum/detail'; // args: postId (int)
  static const forumCompose = '/forum/compose'; // args: Map prefill? / ForumPost edit?

  // Notifications (FR-06)
  static const notifications = '/notifications';
  static const notificationSettings = '/notifications/settings';

  // Artikel edukasi (FR-03.3)
  static const articles = '/articles';
  static const articleDetail = '/articles/detail'; // args: id (int/slug)

  // Profile & farm (FR-07/FR-08)
  static const editProfile = '/profile/edit';
  static const changePassword = '/profile/change-password';
  static const publicProfile = '/users/detail'; // args: userId
  static const ponds = '/ponds';
  static const pondForm = '/ponds/form'; // args: Pond? (null = create)
  static const pondHealth = '/ponds/health'; // args: pondId, pondName
  static const heatmap = '/heatmap';
  static const help = '/help';
  static const about = '/about';
}
