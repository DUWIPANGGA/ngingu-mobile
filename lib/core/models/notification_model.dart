/// Notification models (API.md §8.1–§8.5, FR-06).
library;

import 'package:flutter/material.dart';

/// The 7 notification types (API.md §8.1 / §8.5).
class NotifType {
  NotifType._();

  static const String scanResult = 'scan_result';
  static const String forumReply = 'forum_reply';
  static const String mention = 'mention';
  static const String outbreak = 'outbreak';
  static const String tips = 'tips';
  static const String security = 'security';
  static const String weekly = 'weekly';

  static const List<String> all = [
    scanResult,
    forumReply,
    mention,
    outbreak,
    tips,
    security,
    weekly,
  ];

  static String label(String type) {
    switch (type) {
      case scanResult:
        return 'Hasil Scan';
      case forumReply:
        return 'Balasan Forum';
      case mention:
        return 'Sebutan (@mention)';
      case outbreak:
        return 'Alert Wabah';
      case tips:
        return 'Tips Harian';
      case security:
        return 'Keamanan';
      case weekly:
        return 'Ringkasan Mingguan';
      default:
        return type;
    }
  }

  static IconData icon(String type) {
    switch (type) {
      case scanResult:
        return Icons.science_outlined;
      case forumReply:
        return Icons.forum_outlined;
      case mention:
        return Icons.alternate_email_outlined;
      case outbreak:
        return Icons.campaign_outlined;
      case tips:
        return Icons.tips_and_updates_outlined;
      case security:
        return Icons.shield_outlined;
      case weekly:
        return Icons.calendar_month_outlined;
      default:
        return Icons.notifications_none;
    }
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.data = const {},
    this.readAt,
    this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final String? readAt;
  final String? createdAt;

  bool get isRead => readAt != null;

  /// `data.scan_id` when the notification links to a scan result.
  String? get scanId => data['scan_id']?.toString();

  factory AppNotification.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return AppNotification(
      id: (j['id'] as num?)?.toInt() ?? 0,
      type: (j['type'] as String?) ?? '',
      title: (j['title'] as String?) ?? '',
      body: j['body'] as String?,
      data: j['data'] is Map<String, dynamic>
          ? j['data'] as Map<String, dynamic>
          : const {},
      readAt: j['read_at'] as String?,
      createdAt: j['created_at'] as String?,
    );
  }
}

class NotificationSetting {
  const NotificationSetting({
    required this.type,
    this.viaPush = false,
    this.viaEmail = true,
    this.viaInapp = true,
  });

  final String type;
  final bool viaPush;
  final bool viaEmail;
  final bool viaInapp;

  NotificationSetting copyWith({bool? viaPush, bool? viaEmail, bool? viaInapp}) =>
      NotificationSetting(
        type: type,
        viaPush: viaPush ?? this.viaPush,
        viaEmail: viaEmail ?? this.viaEmail,
        viaInapp: viaInapp ?? this.viaInapp,
      );

  factory NotificationSetting.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return NotificationSetting(
      type: (j['type'] as String?) ?? '',
      viaPush: j['via_push'] == true,
      viaEmail: j['via_email'] != false,
      viaInapp: j['via_inapp'] != false,
    );
  }

  Map<String, dynamic> toRequest() => {
        'type': type,
        'via_push': viaPush,
        'via_email': viaEmail,
        'via_inapp': viaInapp,
      };
}
