import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/pond_model.dart';
import '../../../core/models/scan_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_utils.dart';
import '../../../routes/app_routes.dart';

/// Scan tab root (FR-02): pilih 1-5 foto, kolam & jenis ikan opsional,
/// lalu `POST /api/scans` (API.md 4.1) ke halaman proses.
class ScanController extends GetxController {
  static const int maxImages = AppConfig.maxScanImages;

  final RxList<XFile> picked = <XFile>[].obs;
  final RxBool isSubmitting = false.obs;
  final RxList<Pond> ponds = <Pond>[].obs;
  final RxString selectedPondId = ''.obs;

  final TextEditingController fishTypeController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  bool _pondsRequested = false;

  @override
  void onInit() {
    super.onInit();
    if (AuthService.isAuthed) ensurePonds();
  }

  /// `GET /api/ponds?per_page=100` - field opsional, kegagalan diabaikan.
  Future<void> ensurePonds() async {
    if (_pondsRequested) return;
    _pondsRequested = true;
    final res = await ApiClient.get<List<Pond>>(
      '/ponds',
      query: {'per_page': 100},
      parse: (json) => (json as List).map(Pond.fromJson).toList(),
    );
    if (res.success && res.data != null) ponds.assignAll(res.data!);
  }

  // -- pemilihan foto --------------------------------------------------------

  void openImageSourceSheet() {
    if (picked.length >= maxImages || isSubmitting.value) return;
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Tambah Foto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: AppColors.softSky, shape: BoxShape.circle),
                child: const Icon(Icons.photo_camera_outlined,
                    color: AppColors.primary, size: 20),
              ),
              title: const Text('Ambil Foto',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              subtitle: const Text('Gunakan kamera',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              onTap: () {
                Get.back();
                pickFromCamera();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: AppColors.softSky, shape: BoxShape.circle),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary, size: 20),
              ),
              title: const Text('Pilih dari Galeri',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              subtitle: const Text('Maksimal $maxImages foto per scan',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              onTap: () {
                Get.back();
                pickFromGallery();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      backgroundColor: AppColors.white,
    );
  }

  Future<void> pickFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      AppTheme.error(
        'Izin kamera',
        status.isPermanentlyDenied
            ? 'Izin kamera ditolak. Aktifkan di pengaturan perangkat.'
            : 'Izin kamera diperlukan untuk memfoto ikan.',
      );
      return;
    }
    try {
      final file =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (file != null) await _add(file);
    } catch (_) {
      AppTheme.error('Gagal', 'Kamera tidak dapat diakses. Coba lagi.');
    }
  }

  Future<void> pickFromGallery() async {
    if (picked.length >= maxImages) return;
    try {
      final files = await _picker.pickMultiImage(imageQuality: 85);
      for (final file in files) {
        if (picked.length >= maxImages) {
          AppTheme.info('Foto penuh', 'Maksimal $maxImages foto per scan.');
          break;
        }
        await _add(file);
      }
    } catch (_) {
      AppTheme.error('Gagal', 'Galeri tidak dapat diakses. Coba lagi.');
    }
  }

  Future<void> _add(XFile file) async {
    if (picked.length >= maxImages) return;
    try {
      final size = await File(file.path).length();
      if (size > AppConfig.maxUploadBytes) {
        AppTheme.error(
            'Foto terlalu besar', 'Maksimal 10 MB per foto. Pilih foto lain.');
        return;
      }
    } catch (_) {
      // Ukuran tidak terbaca - biarkan server yang memvalidasi (API.md 2.7).
    }
    picked.add(file);
  }

  void removeImage(int index) {
    if (index < 0 || index >= picked.length) return;
    picked.removeAt(index);
  }

  void goToHistory() => Get.toNamed(Routes.scanHistory);

  // -- submit ----------------------------------------------------------------

  Future<void> submit() async {
    if (isSubmitting.value) return;
    if (picked.isEmpty) {
      AppTheme.error(
          'Foto belum ada', 'Pilih minimal 1 foto ikan untuk di-scan.');
      return;
    }
    if (!AuthService.isAuthed) {
      AppTheme.error('Belum masuk', 'Masuk terlebih dahulu untuk memulai scan.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    isSubmitting.value = true;
    try {
      final compressed =
          await compressImages([for (final x in picked) File(x.path)]);
      final parts = <dio.MultipartFile>[];
      for (final f in compressed) {
        parts.add(await dio.MultipartFile.fromFile(
          f.path,
          filename: f.path.split(RegExp(r'[\\/]')).last,
        ));
      }

      final fields = <String, dynamic>{'images[]': parts};
      final pondId = selectedPondId.value.trim();
      if (pondId.isNotEmpty) fields['pond_id'] = pondId;
      final fishType = fishTypeController.text.trim();
      if (fishType.isNotEmpty) fields['fish_type'] = fishType;
      final position = await _tryGetPosition();
      if (position != null) {
        fields['location_lat'] = position.latitude;
        fields['location_lng'] = position.longitude;
      }

      final res = await ApiClient.postMultipart<CreateScanResponse>(
        '/scans',
        formData: dio.FormData.fromMap(fields),
        parse: CreateScanResponse.fromJson,
      );

      if (res.success && res.data != null) {
        AppTheme.success(
          'Berhasil',
          res.message.isNotEmpty ? res.message : 'Scan diterima, sedang diproses',
        );
        _resetForm();
        Get.toNamed(Routes.scanProcessing,
            arguments: {'scanId': res.data!.scanId});
      } else if (res.statusCode == 429) {
        AppTheme.error('Terlalu banyak permintaan', res.errorText);
      } else {
        AppTheme.error('Gagal', res.errorText);
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Lokasi perangkat untuk peta sebaran (GIS): koordinat titik scan dikirim
  /// ke server agar tampil sebagai sebaran penyakit di heatmap. Mengikuti
  /// pola pond_form_controller — bila layanan lokasi mati atau izin ditolak,
  /// kembalikan null dan scan tetap berjalan tanpa koordinat.
  Future<Position?> _tryGetPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      // Koordinat opsional — gagal diam-diam.
      return null;
    }
  }

  void _resetForm() {
    picked.clear();
    selectedPondId.value = '';
    fishTypeController.clear();
  }

  @override
  void onClose() {
    fishTypeController.dispose();
    super.onClose();
  }
}
