import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madmaps/screens/extraction_lab_screen.dart';
import 'package:madmaps/screens/lab_api.dart';
import 'package:madmaps/screens/annotation_editor.dart';

class FakeLabApi implements LabApi {
  FakeLabApi({this.measured = true});
  final bool measured;
  final requests = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> capabilities() async => {
    'enabled': true,
    'worker_ready': true,
    'live_ready': false,
    'training_ready': false,
  };

  @override
  Future<String> start(Map<String, dynamic> request) async {
    requests.add(request);
    return '${requests.length - 1}';
  }

  @override
  Future<Map<String, dynamic>> getJob(String id) async {
    final request = requests[int.parse(id)];
    if (request['action'] == 'review')
      return {
        'status': 'completed',
        'payload': {'example_id': 'review-1', 'split': 'train'},
      };
    if (request['action'] == 'benchmark') {
      return {
        'status': 'completed',
        'payload': {
          'benchmark': {
            'manifest': {'dataset': 'synthetic-test'},
            'summary': {
              'runs': 3,
              'rooms': {'f1': 1},
              'doors': {'f1': 1},
              'failure_rate': 0,
              'inference_retries': 0,
              'latency_total_p95_s': .01,
            },
            'results': [],
          },
        },
      };
    }
    final extraction =
        jsonDecode(File('test/fixtures/lab_extraction.json').readAsStringSync())
            as Map<String, dynamic>;
    return {
      'status': 'completed',
      'payload': {
        'synthetic': measured,
        'extraction': extraction,
        'graph': null,
        'plan_base64': base64Encode(
          File('test/fixtures/lab_plan.png').readAsBytesSync(),
        ),
        'result': {
          'status': 'needsReview',
          'validation': {
            'candidate_valid': false,
            'issues': ['Missing scale'],
          },
          'timings_s': {'total': .04},
        },
        'mean_confidence': .8,
        'metrics': measured
            ? {
                'rooms': {'f1': 1, 'matched_text_accuracy': 1},
                'doors': {'recall': 1},
                'walls': {'matched_similarity_mean': 1},
              }
            : null,
      },
    };
  }
}

void main() {
  testWidgets(
    'demo runs and shows measured scores separately from confidence',
    (tester) async {
      final api = FakeLabApi();
      await tester.pumpWidget(MaterialApp(home: ExtractionLabScreen(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Accuracy: not measured'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('run-extraction')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('run-extraction')));
      await tester.pumpAndSettle();
      expect(api.requests.single['mode'], 'demo');
      expect(
        find.text('Measured against synthetic reference annotations'),
        findsOneWidget,
      );
      expect(find.text('Model confidence'), findsOneWidget);
      expect(find.text('80.0%'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unlabeled extraction never invents accuracy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ExtractionLabScreen(api: FakeLabApi(measured: false))),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('run-extraction')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('run-extraction')));
    await tester.pumpAndSettle();
    expect(find.text('Accuracy: not measured'), findsOneWidget);
    expect(find.text('100.0%'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('benchmark tab runs the harness and renders its summary', (
    tester,
  ) async {
    final api = FakeLabApi();
    await tester.pumpWidget(MaterialApp(home: ExtractionLabScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Benchmark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run synthetic benchmark'));
    await tester.pumpAndSettle();
    expect(api.requests.single['action'], 'benchmark');
    expect(find.textContaining('synthetic-test'), findsOneWidget);
    expect(find.text('Failure rate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'fine tuning is disabled until configured and review needs an extraction',
    (tester) async {
      final api = FakeLabApi();
      await tester.pumpWidget(MaterialApp(home: ExtractionLabScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fine-tune'));
      await tester.pumpAndSettle();
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save reviewed example'),
      );
      final train = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Launch Databricks fine-tune'),
      );
      expect(save.onPressed, isNull);
      expect(train.onPressed, isNull);
      expect(api.requests, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mobile layout stays usable without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: ExtractionLabScreen(api: FakeLabApi())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'drawn polygons are sent as reviewed data without altering model metrics',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FakeLabApi();
      await tester.pumpWidget(MaterialApp(home: ExtractionLabScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('run-extraction')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fine-tune'));
      await tester.pumpAndSettle();
      final editor = tester.widget<AnnotationEditor>(
        find.byType(AnnotationEditor),
      );
      final originalCount = (editor.document.data['walls'] as List).length;
      await tester.ensureVisible(find.byKey(const Key('annotation-tool-wall')));
      await tester.tap(find.byKey(const Key('annotation-tool-wall')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('annotation-canvas')));
      await tester.pumpAndSettle();
      final box = tester.renderObject<RenderBox>(
        find.byKey(const Key('annotation-canvas')),
      );
      for (final point in [
        const Offset(20, 20),
        const Offset(70, 20),
        const Offset(70, 60),
      ]) {
        await tester.tapAt(
          box.localToGlobal(
            Offset(
              point.dx * box.size.width / 400,
              point.dy * box.size.height / 240,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.byKey(const Key('finish-polygon')));
      await tester.tap(find.byKey(const Key('finish-polygon')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save reviewed example'));
      await tester.tap(find.text('Save reviewed example'));
      await tester.pumpAndSettle();
      expect(api.requests.last['action'], 'review');
      expect(
        (api.requests.last['correction']['walls'] as List).length,
        originalCount + 1,
      );
      expect(api.requests.last['source_job_id'], '0');
      await tester.tap(find.text('Extract'));
      await tester.pumpAndSettle();
      expect(
        find.text('Measured against synthetic reference annotations'),
        findsOneWidget,
      );
      expect(find.text('100.0%'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
