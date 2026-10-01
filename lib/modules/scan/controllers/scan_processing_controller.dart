import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../scan_shared.dart';

/// Long-poll loop for a freshly created scan (API.md §4.3, §9.1).
///
/// One `GET /scans/{id}?wait=300` per attempt; `done` → hasil, `failed` →
/// status gagal, masih `pending`/`processing` → ulangi (maks. [_maxAttempts]).
class ScanProcessingController extends GetxController {
  static const int _maxAttempts = 6;
  static const List<String> _messages = [
    'Menganalisis foto…',
    'Model AI bekerja…',
    'Memeriksa kualitas gambar…',
    'Menyusun hasil prediksi…',
  ];

  late final String scanId;

  final RxString status = 'processing'.obs;
  final RxBool isPolling = false.obs;
  final RxBool isFailed = false.obs;
  final RxBool canManualCheck = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt messageIndex = 0.obs;

  int _attempts = 0;
  bool _closed = false;
  CancelToken? _token;
  Timer? _messageTimer;

  @override
  void onInit() {
    super.onInit();
    scanId = scanIdFromArguments();
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (status.value == 'failed' || status.value == 'done') return;
      messageIndex.value = (messageIndex.value + 1) % _messages.length;
    });
    poll();
  }

  String get currentMessage =>
      status.value == 'pending' ? 'Menunggu antrean pemrosesan…' : _messages[messageIndex.value];

  /// Jalankan loop long-poll sampai status keluar dari antrean atau habis.
  Future<void> poll() async {
    if (isPolling.value || _closed || isFailed.value) return;
    canManualCheck.value = false;
    errorMessage.value = '';
    isPolling.value = true;
    try {
      while (!_closed && _attempts < _maxAttempts) {
        _attempts++;
        final res = await ApiClient.get<dynamic>(
          '/scans/$scanId',
          longPoll: true,
          query: {'wait': AppConfig.scanWaitSeconds},
          cancelToken: _cancelToken(),
        );
        if (_closed) return;

        if (res.success && res.data is Map<String, dynamic>) {
          final data = res.data as Map<String, dynamic>;
          final next = '${data['status'] ?? ''}';
          if (next == 'done') {
            status.value = 'done';
            Get.offNamed(Routes.scanResult, arguments: {'scanId': scanId});
            return;
          }
          if (next == 'failed') {
            status.value = 'failed';
            errorMessage.value = _errorMessage(data);
            isFailed.value = true;
            return;
          }
          if (next.isNotEmpty) status.value = next;
        } else {
          errorMessage.value = res.errorText;
        }
      }
      if (!_closed && !isFailed.value) canManualCheck.value = true;
    } finally {
      if (!_closed) isPolling.value = false;
    }
  }

  CancelToken _cancelToken() {
    final token = CancelToken();
    _token = token;
    return token;
  }

  String _errorMessage(Map<String, dynamic> data) {
    final error = data['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'Prediksi gagal diproses. Coba lagi nanti.';
  }

  /// Ulangi poll setelah plafon [_maxAttempts] tercapai.
  Future<void> manualCheck() {
    _attempts = 0;
    canManualCheck.value = false;
    return poll();
  }

  Future<void> confirmCancel() async {
    final confirmed = await confirmDestructive(
      title: 'Batalkan scan?',
      message:
          'Proses analisis akan dihentikan dan hasil scan tidak akan ditampilkan.',
      confirmLabel: 'Batalkan',
    );
    if (!confirmed) return;
    _closed = true;
    _token?.cancel();
    Get.back();
  }

  void viewDetail() =>
      Get.offNamed(Routes.scanResult, arguments: {'scanId': scanId});

  @override
  void onClose() {
    _closed = true;
    _messageTimer?.cancel();
    _token?.cancel();
    super.onClose();
  }
}

/// Ikon pemindaian berdenyut (SRS §7.1 — playful & fast feedback).
class PulsingScanIcon extends StatefulWidget {
  const PulsingScanIcon({super.key, this.size = 96});

  final double size;

  @override
  State<PulsingScanIcon> createState() => _PulsingScanIconState();
}

class _PulsingScanIconState extends State<PulsingScanIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return SizedBox(
          width: widget.size * 1.9,
          height: widget.size * 1.9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ring(t),
              _ring((t + 0.5) % 1.0),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.center_focus_weak_rounded,
                    size: 44, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ring(double t) {
    final scale = 0.6 + t * 0.6;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: (1 - t) * 0.5),
            width: 2.4,
          ),
        ),
      ),
    );
  }
}
