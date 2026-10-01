/// Dashboard payload (API.md §7.1, FR-07).
library;

import 'forum_model.dart';
import 'scan_model.dart';

class StatCards {
  const StatCards({
    this.totalScans = 0,
    this.diseasesDetected = 0,
    this.activePonds = 0,
    this.questionsAnswered = 0,
  });

  final int totalScans;
  final int diseasesDetected;
  final int activePonds;
  final int questionsAnswered;

  factory StatCards.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return StatCards(
      totalScans: (j['total_scans'] as num?)?.toInt() ?? 0,
      diseasesDetected: (j['diseases_detected'] as num?)?.toInt() ?? 0,
      activePonds: (j['active_ponds'] as num?)?.toInt() ?? 0,
      questionsAnswered: (j['questions_answered'] as num?)?.toInt() ?? 0,
    );
  }
}

class TrendPoint {
  const TrendPoint({required this.date, this.count = 0});

  final String date;
  final int count;

  factory TrendPoint.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return TrendPoint(
      date: (j['date'] as String?) ?? '',
      count: (j['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TopDisease {
  const TopDisease({this.id, this.name, this.count = 0});

  final int? id;
  final String? name;
  final int count;

  factory TopDisease.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const TopDisease();
    return TopDisease(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ActivityItem {
  const ActivityItem({this.type, this.title, this.createdAt});

  final String? type;
  final String? title;
  final String? createdAt;

  factory ActivityItem.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return ActivityItem(
      type: j['type'] as String?,
      title: j['title'] as String?,
      createdAt: j['created_at'] as String?,
    );
  }
}

class Dashboard {
  const Dashboard({
    this.statCards = const StatCards(),
    this.recentScans = const [],
    this.trendingPosts = const [],
    this.diseaseTrend = const [],
    this.topDisease,
    this.activityFeed = const [],
  });

  final StatCards statCards;
  final List<ScanSummary> recentScans;
  final List<ForumPost> trendingPosts;
  final List<TrendPoint> diseaseTrend;
  final TopDisease? topDisease;
  final List<ActivityItem> activityFeed;

  factory Dashboard.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return Dashboard(
      statCards: j['stat_cards'] == null
          ? const StatCards()
          : StatCards.fromJson(j['stat_cards']),
      recentScans:
          ((j['recent_scans'] as List?) ?? []).map(ScanSummary.fromJson).toList(),
      trendingPosts:
          ((j['trending_posts'] as List?) ?? []).map(ForumPost.fromJson).toList(),
      diseaseTrend:
          ((j['disease_trend'] as List?) ?? []).map(TrendPoint.fromJson).toList(),
      topDisease:
          j['top_disease_this_week'] == null ? null : TopDisease.fromJson(j['top_disease_this_week']),
      activityFeed:
          ((j['activity_feed'] as List?) ?? []).map(ActivityItem.fromJson).toList(),
    );
  }
}
