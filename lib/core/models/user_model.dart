/// Auth payload models (API.md §3.1–§3.3, §7.7, §7.10).
library;

class User {
  const User({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.province,
    this.fishTypes = const [],
    this.reputationPoints = 0,
    this.reputationLevel = 'Pemula',
    this.role = 'user',
    this.emailVerifiedAt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? username;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final String? province;
  final List<String> fishTypes;
  final int reputationPoints;
  final String reputationLevel;
  final String role;
  final String? emailVerifiedAt;
  final String? createdAt;

  factory User.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return User(
      id: '${j['id']}',
      name: (j['name'] as String?) ?? '',
      username: j['username'] as String?,
      email: j['email'] as String?,
      phone: j['phone'] as String?,
      avatarUrl: j['avatar_url'] as String?,
      bio: j['bio'] as String?,
      province: j['province'] as String?,
      fishTypes: _stringList(j['fish_types']),
      reputationPoints: (j['reputation_points'] as num?)?.toInt() ?? 0,
      reputationLevel: (j['reputation_level'] as String?) ?? 'Pemula',
      role: (j['role'] as String?) ?? 'user',
      emailVerifiedAt: j['email_verified_at'] as String?,
      createdAt: j['created_at'] as String?,
    );
  }

  bool get isAdmin => role == 'admin' || role == 'superadmin';
}

class Badge {
  const Badge({required this.key, required this.label});

  final String key;
  final String label;

  factory Badge.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return Badge(
      key: (j['key'] as String?) ?? '',
      label: (j['label'] as String?) ?? '',
    );
  }
}

/// GET /api/users/{id} — public profile (API.md §7.10, FR-08.4).
class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
    this.bio,
    this.province,
    this.reputationPoints = 0,
    this.reputationLevel = 'Pemula',
    this.badges = const [],
    this.postsCount = 0,
    this.bestAnswersCount = 0,
    this.joinedAt,
    this.isFollowing = false,
  });

  final String id;
  final String name;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final String? province;
  final int reputationPoints;
  final String reputationLevel;
  final List<Badge> badges;
  final int postsCount;
  final int bestAnswersCount;
  final String? joinedAt;
  final bool isFollowing;

  factory PublicProfile.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return PublicProfile(
      id: '${j['id']}',
      name: (j['name'] as String?) ?? '',
      username: j['username'] as String?,
      avatarUrl: j['avatar_url'] as String?,
      bio: j['bio'] as String?,
      province: j['province'] as String?,
      reputationPoints: (j['reputation_points'] as num?)?.toInt() ?? 0,
      reputationLevel: (j['reputation_level'] as String?) ?? 'Pemula',
      badges: ((j['badges'] as List?) ?? []).map(Badge.fromJson).toList(),
      postsCount: (j['posts_count'] as num?)?.toInt() ?? 0,
      bestAnswersCount: (j['best_answers_count'] as num?)?.toInt() ?? 0,
      joinedAt: j['joined_at'] as String?,
      isFollowing: j['is_following'] == true,
    );
  }
}

/// `POST /api/login` / `POST /api/register` success payload.
class AuthSession {
  const AuthSession({
    required this.user,
    required this.token,
    this.tokenExpiresAt,
  });

  final User user;
  final String token;
  final String? tokenExpiresAt;

  factory AuthSession.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return AuthSession(
      user: User.fromJson(j['user']),
      token: (j['token'] as String?) ?? '',
      tokenExpiresAt: j['token_expires_at'] as String?,
    );
  }
}

List<String> _stringList(dynamic raw) =>
    ((raw as List?) ?? []).map((e) => e.toString()).toList();
