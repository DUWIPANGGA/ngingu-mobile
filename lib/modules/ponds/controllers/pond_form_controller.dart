import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/pond_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import 'ponds_controller.dart';

/// Form tambak (FR-08.1) — `POST /api/ponds` (API.md §7.3) untuk tambah,
/// `PUT /api/ponds/{id}` (API.md §7.4) untuk ubah. Argumen route:
/// tidak ada = tambah, `{'id': pondId}` = ubah (prefill dari `GET /api/ponds/{id}`).
class PondFormController extends GetxController {
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final areaController = TextEditingController();
  final capacityController = TextEditingController();
  final fishTypesController = TextEditingController();
  final descriptionController = TextEditingController();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isLocating = false.obs;
  final loadFailed = false.obs;

  final locationLat = RxnDouble();
  final locationLng = RxnDouble();

  /// 'gps' = mengikuti lokasi saat ini, 'manual' = digeser/diketuk user,
  /// 'saved' = bawaan data tersimpan (mode ubah), null = belum ada titik.
  final pickedVia = RxnString();
  final mapController = MapController();

  /// Fallback peta bila izin lokasi ditolak: pusat Kabupaten Indramayu.
  static const indramayuCenter = LatLng(-6.4548, 108.3237);

  bool _mapReady = false;
  LatLng? _pendingCenter;
  double _pendingZoom = 16;
  final fishChips = <String>[].obs;

  final nameError = Rxn<String>();
  final locationLabelError = Rxn<String>();
  final areaError = Rxn<String>();
  final capacityError = Rxn<String>();
  final fishTypesError = Rxn<String>();
  final descriptionError = Rxn<String>();
  final formError = Rxn<String>();

