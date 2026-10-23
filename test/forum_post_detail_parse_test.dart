import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ngingu_apps/core/models/forum_model.dart';

/// Payload nyata `GET /api/forum/posts/1` production (10 Okt 2026) berisi
/// 1 komentar.
///
/// Regresi: `comments` pada detail (API.md §6.4) dikirim sebagai **objek
/// paginator** `{data: [...], total, ...}`, bukan array. Dulu baris parse
/// memaksa `j['comments'] as List?` → TypeError → detail diskusi tidak
/// pernah bisa dibuka. Sekarang `_parseComments` menerima kedua bentuk.
const _productionDetail = r'''
{
  "id": 1,
  "type": "question",
  "title": "ikan koki saya muncul bintik putih",
  "excerpt": "ikan koki saya udah beberapa hari muncul bintik putih",
  "category": {"id": 1, "name": "Identifikasi Penyakit", "slug": "identifikasi-penyakit", "icon": "\ud83e\udda0"},
  "author": {
    "id": "01a11a51-f7fc-724d-b35e-5f258041a87d",
    "name": "probe",
    "avatar_url": null,
    "reputation_level": "Pemula"
  },
  "linked_scan": {
    "scan_id": "01a11a6c-2216-7067-bead-1c95e947546a",
    "disease": {"name": "Saprolegniasis (Jamur Air)", "confidence": 74.5},
    "thumbnail_url": "https://ngingu.duvi.asia/storage/scans/x/thumb-0-tekvw0.jpg"
  },
  "tags": [],
  "votes_count": 0,
  "comments_count": 1,
  "views_count": 1,
  "has_best_answer": false,
  "is_pinned": false,
  "status": "published",
  "created_at": "2026-10-08T14:35:16+07:00",
  "content_html": "ikan koki saya udah beberapa hari muncul bintik putih",
  "image_urls": [],
  "linked_scan_id": "01a11a6c-2216-7067-bead-1c95e947546a",
  "comments": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "parent_id": null,
        "author": {"id": "01a11a51-f7fc-724d-b35e-5f258041a87d", "name": "probe", "reputation_level": "Pemula"},
        "content_html": "<p>coba cek detail dulu</p>",
        "images": [],
        "votes_count": 0,
        "is_best_answer": false,
        "mention_users": [],
        "created_at": "2026-10-08T15:24:31+07:00",
        "replies": []
      }
    ],
    "first_page_url": "http://ngingu.duvi.asia/api/forum/posts/1?page=1",
    "from": 1,
    "last_page": 1,
    "last_page_url": "http://ngingu.duvi.asia/api/forum/posts/1?page=1",
    "links": [
      {"url": null, "label": "&laquo; Previous", "page": null, "active": false},
      {"url": "http://ngingu.duvi.asia/api/forum/posts/1?page=1", "label": "1", "page": 1, "active": true},
      {"url": null, "label": "Next &raquo;", "page": null, "active": false}
    ],
    "next_page_url": null,
    "path": "http://ngingu.duvi.asia/api/forum/posts/1",
    "per_page": 15,
    "prev_page_url": null,
    "to": 1,
    "total": 1
  },
  "viewer": {"is_bookmarked": false, "is_following": false, "my_vote": 0}
}
''';

void main() {
  test('detail post mem-parse comments berbentuk paginator (API.md §6.4)', () {
    final post =
        ForumPost.fromJson(jsonDecode(_productionDetail), withDetail: true);

    expect(post.id, 1);
    expect(post.isQuestion, isTrue);
    expect(post.commentsCount, 1);
    expect(post.author?.id, '01a11a51-f7fc-724d-b35e-5f258041a87d');
    expect(post.linkedScan?.confidence, closeTo(74.5, 0.001));

    expect(post.comments, hasLength(1));
    final comment = post.comments.first;
    expect(comment.id, 1);
    expect(comment.parentId, isNull);
    expect(comment.contentHtml, contains('coba cek detail dulu'));
    expect(comment.author?.id, '01a11a51-f7fc-724d-b35e-5f258041a87d');
    expect(comment.replies, isEmpty);

    expect(post.viewer.isBookmarked, isFalse);
    expect(post.viewer.myVote, 0);
  });

  test('comments kosong (paginator tanpa data) tetap aman', () {
    final post = ForumPost.fromJson(jsonDecode('''
{
  "id": 2,
  "type": "question",
  "title": "judul",
  "comments_count": 0,
  "comments": {"current_page": 1, "data": [], "total": 0, "per_page": 15},
  "viewer": {"is_bookmarked": false, "is_following": false, "my_vote": 0}
}
'''), withDetail: true);

    expect(post.comments, isEmpty);
    expect(post.title, 'judul');
  });

  test('comments berbentuk array polos tetap diterima', () {
    final post = ForumPost.fromJson(jsonDecode('''
{
  "id": 3,
  "type": "discussion",
  "title": "lama",
  "comments": [
    {"id": 9, "parent_id": null, "content_html": "halo", "replies": []}
  ]
}
'''), withDetail: true);

    expect(post.comments, hasLength(1));
    expect(post.comments.first.id, 9);
  });

  test('tanpa withDetail comments tidak dibaca', () {
    final post = ForumPost.fromJson(jsonDecode(
        '{"id": 4, "type": "discussion", "title": "ringkas", "comments_count": 7}'));

    expect(post.comments, isEmpty);
    expect(post.commentsCount, 7);
  });
}
