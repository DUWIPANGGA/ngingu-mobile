import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// Reactive auth session singleton.
///
/// Hydrate once at startup (`AuthService.init()`), then read the observables
/// — widgets rebuild automatically on change.
class AuthService {
  static const _keyIsGuest = 'is_guest';
  static const _keyAuthToken = 'auth_token';
  static const _keyUser = 'auth_user';

  // ── Reactive state ────────────────────────────────────────────────────────
  static final RxBool isGuestObs = false.obs;
  static final RxBool isLoggedInObs = false.obs;
  static final Rxn<User> currentUser = Rxn<User>();

  static SharedPreferences? _prefs;

  /// Synchronous bearer token — cached after [init] (read by ApiClient interceptor).
  static String get token => _prefs?.getString(_keyAuthToken) ?? '';

  static bool get isLoggedIn => isLoggedInObs.value;
  static bool get isGuest => isGuestObs.value;
  static bool get isAuthed => isLoggedIn && !isGuest;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final guest = _prefs!.getBool(_keyIsGuest) ?? false;
    final tokenValue = _prefs!.getString(_keyAuthToken) ?? '';
    isGuestObs.value = guest;
    isLoggedInObs.value = tokenValue.isNotEmpty && !guest;
    final userJson = _prefs!.getString(_keyUser);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        currentUser.value = User.fromJson(jsonDecode(userJson));
      } catch (_) {
        currentUser.value = null;
      }
    }
  }

  /// Persist a successful login/register payload (API.md §3.1/§3.3).
  static Future<void> setSession(AuthSession session) async {
    await _prefs?.setString(_keyAuthToken, session.token);
    await _prefs?.setString(_keyUser, jsonEncode(_userToJson(session.user)));
    await _prefs?.remove(_keyIsGuest);
    currentUser.value = session.user;
    isGuestObs.value = false;
    isLoggedInObs.value = true;
  }

  /// Replace cached user profile (after `PUT /api/user/profile`, avatar upload…).
  static Future<void> updateUser(User user) async {
    await _prefs?.setString(_keyUser, jsonEncode(_userToJson(user)));
    currentUser.value = user;
  }

  /// Browse mode without an account (FR-03.1.5 — encyclopedia is public).
  static Future<void> setGuestMode() async {
    await _prefs?.setBool(_keyIsGuest, true);
    await _prefs?.remove(_keyAuthToken);
    await _prefs?.remove(_keyUser);
    currentUser.value = null;
    isGuestObs.value = true;
    isLoggedInObs.value = false;
  }

  /// Clear every local credential (logout / revoked token).
  static Future<void> clearSession() async {
    await _prefs?.remove(_keyIsGuest);
    await _prefs?.remove(_keyAuthToken);
    await _prefs?.remove(_keyUser);
    currentUser.value = null;
    isGuestObs.value = false;
    isLoggedInObs.value = false;
  }

  static Map<String, dynamic> _userToJson(User u) => {
        'id': u.id,
        'name': u.name,
        'username': u.username,
        'email': u.email,
        'phone': u.phone,
        'avatar_url': u.avatarUrl,
        'bio': u.bio,
        'province': u.province,
        'fish_types': u.fishTypes,
        'reputation_points': u.reputationPoints,
        'reputation_level': u.reputationLevel,
        'role': u.role,
        'email_verified_at': u.emailVerifiedAt,
        'created_at': u.createdAt,
      };
}
