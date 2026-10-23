import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:ngingu_apps/core/models/user_model.dart';
import 'package:ngingu_apps/core/widgets/ngingu_logo.dart';
import 'package:ngingu_apps/modules/welcome/views/welcome_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WelcomeView', () {
    testWidgets('renders brand, login and register actions', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: WelcomeView()),
      );
      await tester.pump();

      expect(find.byType(NginguLogo), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Daftar Akun Baru'), findsOneWidget);
      expect(find.text('Jelajahi sebagai Tamu'), findsOneWidget);
    });
  });

  group('AuthSession parsing (API.md §3.3)', () {
    test('parses login payload', () {
      final session = AuthSession.fromJson({
        'user': {
          'id': 12,
          'name': 'Budi Santoso',
          'email': 'budi@example.com',
          'role': 'user',
          'avatar_url': 'https://cdn.example.com/a.jpg',
        },
        'token': '2|xxxxx',
        'token_expires_at': '2026-10-28T14:00:00+07:00',
      });

      expect(session.token, '2|xxxxx');
      expect(session.user.id, '12');
      expect(session.user.name, 'Budi Santoso');
      expect(session.user.role, 'user');
      expect(session.tokenExpiresAt, '2026-10-28T14:00:00+07:00');
    });

    test('tolerates partial user payload (register response)', () {
      final session = AuthSession.fromJson({
        'user': {
          'id': 13,
          'name': 'Ayu',
          'email': 'ayu@example.com',
          'role': 'user',
          'email_verified_at': null,
        },
        'token': '1|yyy',
      });

      expect(session.token, '1|yyy');
      expect(session.user.username, isNull);
      expect(session.user.fishTypes, isEmpty);
      expect(session.tokenExpiresAt, isNull);
    });
  });
}