  String? pondId;
  bool get isEdit => pondId != null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) pondId = args['id']?.toString();
    if (isEdit) {
      loadPond();
    } else {
      _syncFishChips();
      initMapLocation();
    }
    nameController.addListener(() => nameError.value = null);
    locationController.addListener(() => locationLabelError.value = null);
    areaController.addListener(() => areaError.value = null);
    capacityController.addListener(() => capacityError.value = null);
    descriptionController.addListener(() => descriptionError.value = null);
    fishTypesController.addListener(() {
      fishTypesError.value = null;
      _syncFishChips();
    });
  }

  /// `GET /api/ponds/{id}` → isi form (data segar, bukan argumen route).
  Future<void> loadPond() async {
    isLoading.value = true;
    loadFailed.value = false;
    formError.value = null;
    final res = await ApiClient.get<Pond>(
      '/ponds/$pondId',
      parse: Pond.fromJson,
    );
    isLoading.value = false;
    final pond = res.data;
    if (!res.success || pond == null) {
      loadFailed.value = true;
      formError.value = res.statusCode == 404
          ? 'Tambak tidak ditemukan.'
          : res.errorText;
      return;
    }
    _prefill(pond);
  }

  void _prefill(Pond pond) {
    nameController.text = pond.name == '-' ? '' : pond.name;
    locationController.text = pond.locationLabel ?? '';
    areaController.text = pond.areaM2 == null
        ? ''
        : pond.areaM2! == pond.areaM2!.truncateToDouble()
            ? pond.areaM2!.toInt().toString()
            : '${pond.areaM2}';
    capacityController.text =
        pond.capacity == null ? '' : '${pond.capacity}';
    fishTypesController.text = pond.fishTypes.join(', ');
    descriptionController.text = pond.description ?? '';
    locationLat.value = pond.locationLat;
    locationLng.value = pond.locationLng;
    if (pond.locationLat != null && pond.locationLng != null) {
      pickedVia.value = 'saved';
      _requestMove(LatLng(pond.locationLat!, pond.locationLng!), 16);
    }
    _syncFishChips();
  }

  List<String> _parseFishTypes() => fishTypesController.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  void _syncFishChips() => fishChips.assignAll(_parseFishTypes());

  /// Baca GPS senyap (tanpa toast gagal) — dipakai inisialisasi peta.
  Future<Position?> _tryCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
  }

  /// Saat form terbuka: default marker = lokasi sekarang; izin ditolak →
  /// peta fokus ke Indramayu tanpa marker (user pilih manual).
  Future<void> initMapLocation() async {
    final pos = await _tryCurrentPosition();
    if (pos != null) {
      final p = LatLng(pos.latitude, pos.longitude);
      setPoint(p, via: 'gps');
      _requestMove(p, 16);
    } else {
      _requestMove(indramayuCenter, 11);
    }
  }

  /// Lokasi opsional (API.md §7.3) — tombol "Gunakan lokasi saya": kembali
  /// ke GPS + recenter peta.
  Future<void> captureLocation() async {
    if (isLocating.value) return;
    isLocating.value = true;
    final pos = await _tryCurrentPosition();
    isLocating.value = false;
    if (pos == null) {
      AppTheme.error('Lokasi tidak tersedia',
          'Izin lokasi ditolak atau GPS mati. Geser marker manual saja.');
      return;
    }
    final p = LatLng(pos.latitude, pos.longitude);
    setPoint(p, via: 'gps');
    _requestMove(p, 16);
    AppTheme.success('Lokasi ditemukan',
        '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
  }

  void setPoint(LatLng p, {required String via}) {
    locationLat.value = p.latitude;
    locationLng.value = p.longitude;
    pickedVia.value = via;
  }

  void onMapTap(TapPosition _, LatLng p) => setPoint(p, via: 'manual');

  /// Geser marker dengan jari: delta layar (px) → koordinat lewat kamera.
  void onMarkerDrag(DragUpdateDetails d) {
    final lat = locationLat.value;
    final lng = locationLng.value;
    if (lat == null || lng == null) return;
    final cam = mapController.camera;
    final screen =
        cam.screenOffsetToLatLng(cam.latLngToScreenOffset(LatLng(lat, lng)) + d.delta);
    setPoint(screen, via: 'manual');
  }

  void _requestMove(LatLng center, double zoom) {
    _pendingCenter = center;
    _pendingZoom = zoom;
    if (_mapReady) _flushPendingMove();
  }

  void _flushPendingMove() {
    final c = _pendingCenter;
    if (c == null) return;
    mapController.move(c, _pendingZoom);
    _pendingCenter = null;
  }

  /// Dipanggil FlutterMap setelah peta siap menerima perintah move.
  void onMapReady() {
    _mapReady = true;
    _flushPendingMove();
  }

  void clearLocation() {
    locationLat.value = null;
    locationLng.value = null;
    pickedVia.value = null;
  }

  bool _validate() {
    var invalid = false;
    formError.value = null;
    nameError.value = null;
    areaError.value = null;
    capacityError.value = null;
    descriptionError.value = null;

    if (nameController.text.trim().isEmpty) {
      nameError.value = 'Nama tambak wajib diisi.';
      invalid = true;
    }
    final areaText = areaController.text.trim();
    if (areaText.isNotEmpty && _parseArea(areaText) == null) {
      areaError.value = 'Luas berupa angka, contoh: 120.';
      invalid = true;
    }
    final capacityText = capacityController.text.trim();
    if (capacityText.isNotEmpty && _parseCount(capacityText) == null) {
      capacityError.value = 'Kapasitas berupa angka, contoh: 5000.';
      invalid = true;
    }
    return !invalid;
  }

  double? _parseArea(String raw) =>
      double.tryParse(raw.replaceAll(',', '.'));

  int? _parseCount(String raw) {
    if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(raw)) {
      return int.parse(raw.replaceAll('.', ''));
    }
    return int.tryParse(raw.replaceAll(',', '.'));
  }

  /// Body POST/PUT — nama field persis API.md §7.3.
  Map<String, dynamic> _body() {
    final areaText = areaController.text.trim();
    final capacityText = capacityController.text.trim();
    final locationLabel = locationController.text.trim();
    return {
      'name': nameController.text.trim(),
      if (locationLat.value != null) 'location_lat': locationLat.value,
      if (locationLng.value != null) 'location_lng': locationLng.value,
      if (locationLabel.isNotEmpty) 'location_label': locationLabel,
      if (areaText.isNotEmpty) 'area_m2': _parseArea(areaText),
      if (capacityText.isNotEmpty) 'capacity': _parseCount(capacityText),
      'fish_types': _parseFishTypes(),
      'description': descriptionController.text.trim(),
    };
  }

  Future<void> save() async {
    if (isSaving.value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_validate()) return;

    isSaving.value = true;
    final body = _body();
    final res = isEdit
        ? await ApiClient.put<dynamic>('/ponds/$pondId', data: body)
        : await ApiClient.post<dynamic>('/ponds', data: body);
    isSaving.value = false;

    if (!res.success) {
      nameError.value = res.fieldError('name');
      locationLabelError.value = res.fieldError('location_label');
      areaError.value = res.fieldError('area_m2');
      capacityError.value = res.fieldError('capacity');
      fishTypesError.value = res.fieldError('fish_types');
      descriptionError.value = res.fieldError('description');
      if (!res.hasFieldErrors) {
        formError.value = res.statusCode == 401
            ? 'Sesi berakhir. Silakan masuk kembali.'
            : res.statusCode == 429
                ? 'Terlalu banyak permintaan. Coba lagi nanti.'
                : res.errorText;
      }
      return;
    }

    if (Get.isRegistered<PondsController>()) {
      Get.find<PondsController>().reload();
    }
    Get.back();
    AppTheme.success(
      'Berhasil',
      isEdit ? 'Tambak berhasil diperbarui.' : 'Tambak berhasil ditambahkan.',
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    locationController.dispose();
    areaController.dispose();
    capacityController.dispose();
    fishTypesController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
