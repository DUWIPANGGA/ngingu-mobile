import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notifikasi lokal perangkat (peringatan wabah sekitar, dsb.).
///
/// Best-effort: semua kegagalan ditelan agar tidak mengganggu alur utama.
class LocalAlertService {
  LocalAlertService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _ready = false;

  static Future<void> ensureInitialized() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (_) {
      // Diabaikan — fallback ke snackbar di caller.
    }
  }

  /// Tampilkan peringatan wabah di dekat pengguna. Mengembalikan `true`
  /// jika notifikasi sistem berhasil ditampilkan.
  static Future<bool> showOutbreakNearby({
    required String province,
    required String disease,
    required int cases,
    required double km,
  }) async {
    try {
      await ensureInitialized();
      if (!_ready) return false;
      await _plugin.show(
        id: 1001,
        title: 'Wabah di dekatmu',
        body: 'Wabah $disease terdeteksi di $province '
            '($cases kasus, ±${km.toStringAsFixed(0)} km).',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'outbreak',
            'Peringatan wabah',
            channelDescription: 'Wabah penyakit ikan di sekitar lokasi',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
