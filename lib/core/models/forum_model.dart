/// Forum models (API.md §6.1–§6.15, FR-05).
library;

class ForumCategory {
  const ForumCategory({this.id, required this.name, this.slug, this.icon, this.postsCount});

  final int? id;
  final String name;
  final String? slug;
  final String? icon;
  final int? postsCount;

  factory ForumCategory.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return ForumCategory(
      id: (j['id'] as num?)?.toInt(),
      name: (j['name'] as String?) ?? '-',
      slug: j['slug'] as String?,
      icon: j['icon'] as String?,
      postsCount: (j['posts_count'] as num?)?.toInt(),
    );
  }
}

class ForumAuthor {
  const ForumAuthor({
    this.id,
    required this.name,
    this.avatarUrl,
    this.reputationLevel,
  });

  final int? id;
  final String name;
  final String? avatarUrl;
  final String? reputationLevel;

  factory ForumAuthor.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const ForumAuthor(name: '-');
    }
    return ForumAuthor(
      id: (json['id'] as num?)?.toInt(),
      name: (json['name'] as String?) ?? '-',
      avatarUrl: json['avatar_url'] as String?,
      reputationLevel: json['reputation_level'] as String?,
    );
  }
}

class LinkedScan {
  const LinkedScan({this.scanId, this.diseaseName, this.confidence, this.thumbnailUrl});

  final String? scanId;
  final String? diseaseName;
  final double? confidence;
  final String? thumbnailUrl;

  factory LinkedScan.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const LinkedScan();
    final disease = json['disease'] as Map<String, dynamic>?;
    return LinkedScan(
      scanId: json['scan_id']?.toString(),
      diseaseName: disease?['name'] as String?,
      confidence: (disease?['confidence'] as num?)?.toDouble(),
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
}

class ViewerState {
  const ViewerState({
    this.isBookmarked = false,
    this.isFollowing = false,
    this.myVote = 0,
  });

  final bool isBookmarked;
  final bool isFollowing;
  final int myVote;

  factory ViewerState.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const ViewerState();
    return ViewerState(
      isBookmarked: json['is_bookmarked'] == true,
      isFollowing: json['is_following'] == true,
      myVote: (json['my_vote'] as num?)?.toInt() ?? 0,
    );
  }
}

class ForumPost {
  const ForumPost({
    required this.id,
    required this.type,
    required this.title,
    this.excerpt,
    this.contentHtml,
    this.imageUrls = const [],
    this.linkedScanId,
    this.category,
    this.author,
    this.linkedScan,
    this.tags = const [],
    this.votesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.hasBestAnswer = false,
    this.isPinned = false,
    this.status,
    this.createdAt,
    this.comments = const [],
    this.viewer = const ViewerState(),
  });

  final int id;
  final String type;
  final String title;
  final String? excerpt;
  final String? contentHtml;
  final List<String> imageUrls;
  final String? linkedScanId;
  final ForumCategory? category;
  final ForumAuthor? author;
  final LinkedScan? linkedScan;
  final List<String> tags;
  final int votesCount;
  final int commentsCount;
  final int viewsCount;
  final bool hasBestAnswer;
  final bool isPinned;
  final String? status;
  final String? createdAt;

  /// Only present on `GET /api/forum/posts/{id}` (§6.4).
  final List<ForumComment> comments;
  final ViewerState viewer;

  bool get isQuestion => type == 'question';
  bool get isPending => status == 'pending';

  ForumPost copyWith({
    int? votesCount,
    int? commentsCount,
    ViewerState? viewer,
    String? contentHtml,
    List<String>? imageUrls,
    String? status,
    bool? hasBestAnswer,
  }) =>
      ForumPost(
        id: id,
        type: type,
        title: title,
        excerpt: excerpt,
        contentHtml: contentHtml ?? this.contentHtml,
        imageUrls: imageUrls ?? this.imageUrls,
        linkedScanId: linkedScanId,
        category: category,
        author: author,
        linkedScan: linkedScan,
        tags: tags,
        votesCount: votesCount ?? this.votesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        viewsCount: viewsCount,
        hasBestAnswer: hasBestAnswer ?? this.hasBestAnswer,
        isPinned: isPinned,
        status: status ?? this.status,
        createdAt: createdAt,
        comments: comments,
        viewer: viewer ?? this.viewer,
      );

