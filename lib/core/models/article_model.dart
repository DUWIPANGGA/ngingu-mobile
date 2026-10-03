/// Artikel edukasi (FR-03.3) — `GET /api/articles`.
library;

class Article {
  const Article({
    this.id,
    required this.title,
    this.slug,
    this.category,
    this.excerpt,
    this.coverUrl,
    this.readMinutes,
    this.publishedAt,
  });

  final int? id;
  final String title;
  final String? slug;
  final String? category;
  final String? excerpt;
  final String? coverUrl;
  final int? readMinutes;
  final String? publishedAt;

  factory Article.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return Article(
      id: (j['id'] as num?)?.toInt(),
      title: (j['title'] as String?) ?? '-',
      slug: j['slug'] as String?,
      category: j['category'] as String?,
      excerpt: j['excerpt'] as String?,
      coverUrl: j['cover_url'] as String?,
      readMinutes: (j['read_minutes'] as num?)?.toInt(),
      publishedAt: j['published_at'] as String?,
    );
  }
}

/// Detail artikel — `GET /api/articles/{id}`.
class ArticleDetail extends Article {
  const ArticleDetail({
    super.id,
    required super.title,
    super.slug,
    super.category,
    super.excerpt,
    super.coverUrl,
    super.readMinutes,
    super.publishedAt,
    this.paragraphs = const [],
    this.contentHtml,
  });

  final List<String> paragraphs;
  final String? contentHtml;

  factory ArticleDetail.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return ArticleDetail(
      id: (j['id'] as num?)?.toInt(),
      title: (j['title'] as String?) ?? '-',
      slug: j['slug'] as String?,
      category: j['category'] as String?,
      excerpt: j['excerpt'] as String?,
      coverUrl: j['cover_url'] as String?,
      readMinutes: (j['read_minutes'] as num?)?.toInt(),
      publishedAt: j['published_at'] as String?,
      paragraphs: ((j['content_paragraphs'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      contentHtml: j['content_html'] as String?,
    );
  }

  /// Paragraf siap tampil (fallback dari HTML bila perlu).
  List<String> get body {
    if (paragraphs.isNotEmpty) return paragraphs;
    final text = _stripHtml(contentHtml);
    if (text.isEmpty) return const [];
    return text
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

String _stripHtml(String? html) {
  if (html == null || html.isEmpty) return '';
  return html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();
}
