import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ngingu_apps/core/models/article_model.dart';
import 'package:ngingu_apps/core/models/pond_model.dart';
import 'package:ngingu_apps/core/widgets/app_skeleton.dart';
import 'package:ngingu_apps/core/widgets/google_logo.dart';
import 'package:ngingu_apps/modules/ponds/widgets/trend_chart.dart';
import 'package:ngingu_apps/modules/scan/widgets/photo_guide_sheet.dart';

Widget _wrap(Widget child) => GetMaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('GoogleLogo renders', (tester) async {
    await tester.pumpWidget(_wrap(const GoogleLogo()));
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('Skeletons render', (tester) async {
    await tester.pumpWidget(_wrap(const DashboardSkeleton()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PulseBlock), findsWidgets);

    await tester.pumpWidget(_wrap(const DiseaseListSkeleton(count: 2)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PulseBlock), findsWidgets);
  });

  testWidgets('TrendChart renders sample trend', (tester) async {
    final trend = List.generate(
      7,
      (i) => HealthTrendPoint(date: '2026-09-2$i', scans: i, diseases: const []),
    );
    await tester.pumpWidget(_wrap(TrendChart(trend: trend)));
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Penyakit'), findsOneWidget);
  });

  testWidgets('PhotoGuideSheet renders 3 tips', (tester) async {
    await tester
        .pumpWidget(_wrap(PhotoGuideSheet(onContinue: () {})));
    expect(find.text('Cahaya cukup'), findsOneWidget);
    expect(find.text('Fokus ke gejala'), findsOneWidget);
    expect(find.text('Ikan tetap basah'), findsOneWidget);
  });

  test('ArticleDetail parses backend payload', () {
    final d = ArticleDetail.fromJson({
      'id': 1,
      'title': 'Panduan Karantina',
      'slug': 'karantina',
      'category': 'Budidaya',
      'read_minutes': 4,
      'content_paragraphs': ['Paragraf satu.', 'Paragraf dua.'],
    });
    expect(d.title, 'Panduan Karantina');
    expect(d.body.length, 2);
    expect(d.readMinutes, 4);
  });

  test('ArticleDetail falls back to HTML content', () {
    final d = ArticleDetail.fromJson({
      'id': 2,
      'title': 'X',
      'content_html': '<p>Satu.</p><p>Dua.</p>',
    });
    expect(d.body.length, 2);
  });
}
