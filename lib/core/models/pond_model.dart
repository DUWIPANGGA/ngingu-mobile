/// Pond (kolam/tambak) models — API.md §7.2–§7.6, FR-08.1/FR-04.2.
library;

class Pond {
  const Pond({
    required this.id,
    required this.name,
    this.locationLat,
    this.locationLng,
    this.locationLabel,
    this.areaM2,
    this.capacity,
    this.fishTypes = const [],
    this.description,
    this.healthScore,
    this.scansCount,
    this.createdAt,
  });

  final String id;
  final String name;
  final double? locationLat;
  final double? locationLng;
  final String? locationLabel;
  final double? areaM2;
  final int? capacity;
  final List<String> fishTypes;
  final String? description;
  final int? healthScore;
  final int? scansCount;
  final String? createdAt;

  factory Pond.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return Pond(
      id: '${j['id']}',
      name: (j['name'] as String?) ?? '-',
      locationLat: (j['location_lat'] as num?)?.toDouble(),
      locationLng: (j['location_lng'] as num?)?.toDouble(),
      locationLabel: j['location_label'] as String?,
      areaM2: (j['area_m2'] as num?)?.toDouble(),
      capacity: (j['capacity'] as num?)?.toInt(),
      fishTypes: ((j['fish_types'] as List?) ?? []).map((e) => e.toString()).toList(),
      description: j['description'] as String?,
      healthScore: (j['health_score'] as num?)?.toInt(),
      scansCount: (j['scans_count'] as num?)?.toInt(),
      createdAt: j['created_at'] as String?,
    );
  }

  /// Fields accepted by POST/PUT /api/ponds.
  Map<String, dynamic> toRequest() => {
        'name': name,
        if (locationLat != null) 'location_lat': locationLat,
        if (locationLng != null) 'location_lng': locationLng,
        if (locationLabel != null) 'location_label': locationLabel,
        if (areaM2 != null) 'area_m2': areaM2,
        if (capacity != null) 'capacity': capacity,
        'fish_types': fishTypes,
        if (description != null) 'description': description,
      };
}

class HealthTrendPoint {
  const HealthTrendPoint({required this.date, this.scans = 0, this.diseases = const []});

  final String date;
  final int scans;
  final List<String> diseases;

  factory HealthTrendPoint.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return HealthTrendPoint(
      date: (j['date'] as String?) ?? '',
      scans: (j['scans'] as num?)?.toInt() ?? 0,
      diseases: ((j['diseases'] as List?) ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class RepeatAlert {
  const RepeatAlert({this.diseaseId, this.diseaseName, this.occurrences});

  final int? diseaseId;
  final String? diseaseName;
  final int? occurrences;

  factory RepeatAlert.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const RepeatAlert();
    return RepeatAlert(
      diseaseId: (json['disease_id'] as num?)?.toInt(),
      diseaseName: (json['disease_name'] as String?) ?? (json['name'] as String?),
      occurrences: (json['occurrences'] as num?)?.toInt(),
    );
  }
}

class LastScanRef {
  const LastScanRef({this.scanId, this.createdAt});

  final String? scanId;
  final String? createdAt;

  factory LastScanRef.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const LastScanRef();
    return LastScanRef(
      scanId: json['scan_id']?.toString(),
      createdAt: json['created_at'] as String?,
    );
  }
}

class HealthReport {
  const HealthReport({
    this.pondId,
    this.pondName,
    this.healthScore = 100,
    this.trend = const [],
    this.repeatAlert,
    this.lastScan,
  });

  final String? pondId;
  final String? pondName;
  final int healthScore;
  final List<HealthTrendPoint> trend;
  final RepeatAlert? repeatAlert;
  final LastScanRef? lastScan;

  factory HealthReport.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    final pond = j['pond'] as Map<String, dynamic>?;
    return HealthReport(
      pondId: pond?['id']?.toString(),
      pondName: pond?['name'] as String?,
      healthScore: (j['health_score'] as num?)?.toInt() ?? 100,
      trend: ((j['trend'] as List?) ?? []).map(HealthTrendPoint.fromJson).toList(),
      repeatAlert: j['repeat_disease_alert'] == null
          ? null
          : RepeatAlert.fromJson(j['repeat_disease_alert']),
      lastScan: j['last_scan'] == null ? null : LastScanRef.fromJson(j['last_scan']),
    );
  }
}
