/// Tips, outbreak alerts, heatmap & pins GIS models
/// (API.md §7.11, §7.13, §8.6–§8.7, FR-06.4/6.5/FR-07.3).
library;

class Tip {
  const Tip({this.id, this.content, this.category, this.publishedAt});

  final int? id;
  final String? content;
  final String? category;
  final String? publishedAt;

  factory Tip.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const Tip();
    return Tip(
      id: (json['id'] as num?)?.toInt(),
      content: json['content'] as String?,
      category: json['category'] as String?,
      publishedAt: json['published_at'] as String?,
    );
  }
}

class Outbreak {
  const Outbreak({
    this.id,
    this.diseaseId,
    this.diseaseName,
    this.diseaseSlug,
    this.severity,
    this.province,
    this.cases7d = 0,
    this.threshold,
    this.message,
    this.status,
    this.createdAt,
  });

  final int? id;
  final int? diseaseId;
  final String? diseaseName;
  final String? diseaseSlug;
  final String? severity;
  final String? province;
  final int cases7d;
  final int? threshold;
  final String? message;
  final String? status;
  final String? createdAt;

  factory Outbreak.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    final disease = j['disease'] as Map<String, dynamic>?;
    return Outbreak(
      id: (j['id'] as num?)?.toInt(),
      diseaseId: (disease?['id'] as num?)?.toInt(),
      diseaseName: disease?['name'] as String?,
      diseaseSlug: disease?['slug'] as String?,
      severity: disease?['severity'] as String?,
      province: j['province'] as String?,
      cases7d: (j['cases_7d'] as num?)?.toInt() ?? 0,
      threshold: (j['threshold'] as num?)?.toInt(),
      message: j['message'] as String?,
      status: j['status'] as String?,
      createdAt: j['created_at'] as String?,
    );
  }
}

class HeatmapPoint {
  const HeatmapPoint({
    required this.kecamatan,
    required this.lat,
    required this.lng,
    this.cases = 0,
    this.topDisease,
  });

  /// Nama kecamatan (agregasi per kecamatan, fokus Kab. Indramayu).
  final String kecamatan;
  final double lat;
  final double lng;
  final int cases;
  final String? topDisease;

  factory HeatmapPoint.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return HeatmapPoint(
      kecamatan: (j['kecamatan'] as String?) ?? '-',
      lat: (j['lat'] as num?)?.toDouble() ?? 0,
      lng: (j['lng'] as num?)?.toDouble() ?? 0,
      cases: (j['cases'] as num?)?.toInt() ?? 0,
      topDisease: j['top_disease'] as String?,
    );
  }
}

/// Satu hasil scan yang punya koordinat (GPS scan / fallback kolam) — marker
/// individual di peta GIS (API.md §7.13 `GET /api/map/pins`, publik).
///
/// Privasi (FR-07.3): endpoint tidak mengirim nama kolam / label lokasi /
/// identitas pemilik — hanya penyakit dan hasil prediksi.
class ScanPin {
  const ScanPin({
    required this.id,
    required this.lat,
    required this.lng,
    this.kecamatan,
    this.diseaseId,
    this.diseaseName,
    this.severity,
    this.confidenceScore = 0,
    this.fishType,
    this.scannedAt,
  });

  final int id;
  final double lat;
  final double lng;

  /// Kecamatan hasil pemetaan koordinat scan (null bila di luar Kab. Indramayu).
  final String? kecamatan;
  final int? diseaseId;
  final String? diseaseName;
  final String? severity;
  final double confidenceScore;
  final String? fishType;
  final String? scannedAt;

  /// Koordinat valid untuk ditaruh di peta.
  bool get hasValidCoords =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  factory ScanPin.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return ScanPin(
      id: (j['id'] as num?)?.toInt() ?? 0,
      lat: (j['lat'] as num?)?.toDouble() ?? 0,
      lng: (j['lng'] as num?)?.toDouble() ?? 0,
      kecamatan: j['kecamatan'] as String?,
      diseaseId: (j['disease_id'] as num?)?.toInt(),
      diseaseName: j['disease_name'] as String?,
      severity: j['severity'] as String?,
      confidenceScore: (j['confidence_score'] as num?)?.toDouble() ?? 0,
      fishType: j['fish_type'] as String?,
      scannedAt: j['scanned_at'] as String?,
    );
  }
}
