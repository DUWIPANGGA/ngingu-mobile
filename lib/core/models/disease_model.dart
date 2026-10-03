/// Encyclopedia models (API.md §5.1–§5.4, FR-03).
library;

class RecoveryDays {
  const RecoveryDays({this.min, this.max});

  final int? min;
  final int? max;

  factory RecoveryDays.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const RecoveryDays();
    return RecoveryDays(
      min: (json['min'] as num?)?.toInt(),
      max: (json['max'] as num?)?.toInt(),
    );
  }

  String get label {
    if (min == null && max == null) return '-';
    return '${min ?? '?'}–${max ?? '?'} hari';
  }
}

class DiseaseImage {
  const DiseaseImage({required this.url, this.caption, this.isPrimary = false});

  final String url;
  final String? caption;
  final bool isPrimary;

  factory DiseaseImage.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return DiseaseImage(
      url: (j['url'] as String?) ?? '',
      caption: j['caption'] as String?,
      isPrimary: j['is_primary'] == true,
    );
  }
}

class Medicine {
  const Medicine({this.name, this.dose, this.frequency, this.notes});

  final String? name;
  final String? dose;
  final String? frequency;
  final String? notes;

  factory Medicine.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const Medicine();
    return Medicine(
      name: json['name'] as String?,
      dose: json['dose'] as String?,
      frequency: json['frequency'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class Treatment {
  const Treatment({
    this.stepOrder,
    this.title,
    this.description,
    this.medicines = const [],
    this.durationDays,
  });

  final int? stepOrder;
  final String? title;
  final String? description;
  final List<Medicine> medicines;
  final int? durationDays;

  factory Treatment.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return Treatment(
      stepOrder: (j['step_order'] as num?)?.toInt(),
      title: j['title'] as String?,
      description: j['description'] as String?,
      medicines: ((j['medicines'] as List?) ?? []).map(Medicine.fromJson).toList(),
      durationDays: (j['duration_days'] as num?)?.toInt(),
    );
  }
}

/// List/search row (§5.1, §5.3).
class DiseaseItem {
  const DiseaseItem({
    this.id,
    required this.name,
    required this.slug,
    this.category,
    this.severity,
    this.thumbnailUrl,
    this.fishTypes = const [],
    this.recoveryDays,
    this.snippet,
  });

  final int? id;
  final String name;
  final String slug;
  final String? category;
  final String? severity;
  final String? thumbnailUrl;
  final List<String> fishTypes;
  final RecoveryDays? recoveryDays;
  final String? snippet;

  factory DiseaseItem.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return DiseaseItem(
      id: (j['id'] as num?)?.toInt(),
      name: (j['name'] as String?) ?? '-',
      slug: (j['slug'] as String?) ?? '',
      category: j['category'] as String?,
      severity: j['severity'] as String?,
      thumbnailUrl: j['thumbnail_url'] as String?,
      fishTypes: ((j['fish_types'] as List?) ?? []).map((e) => e.toString()).toList(),
      recoveryDays: j['recovery_days'] == null
          ? null
          : RecoveryDays.fromJson(j['recovery_days']),
      snippet: j['snippet'] as String?,
    );
  }

  /// Untuk cache offline (SharedPreferences).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'category': category,
        'severity': severity,
        'thumbnail_url': thumbnailUrl,
        'fish_types': fishTypes,
        'recovery_days': recoveryDays == null
            ? null
            : {'min': recoveryDays!.min, 'max': recoveryDays!.max},
        'snippet': snippet,
      };
}

/// Full detail payload (§5.2).
class DiseaseDetail {
  const DiseaseDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.category,
    this.severity,
    this.description,
    this.causes,
    this.symptoms = const [],
    this.fishTypes = const [],
    this.images = const [],
    this.treatments = const [],
    this.preventions = const [],
    this.recoveryDays,
    this.relatedForumPostsCount = 0,
    this.createdAt,
  });

  final int id;
  final String name;
  final String slug;
  final String? category;
  final String? severity;
  final String? description;
  final String? causes;
  final List<String> symptoms;
  final List<String> fishTypes;
  final List<DiseaseImage> images;
  final List<Treatment> treatments;
  final List<String> preventions;
  final RecoveryDays? recoveryDays;
  final int relatedForumPostsCount;
  final String? createdAt;

  factory DiseaseDetail.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return DiseaseDetail(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '-',
      slug: (j['slug'] as String?) ?? '',
      category: j['category'] as String?,
      severity: j['severity'] as String?,
      description: j['description'] as String?,
      causes: j['causes'] as String?,
      symptoms: ((j['symptoms'] as List?) ?? []).map((e) => e.toString()).toList(),
      fishTypes: ((j['fish_types'] as List?) ?? []).map((e) => e.toString()).toList(),
      images: ((j['images'] as List?) ?? []).map(DiseaseImage.fromJson).toList(),
      treatments: ((j['treatments'] as List?) ?? []).map(Treatment.fromJson).toList(),
      preventions: ((j['preventions'] as List?) ?? []).map((e) => e.toString()).toList(),
      recoveryDays: j['recovery_days'] == null
          ? null
          : RecoveryDays.fromJson(j['recovery_days']),
      relatedForumPostsCount: (j['related_forum_posts_count'] as num?)?.toInt() ?? 0,
      createdAt: j['created_at'] as String?,
    );
  }
}
