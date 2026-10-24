import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:ngingu_apps/core/models/alert_model.dart';
import 'package:ngingu_apps/modules/heatmap/controllers/heatmap_controller.dart';
import 'package:ngingu_apps/modules/heatmap/views/heatmap_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HeatmapController - Indramayu Focus', () {
    test('default center and zoom is focused on Kota Indramayu', () {
      expect(HeatmapController.indramayuCenter.latitude, closeTo(-6.3275, 0.01));
      expect(HeatmapController.indramayuCenter.longitude, closeTo(108.3250, 0.01));
      expect(HeatmapController.indramayuZoom, 11.5);
    });

    test('focusIndramayu does not throw even before map is attached', () {
      final controller = HeatmapController();
      expect(() => controller.focusIndramayu(), returnsNormally);
      expect(HeatmapController.indramayuCenter, const LatLng(-6.3275, 108.3250));
      controller.onClose();
    });
  });

  group('ScanPin - GIS per-scan (API.md §7.13)', () {
    test('parses /api/map/pins payload', () {
      final pin = ScanPin.fromJson({
        'id': 421,
        'lat': -6.3275,
        'lng': 108.3250,
        'kecamatan': 'Indramayu',
        'disease_id': 5,
        'disease_name': 'White Spot (Ich)',
        'severity': 'berat',
        'confidence_score': 88.5,
        'fish_type': 'Lele',
        'scanned_at': '2026-10-20T09:12:00+07:00',
      });

      // id int lama tetap terbaca (toString) — payload produksi memakai UUID.
      expect(pin.id, '421');
      expect(pin.lat, closeTo(-6.3275, 0.0001));
      expect(pin.lng, closeTo(108.3250, 0.0001));
      expect(pin.kecamatan, 'Indramayu');
      expect(pin.diseaseId, 5);
      expect(pin.severity, 'berat');
      expect(pin.confidenceScore, 88.5);
      expect(pin.fishType, 'Lele');
      expect(pin.hasValidCoords, isTrue);
    });

    test('parses real production pin (UUID id, null pond fields)', () {
      // Payload persis dari GET /api/map/pins produksi 2026-10-24 13:00.
      // Regresi: id UUID string sempat membuat fromJson melempar karena
      // model mengasumsikan id int, sehingga peta menampilkan banner
      // "Titik scan tidak dapat dimuat".
      final pin = ScanPin.fromJson({
        'id': '01a16c7e-b945-7310-9b00-24596de9a5a4',
        'lat': -6.334997,
        'lng': 108.331618,
        'pond_name': null,
        'location_label': null,
        'disease_id': 2,
        'disease_name': 'Infeksi Bakteri Aeromonas (Aeromoniasis)',
        'severity': 'berat',
        'confidence_score': 70.2,
        'fish_type': 'Nila',
        'scanned_at': '2026-10-24 13:00:06',
      });

      expect(pin.id, '01a16c7e-b945-7310-9b00-24596de9a5a4');
      expect(pin.lat, closeTo(-6.334997, 0.000001));
      expect(pin.lng, closeTo(108.331618, 0.000001));
      expect(pin.diseaseId, 2);
      expect(pin.diseaseName, 'Infeksi Bakteri Aeromonas (Aeromoniasis)');
      expect(pin.severity, 'berat');
      expect(pin.confidenceScore, 70.2);
      expect(pin.fishType, 'Nila');
      expect(pin.hasValidCoords, isTrue);
    });

    test('tolerates missing optional fields and flags bad coordinates', () {
      final pin = ScanPin.fromJson({'id': 'abc', 'lat': 999, 'lng': 0});
      expect(pin.kecamatan, isNull);
      expect(pin.diseaseId, isNull);
      expect(pin.confidenceScore, 0);
      expect(pin.hasValidCoords, isFalse);
    });

    test('layer toggles and selection are mutually exclusive', () {
      final controller = HeatmapController();
      const point = HeatmapPoint(
          kecamatan: 'Indramayu', lat: -6.9, lng: 107.6, cases: 3);
      const pin = ScanPin(id: '7', lat: -6.3, lng: 108.3);

      expect(controller.showClusters.value, isTrue);
      expect(controller.showPins.value, isTrue);

      controller.togglePins();
      expect(controller.showPins.value, isFalse);
      controller.toggleClusters();
      expect(controller.showClusters.value, isFalse);

      controller.selectPoint(point);
      controller.selectPin(pin);
      expect(controller.selectedPoint.value, isNull);
      expect(controller.selectedPin.value?.id, '7');

      controller.clearSelection();
      expect(controller.selectedPin.value, isNull);
      controller.onClose();
    });
  });

  group('HeatmapView - Overflow Regression Test', () {
    testWidgets('renders cleanly on narrow/compact screen on error state', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Get.put(HeatmapController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: HeatmapView(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow exceptions occurred in error state
      expect(tester.takeException(), isNull);

      Get.delete<HeatmapController>();
    });

    testWidgets('renders map and Indramayu focus button with points without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = Get.put(HeatmapController());
      controller.hasError.value = false;
      controller.isLoading.value = false;
      controller.points.assignAll([
        const HeatmapPoint(
          kecamatan: 'Indramayu',
          lat: -6.3275,
          lng: 108.3250,
          cases: 15,
          topDisease: 'White Spot Disease',
        ),
      ]);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: HeatmapView(),
        ),
      );
      await tester.pump();

      // Check Indramayu focus button exists
      expect(find.text('Fokus Indramayu'), findsOneWidget);

      // Verify no RenderFlex overflow exceptions occurred
      expect(tester.takeException(), isNull);

      Get.delete<HeatmapController>();
    });
  });
}
