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

  group('HeatmapView - Overflow Regression Test', () {
    testWidgets('renders cleanly on narrow/compact screen on error state', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = Get.put(HeatmapController());

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
          province: 'Jawa Barat (Indramayu)',
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
