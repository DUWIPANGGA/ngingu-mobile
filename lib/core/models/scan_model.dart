/// Scan models (API.md §4.1–§4.6).
library;

class ScanPondRef {
  const ScanPondRef({this.id, this.name});

  final String? id;
  final String? name;

  factory ScanPondRef.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const ScanPondRef();
    return ScanPondRef(id: '${json['id']}', name: json['name'] as String?);
  }
}

class ScanDiseaseRef {
  const ScanDiseaseRef({
    this.id,
    this.name,
    this.slug,
    this.severity,
    this.confidence,
  });

  final int? id;
  final String? name;
  final String? slug;
  final String? severity;
  final double? confidence;

  factory ScanDiseaseRef.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const ScanDiseaseRef();
    return ScanDiseaseRef(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      severity: json['severity'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

class Prediction {
  const Prediction({required this.name, this.confidence});

  final String name;
  final double? confidence;

  factory Prediction.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return Prediction(
      name: (j['name'] as String?) ?? '-',
      confidence: (j['confidence'] as num?)?.toDouble(),
    );
  }
}

class ScanImage {
  const ScanImage({required this.url, this.isPrimary = false, this.gradcamUrl});

  final String url;
  final bool isPrimary;
  final String? gradcamUrl;

  factory ScanImage.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return ScanImage(
      url: (j['url'] as String?) ?? '',
      isPrimary: j['is_primary'] == true,
      gradcamUrl: j['gradcam_url'] as String?,
    );
  }
}

class ScanError {
  const ScanError({this.code, this.message});

  final String? code;
  final String? message;

  factory ScanError.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const ScanError();
    return ScanError(code: json['code'] as String?, message: json['message'] as String?);
  }
}

/// Summary row used by history list & dashboard (§4.2).
class ScanSummary {
  const ScanSummary({
    required this.scanId,
    this.thumbnailUrl,
    this.fishType,
    this.pond,
    this.disease,
    this.confidence,
    this.status,
    this.createdAt,
  });

  final String scanId;
  final String? thumbnailUrl;
  final String? fishType;
  final ScanPondRef? pond;
  final ScanDiseaseRef? disease;
  final double? confidence;
  final String? status;
  final String? createdAt;

  factory ScanSummary.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return ScanSummary(
      scanId: '${j['scan_id']}',
      thumbnailUrl: j['thumbnail_url'] as String?,
      fishType: j['fish_type'] as String?,
      pond: j['pond'] == null ? null : ScanPondRef.fromJson(j['pond']),
      disease: j['disease'] == null ? null : ScanDiseaseRef.fromJson(j['disease']),
      confidence: (j['confidence'] as num?)?.toDouble(),
      status: j['status'] as String?,
      createdAt: j['created_at'] as String?,
    );
  }
}

/// `POST /api/scans` → 202 payload (§4.1).
class CreateScanResponse {
  const CreateScanResponse({
    required this.scanId,
    this.status,
    this.imagesCount = 0,
    this.estimatedSeconds,
  });

  final String scanId;
  final String? status;
  final int imagesCount;
  final int? estimatedSeconds;

  factory CreateScanResponse.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return CreateScanResponse(
      scanId: '${j['scan_id']}',
      status: j['status'] as String?,
      imagesCount: (j['images_count'] as num?)?.toInt() ?? 0,
      estimatedSeconds: (j['estimated_seconds'] as num?)?.toInt(),
    );
  }
}

/// Full result payload of `GET /api/scans/{id}` (§4.3).
class ScanDetail {
  const ScanDetail({
    required this.scanId,
    required this.status,
    this.fishType,
    this.pond,
    this.images = const [],
    this.disease,
    this.topPredictions = const [],
    this.lowConfidenceWarning = false,
    this.gradcamUrl,
    this.processingTimeMs,
    this.modelVersion,
    this.treatmentUrl,
    this.error,
    this.pollAfterMs,
    this.createdAt,
  });

  final String scanId;
  final String status;
  final String? fishType;
  final ScanPondRef? pond;
  final List<ScanImage> images;
  final ScanDiseaseRef? disease;
  final List<Prediction> topPredictions;
  final bool lowConfidenceWarning;
  final String? gradcamUrl;
  final int? processingTimeMs;
  final String? modelVersion;
  final String? treatmentUrl;
  final ScanError? error;
  final int? pollAfterMs;
  final String? createdAt;

  bool get isDone => status == 'done';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing' || status == 'pending';

  /// Top-level confidence (from `disease.confidence`, falling back to top prediction).
  double? get confidence =>
      disease?.confidence ??
      (topPredictions.isNotEmpty ? topPredictions.first.confidence : null);

  factory ScanDetail.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return ScanDetail(
      scanId: '${j['scan_id']}',
      status: (j['status'] as String?) ?? 'processing',
      fishType: j['fish_type'] as String?,
      pond: j['pond'] == null ? null : ScanPondRef.fromJson(j['pond']),
      images: ((j['images'] as List?) ?? []).map(ScanImage.fromJson).toList(),
      disease: j['disease'] == null ? null : ScanDiseaseRef.fromJson(j['disease']),
      topPredictions:
          ((j['top_predictions'] as List?) ?? []).map(Prediction.fromJson).toList(),
      lowConfidenceWarning: j['low_confidence_warning'] == true,
      gradcamUrl: j['gradcam_url'] as String?,
      processingTimeMs: (j['processing_time_ms'] as num?)?.toInt(),
      modelVersion: j['model_version'] as String?,
      treatmentUrl: j['treatment_url'] as String?,
      error: j['error'] == null ? null : ScanError.fromJson(j['error']),
      pollAfterMs: (j['poll_after_ms'] as num?)?.toInt(),
      createdAt: j['created_at'] as String?,
    );
  }

  /// Slug of the predicted disease for encyclopedia navigation.
  String? get diseaseSlug => disease?.slug;
}
