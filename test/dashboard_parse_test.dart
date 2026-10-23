import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ngingu_apps/core/models/dashboard_model.dart';

/// Payload nyata `GET /api/dashboard` production (10 Okt 2026) yang
/// `trending_posts`-nya berisi1 post forum dengan `author.id` UUID.
///
/// Regresi: dulu `ForumAuthor.fromJson` melempar TypeError saat membaca id
/// UUID, `Dashboard.fromJson` ikut melempar, dan `HomeController.load()`
/// tidak pernah sempat menjalankan `isLoading = false` → layar dashboard
/// loading terus (FR-07).
const _productionData = r'''
{
  "stat_cards": {"total_scans": 4, "diseases_detected": 3, "active_ponds": 0, "questions_answered": 0},
  "recent_scans": [
    {
      "scan_id": "01a11a6c-2216-7067-bead-1c95e947546a",
      "thumbnail_url": "https://ngingu.duvi.asia/storage/scans/01a11a6c-2216-7067-bead-1c95e947546a/thumb-0-tekvw0.jpg",
      "fish_type": null,
      "pond": null,
      "disease": {"id": 4, "name": "Saprolegniasis (Jamur Air)", "slug": "saprolegniasis", "severity": "sedang"},
      "confidence": 74.5,
      "status": "done",
      "created_at": "2026-10-08T14:30:56+07:00"
    },
    {
      "scan_id": "01a11a69-ecdb-7266-b1c9-d2f9f643be65",
      "thumbnail_url": "https://ngingu.duvi.asia/storage/scans/01a11a69-ecdb-7266-b1c9-d2f9f643be65/thumb-0-9cye8x.jpg",
      "fish_type": null,
      "pond": null,
      "disease": null,
      "confidence": null,
      "status": "failed",
      "created_at": "2026-10-08T14:28:31+07:00"
    }
  ],
  "trending_posts": [
    {
      "id": 1,
      "type": "question",
      "title": "ikan koki saya muncul bintik putih",
      "excerpt": "ikan koki saya udah beberapa hari muncul bintik putih",
      "category": {"id": 1, "name": "Identifikasi Penyakit", "slug": "identifikasi-penyakit", "icon": "🦠"},
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
      "comments_count": 0,
      "views_count": 0,
      "has_best_answer": false,
      "is_pinned": false,
      "status": "published",
      "created_at": "2026-10-08T14:35:16+07:00"
    }
  ],
  "disease_trend": [
    {"date": "2026-10-07", "count": 0},
    {"date": "2026-10-08", "count": 3}
  ],
  "top_disease_this_week": {"id": 3, "name": "Penyakit Bakteri Insang", "count": 1},
  "activity_feed": [
    {"type": "scan", "title": "Scan mendeteksi Saprolegniasis (Jamur Air)", "created_at": "2026-10-08T14:30:56+07:00"}
  ]
}
''';

void main() {
  test('Dashboard.fromJson tidak melempar saat ada post forum bertrend', () {
    final dash = Dashboard.fromJson(jsonDecode(_productionData));

    expect(dash.statCards.totalScans, 4);
    expect(dash.recentScans, hasLength(2));
    expect(dash.recentScans.last.status, 'failed');
    expect(dash.diseaseTrend, hasLength(2));
    expect(dash.topDisease?.name, 'Penyakit Bakteri Insang');
    expect(dash.activityFeed, hasLength(1));

    expect(dash.trendingPosts, hasLength(1));
    expect(dash.trendingPosts.first.id, 1);
    expect(dash.trendingPosts.first.isQuestion, isTrue);
    expect(dash.trendingPosts.first.author?.id, '01a11a51-f7fc-724d-b35e-5f258041a87d');
    expect(dash.trendingPosts.first.linkedScan?.confidence, closeTo(74.5, 0.001));
  });

  test('payload tanpa trending_posts tetap aman', () {
    final dash = Dashboard.fromJson(jsonDecode(
        '{"stat_cards": {"total_scans": 0}, "recent_scans": [], '
        '"trending_posts": [], "disease_trend": [], "activity_feed": []}'));

    expect(dash.trendingPosts, isEmpty);
    expect(dash.topDisease, isNull);
  });
}