  factory ForumPost.fromJson(dynamic json, {bool withDetail = false}) {
    final j = json as Map<String, dynamic>;
    return ForumPost(
      id: (j['id'] as num?)?.toInt() ?? 0,
      type: (j['type'] as String?) ?? 'discussion',
      title: (j['title'] as String?) ?? '',
      excerpt: j['excerpt'] as String?,
      contentHtml: j['content_html'] as String?,
      imageUrls: ((j['image_urls'] as List?) ?? []).map((e) => e.toString()).toList(),
      linkedScanId: j['linked_scan_id']?.toString(),
      category: j['category'] == null ? null : ForumCategory.fromJson(j['category']),
      author: j['author'] == null ? null : ForumAuthor.fromJson(j['author']),
      linkedScan: j['linked_scan'] == null ? null : LinkedScan.fromJson(j['linked_scan']),
      tags: ((j['tags'] as List?) ?? []).map((e) => e.toString()).toList(),
      votesCount: (j['votes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (j['comments_count'] as num?)?.toInt() ?? 0,
      viewsCount: (j['views_count'] as num?)?.toInt() ?? 0,
      hasBestAnswer: j['has_best_answer'] == true,
      isPinned: j['is_pinned'] == true,
      status: j['status'] as String?,
      createdAt: j['created_at'] as String?,
      comments: withDetail
          ? ((j['comments'] as List?) ?? []).map(ForumComment.fromJson).toList()
          : const [],
      viewer: ViewerState.fromJson(j['viewer']),
    );
  }
}

class ForumComment {
  const ForumComment({
    required this.id,
    this.parentId,
    this.author,
    this.contentHtml,
    this.images = const [],
    this.votesCount = 0,
    this.isBestAnswer = false,
    this.mentionUsers = const [],
    this.createdAt,
    this.replies = const [],
    this.myVote = 0,
  });

  final int id;
  final int? parentId;
  final ForumAuthor? author;
  final String? contentHtml;
  final List<String> images;
  final int votesCount;
  final bool isBestAnswer;
  final List<String> mentionUsers;
  final String? createdAt;
  final List<ForumComment> replies;
  final int myVote;

  ForumComment copyWith({int? votesCount, int? myVote, bool? isBestAnswer}) =>
      ForumComment(
        id: id,
        parentId: parentId,
        author: author,
        contentHtml: contentHtml,
        images: images,
        votesCount: votesCount ?? this.votesCount,
        isBestAnswer: isBestAnswer ?? this.isBestAnswer,
        mentionUsers: mentionUsers,
        createdAt: createdAt,
        replies: replies,
        myVote: myVote ?? this.myVote,
      );

  factory ForumComment.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return ForumComment(
      id: (j['id'] as num?)?.toInt() ?? 0,
      parentId: (j['parent_id'] as num?)?.toInt(),
      author: j['author'] == null ? null : ForumAuthor.fromJson(j['author']),
      contentHtml: j['content_html'] as String?,
      images: ((j['images'] as List?) ?? []).map((e) => e.toString()).toList(),
      votesCount: (j['votes_count'] as num?)?.toInt() ?? 0,
      isBestAnswer: j['is_best_answer'] == true,
      mentionUsers:
          ((j['mention_users'] as List?) ?? []).map((e) => e.toString()).toList(),
      createdAt: j['created_at'] as String?,
      replies: ((j['replies'] as List?) ?? []).map(ForumComment.fromJson).toList(),
      myVote: (j['my_vote'] as num?)?.toInt() ?? 0,
    );
  }
}

/// `POST /api/forum/posts/{id}/vote` response (§6.7).
class VoteResult {
  const VoteResult({this.votesCount = 0, this.myVote = 0});

  final int votesCount;
  final int myVote;

  factory VoteResult.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return VoteResult(
      votesCount: (j['votes_count'] as num?)?.toInt() ?? 0,
      myVote: (j['my_vote'] as num?)?.toInt() ?? 0,
    );
  }
}
