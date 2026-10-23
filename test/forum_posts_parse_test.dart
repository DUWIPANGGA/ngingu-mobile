import 'package:flutter_test/flutter_test.dart';

import 'package:ngingu_apps/core/models/forum_model.dart';
import 'package:ngingu_apps/modules/forum/utils/forum_utils.dart';

/// Payload nyata dari `GET /api/forum/posts` production (10 Okt 2026).
///
/// Regresi: `author.id` berupa UUID string. Dulu di-cast ke `num` sehingga
/// melempar TypeError, dan `parseForumPosts` membuang post-nya diam-diam →
/// daftar forum tampil kosong walau post sudah disetujui moderator.
const _productionPayload = <Map<String, dynamic>>[
  {
    'id': 1,
    'type': 'question',
    'title': 'ikan koki saya muncul bintik putih',
    'excerpt': 'ikan koki saya udah beberapa hari muncul bintik putih',
    'category': {
      'id': 1,
      'name': 'Identifikasi Penyakit',
      'slug': 'identifikasi-penyakit',
      'icon': '🦠',
    },
    'author': {
      'id': '01a11a51-f7fc-724d-b35e-5f258041a87d',
      'name': 'Arya',
      'avatar_url': null,
      'reputation_level': 'Pemula',
    },
    'linked_scan': {
      'scan_id': '01a11a6c-2216-7067-bead-1c95e947546a',
      'disease': {'name': 'Saprolegniasis (Jamur Air)', 'confidence': 74.5},
      'thumbnail_url': 'https://ngingu.duvi.asia/storage/scans/x/thumb.jpg',
    },
    'tags': <String>[],
    'votes_count': 0,
    'comments_count': 0,
    'views_count': 0,
    'has_best_answer': false,
    'is_pinned': false,
    'status': 'published',
    'created_at': '2026-10-08T14:35:16+07:00',
  },
];

void main() {
  test('post dengan author UUID tidak dibuang oleh parser daftar forum', () {
    final posts = parseForumPosts(_productionPayload);

    expect(posts, hasLength(1), reason: 'post terbuang diam-diam oleh try/catch');
    expect(posts.first.title, 'ikan koki saya muncul bintik putih');
    expect(posts.first.author?.id, '01a11a51-f7fc-724d-b35e-5f258041a87d');
    expect(posts.first.status, 'published');
    expect(posts.first.isQuestion, isTrue);
    expect(posts.first.linkedScan?.diseaseName, 'Saprolegniasis (Jamur Air)');
    expect(posts.first.linkedScan?.confidence, closeTo(74.5, 0.001));
  });

  test('ForumAuthor.fromJson menerima UUID string maupun angka', () {
    expect(ForumAuthor.fromJson(const {'id': 'abc-123', 'name': 'A'}).id, 'abc-123');
    expect(ForumAuthor.fromJson(const {'id': 42, 'name': 'B'}).id, '42');
    expect(ForumAuthor.fromJson(const {'name': 'C'}).id, isNull);
    // Payload bukan map tidak boleh melempar.
    expect(ForumAuthor.fromJson(null).name, '-');
  });

  test('daftar kosong tetap aman', () {
    expect(parseForumPosts(const []), isEmpty);
    expect(parseForumPosts({'data': []}), isEmpty, reason: 'non-list → kosong');
  });
}
