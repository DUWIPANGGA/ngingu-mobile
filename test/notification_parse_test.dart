import 'package:flutter_test/flutter_test.dart';

import 'package:ngingu_apps/core/models/notification_model.dart';

/// Regresi: backend mengirim `id` notifikasi sebagai UUID string
/// (`NotificationController::payload`). Dulu di-cast ke `int` sehingga
/// melempar TypeError dan seluruh daftar notifikasi gagal dimuat.
void main() {
  test('AppNotification menerima id UUID string', () {
    final n = AppNotification.fromJson(<String, dynamic>{
      'id': '01a11a6b-2222-7333-8444-555566667777',
      'type': 'forum_reply',
      'title': 'Ada balasan baru',
      'body': 'Post Anda dibalas',
      'data': {'post_id': 1},
      'read_at': null,
      'created_at': '2026-10-08T14:00:00+07:00',
    });

    expect(n.id, '01a11a6b-2222-7333-8444-555566667777');
    expect(n.isRead, isFalse);
    expect(n.data['post_id'], 1);
  });

  test('id numerik lama tetap diterima sebagai string', () {
    expect(AppNotification.fromJson(const {'id': 7, 'type': 'x', 'title': 't'}).id, '7');
  });
}
