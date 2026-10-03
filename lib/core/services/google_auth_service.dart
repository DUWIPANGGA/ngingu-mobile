import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Shared Google Sign-In helper for login & register.
///
/// Backend uses a single endpoint `POST /api/auth/google` with `id_token`
/// (existing user → login, new user → auto-register), so both screens
/// share this flow.
class GoogleAuthService {
  GoogleAuthService._();

  static const serverClientId =
      '192572861773-qfpnedaikjredjpskhd4pofuibg2ivd8.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: serverClientId,
  );

  /// Shows the Google account picker and returns the `id_token`.
  ///
  /// Returns `null` when the user cancels the picker.
  /// Throws on platform / network errors so callers can show a snackbar.
  static Future<String?> signInAndGetIdToken() async {
    // Force account picker (same behavior as before on login screen).
    await _googleSignIn.signOut();
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // cancelled
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      debugPrint('[GoogleAuth] idToken kosong (serverClientId salah / Play Services bermasalah)');
    }
    return googleAuth.idToken;
  }

  /// Pesan error yang ramah untuk kasus umum ( Dipakai login & register ).
  /// ApiException 10 = SHA-1 / OAuth client belum terdaftar.
  static String friendlyErrorMessage(Object e) {
    final s = e.toString();
    debugPrint('[GoogleAuth] gagal: $s');
    if (s.contains('ApiException: 10') ||
        s.contains('DEVELOPER_ERROR') ||
        s.contains('error 10')) {
      return 'Konfigurasi Google belum cocok (SHA-1 / OAuth client). Hubungi backend / cek google-services.json.';
    }
    if (s.contains('network') || s.contains('7:')) {
      return 'Jaringan bermasalah. Periksa internet emulator.';
    }
    if (s.contains('sign_in_canceled') || s.contains('canceled')) {
      return 'Login Google dibatalkan.';
    }
    return 'Gagal tersambung ke Google. Coba lagi.';
  }

  static Future<void> signOut() => _googleSignIn.signOut();
}
