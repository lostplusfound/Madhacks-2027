import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'lab_api.dart';
import 'annotation_document.dart';
import 'annotation_editor.dart';

const _ink = Color(0xff25233b);
const _violet = Color(0xff6655d6);
const _green = Color(0xff217b55);
const _border = Color(0xffe5e3ee);

class ExtractionLabScreen extends StatefulWidget {
  const ExtractionLabScreen({super.key, this.api, this.onConnectionCheck});
  final LabApi? api;
  final VoidCallback? onConnectionCheck;

  @override
  State<ExtractionLabScreen> createState() => _ExtractionLabScreenState();
}

class _ExtractionLabScreenState extends State<ExtractionLabScreen> {
  late final LabApi _api = widget.api ?? ServerpodLabApi();
  Map<String, dynamic> _capabilities = {};
  Map<String, dynamic>? _payload, _benchmark, _truth, _recorded;
  Uint8List? _upload, _plan;
  String? _fileName, _sourceJobId, _error, _notice;
  String _mode = 'demo', _split = 'train';
  int _tab = 0;
  bool _busy = false,
      _reviewed = false,
      _showWalls = true,
      _showGraph = true,
      _showRooms = true;
  AnnotationDocument? _annotations;
  int _annotationRevision = 0;
  bool _jsonDirty = false;
  final _correction = TextEditingController();
  final _group = TextEditingController(text: 'demo-building');
  final _calibration = TextEditingController();
  final _page = TextEditingController(text: '0');
  final _manifest = TextEditingController();
  final _epochs = TextEditingController(text: '1');
  final _rate = TextEditingController(text: '0.0001');
  final _rank = TextEditingController(text: '16');

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    for (final controller in [
      _correction,
      _group,
      _calibration,
      _page,
      _manifest,
      _epochs,
      _rate,
      _rank,
    ]) {
      controller.dispose();
    }
    _annotations?.removeListener(_annotationsChanged);
    _annotations?.dispose();
    super.dispose();
  }

  void _clearAnnotations() {
    _annotations?.removeListener(_annotationsChanged);
    _annotations?.dispose();
    _annotations = null;
    _annotationRevision = 0;
    _jsonDirty = false;
    _correction.clear();
  }

  void _annotationsChanged() {
    final annotations = _annotations;
    if (annotations == null || annotations.revision == _annotationRevision)
      return;
    setState(() {
      _annotationRevision = annotations.revision;
      _correction.text = annotations.json;
      _jsonDirty = false;
      _reviewed = false;
    });
  }

  void _applyAnnotationJson() {
    try {
      final value = jsonDecode(_correction.text) as Map<String, dynamic>;
      _annotations!.replace(value);
      setState(() {
        _jsonDirty = false;
        _reviewed = false;
        _correction.text = _annotations!.json;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() => _error = 'Cannot apply JSON: ${error.message}');
    } on TypeError {
      setState(
        () =>
            _error = 'Use an extraction JSON object with the expected fields.',
      );
    }
  }

  Future<void> _refresh() async {
    try {
      final capabilities = await _api.capabilities();
      if (mounted) setState(() => _capabilities = capabilities);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Cannot reach Serverpod. Start the runner, then reconnect.',
        );
    }
  }

  Future<Map<String, dynamic>> _job(
    Map<String, dynamic> request, {
    bool extraction = false,
  }) async {
    final id = await _api.start(request);
    if (extraction) _sourceJobId = id;
    final deadline = DateTime.now().add(const Duration(minutes: 21));
    while (mounted && DateTime.now().isBefore(deadline)) {
      final response = await _api.getJob(id);
      if (response['status'] == 'failed')
        throw StateError(response['error'] as String? ?? 'Job failed');
      if (response['status'] == 'completed')
        return response['payload'] as Map<String, dynamic>;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    throw StateError('Stopped waiting. The server job may still be running.');
  }

  Future<void> _perform(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choosePlan() async {
    await _perform(() async {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Floor plan',
            extensions: ['png', 'jpg', 'jpeg', 'pdf'],
            uniformTypeIdentifiers: [
              'public.png',
              'public.jpeg',
              'com.adobe.pdf',
            ],
          ),
        ],
      );
      if (file == null) return;
      if (await file.length() > 8 * 1024 * 1024)
        throw ArgumentError('Plan must be 8 MB or smaller.');
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _upload = bytes;
        _fileName = file.name;
        _plan = null;
        _payload = null;
        _truth = null;
        _recorded = null;
        _sourceJobId = null;
        _reviewed = false;
        _clearAnnotations();
        _calibration.clear();
        _group.clear();
        _mode = _capabilities['live_ready'] == true ? 'databricks' : 'recorded';
      });
    });
  }

  Future<Map<String, dynamic>?> _readJson() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'JSON',
          extensions: ['json'],
          uniformTypeIdentifiers: ['public.json'],
        ),
      ],
    );
    if (file == null) return null;
    if (await file.length() > 12 * 1024 * 1024)
      throw ArgumentError('JSON must be 12 MB or smaller.');
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<void> _import(String type) => _perform(() async {
    final data = await _readJson();
    if (data == null || !mounted) return;
    setState(() {
      if (type == 'truth') {
        _truth = data;
        _payload?['metrics'] = null;
      }
      if (type == 'recorded') {
        _recorded = data;
      }
      if (type == 'benchmark') {
        if (data['summary'] is! Map || data['results'] is! List)
          throw const FormatException('Not a benchmark report');
        _benchmark = data;
      }
      _notice = type == 'truth'
          ? 'Reference annotations loaded. Run extraction to measure accuracy.'
          : '$type loaded.';
    });
  });

  Future<void> _extract({
    bool demo = false,
    bool liveSample = false,
  }) => _perform(() async {
    final mode = liveSample ? 'databricks' : (demo ? 'demo' : _mode);
    if (mode != 'demo' && !liveSample && _upload == null)
      throw StateError('Choose a plan first.');
    if (mode == 'recorded' && _recorded == null)
      throw StateError('Import recorded extraction JSON for this plan.');
    final request = <String, dynamic>{
      'action': 'extract',
      'mode': mode,
      'sample_plan': liveSample,
    };
    if (mode != 'demo' && !liveSample) {
      request.addAll({
        'file_base64': base64Encode(_upload!),
        'file_name': _fileName,
        'page': int.parse(_page.text),
        'ground_truth': _truth,
        'recorded_extraction': _recorded,
        'calibration': _calibration.text.trim().isEmpty
            ? null
            : jsonDecode(_calibration.text),
      });
    }
    setState(() {
      _payload = null;
      _plan = null;
      _reviewed = false;
      _sourceJobId = null;
      _clearAnnotations();
    });
    final payload = await _job(request, extraction: true);
    final result = payload['result'] as Map<String, dynamic>;
    if (result['status'] == 'failed') {
      final failure = result['error'] as Map<String, dynamic>;
      throw StateError(
        'Extraction failed at ${failure['stage']} (${failure['type']}). Check the plan and extraction schema.',
      );
    }
    if (!mounted) return;
    setState(() {
      _payload = payload;
      _mode = mode;
      _plan = base64Decode(payload['plan_base64'] as String);
      _annotations = AnnotationDocument(
        payload['extraction'] as Map<String, dynamic>,
      )..addListener(_annotationsChanged);
      _annotationRevision = _annotations!.revision;
      _correction.text = _annotations!.json;
      _jsonDirty = false;
      if (mode == 'demo' || liveSample) _group.text = 'demo-building';
    });
  });

  Future<void> _runBenchmark({bool live = false}) => _perform(() async {
    final payload = await _job({
      'action': 'benchmark',
      'mode': live ? 'databricks' : 'demo',
    });
    if (mounted)
      setState(() {
        _benchmark = payload['benchmark'] as Map<String, dynamic>;
        _benchmark!['run_source'] = live
            ? 'Live Databricks VLM'
            : 'Recorded output';
      });
  });

  Future<void> _saveReview() => _perform(() async {
    if (_jsonDirty)
      throw StateError('Apply or discard the JSON changes before saving.');
    final correction = _annotations!.data;
    final result = await _job({
      'action': 'review',
      'source_job_id': _sourceJobId,
      'correction': correction,
      'split': _split,
      'group': _group.text.trim(),
    });
    if (mounted)
      setState(
        () => _notice =
            'Saved reviewed example ${result['example_id']} to ${result['split']}.',
      );
  });

  Future<void> _export() => _perform(() async {
    final payload = await _job({'action': 'export'});
    final name = payload['file_name'] as String;
    String path = name;
    if (!kIsWeb) {
      final location = await getSaveLocation(suggestedName: name);
      if (location == null) return;
      path = location.path;
    }
    await XFile.fromData(
      base64Decode(payload['zip_base64'] as String),
      name: name,
      mimeType: 'application/zip',
    ).saveTo(path);
    if (mounted)
      setState(
        () => _notice = 'Exported ${payload['examples']} reviewed examples.',
      );
  });

  Future<void> _train() => _perform(() async {
    final payload = await _job({
      'action': 'train',
      'manifest_path': _manifest.text.trim(),
      'epochs': int.parse(_epochs.text),
      'learning_rate': double.parse(_rate.text),
      'rank': int.parse(_rank.text),
    });
    if (mounted)
      setState(
        () => _notice =
            'Submitted Databricks training run ${payload['run_id']}. Inspect it in Databricks; the serving model is unchanged.',
      );
  });

  @override
  Widget build(BuildContext context) {
    final ready = _capabilities['worker_ready'] == true;
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _violet),
        scaffoldBackgroundColor: const Color(0xfff7f7fb),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.explore_outlined, color: _violet),
              SizedBox(width: 12),
              Text('MadMaps', style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(width: 14),
              Flexible(
                child: Text(
                  '/ Extraction lab',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Reconnect',
              onPressed: _busy ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
            if (widget.onConnectionCheck != null)
              IconButton(
                tooltip: 'Connection check',
                onPressed: widget.onConnectionCheck,
                icon: const Icon(Icons.settings_outlined),
              ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_busy) const LinearProgressIndicator(minHeight: 3),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(wide ? 32 : 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'PLAN INTELLIGENCE / DEVELOPMENT',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.5,
                                color: _violet,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              [
                                'Turn a plan into a navigable map.',
                                'Measure before you choose a model.',
                                'Build a better model with reviewed data.',
                              ][_tab],
                              style: const TextStyle(
                                fontSize: 30,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              [
                                'Inspect geometry, calibrate scale, and compare against reference annotations.',
                                'Compare quality, reliability, and speed. Synthetic runs verify the harness.',
                                'Correct extraction JSON, keep buildings in one split, then fine-tune on GPU compute.',
                              ][_tab],
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 24),
                            if (!ready)
                              _banner(
                                _capabilities.isEmpty
                                    ? 'Connecting to Serverpod…'
                                    : 'Python worker is unavailable. See the extraction lab setup instructions.',
                                Icons.cable,
                                Colors.orange,
                              ),
                            if (_error != null)
                              _banner(_error!, Icons.error_outline, Colors.red),
                            if (_notice != null)
                              _banner(
                                _notice!,
                                Icons.check_circle_outline,
                                _green,
                              ),
                            if (_tab == 0) ..._extractionContent(ready, wide),
                            if (_tab == 1) ..._benchmarkContent(ready),
                            if (_tab == 2) ..._trainingContent(ready),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!wide)
                  NavigationBar(
                    selectedIndex: _tab,
                    onDestinationSelected: (index) =>
                        setState(() => _tab = index),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.layers_outlined),
                        label: 'Extract',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.insights_outlined),
                        label: 'Benchmark',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.tune),
                        label: 'Fine-tune',
                      ),
                    ],
                  ),
              ],
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  NavigationRail(
                    selectedIndex: _tab,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: (index) =>
                        setState(() => _tab = index),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.layers_outlined),
                        label: Text('Extract'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.insights_outlined),
                        label: Text('Benchmark'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.tune),
                        label: Text('Fine-tune'),
                      ),
                    ],
                  ),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _extractionContent(bool ready, bool wide) {
    final input = _panel(
      '01 / INPUT',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Start with a floor plan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _choosePlan,
            icon: const Icon(Icons.upload_file),
            label: Text(_fileName ?? 'Choose PNG, JPEG or PDF · up to 8 MB'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _mode,
            key: ValueKey(_mode),
            decoration: const InputDecoration(labelText: 'Extraction source'),
            items: [
              const DropdownMenuItem(
                value: 'demo',
                child: Text('Synthetic demo'),
              ),
              const DropdownMenuItem(
                value: 'recorded',
                child: Text('Recorded output for my plan'),
              ),
              DropdownMenuItem(
                value: 'databricks',
                enabled: _capabilities['live_ready'] == true,
                child: const Text('Databricks VLM'),
              ),
            ],
            onChanged: _busy ? null : (value) => setState(() => _mode = value!),
          ),
          const SizedBox(height: 12),
          const Text(
            'The demo uses a fixed plan and recorded output. Uploaded plans need their own recorded output or a configured VLM.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (_mode != 'demo') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _page,
              decoration: const InputDecoration(
                labelText: 'PDF page · zero-based',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _calibration,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Optional scale calibration JSON',
                hintText: '{"points":[[20,120],[220,120]],"distance_m":10}',
              ),
            ),
            if (_mode == 'recorded')
              OutlinedButton(
                onPressed: _busy ? null : () => _import('recorded'),
                child: Text(
                  _recorded == null
                      ? 'Import recorded extraction JSON'
                      : 'Recorded output loaded ✓',
                ),
              ),
            OutlinedButton(
              onPressed: _busy ? null : () => _import('truth'),
              child: Text(
                _truth == null
                    ? 'Import reference annotations (optional)'
                    : 'Reference annotations loaded ✓',
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('run-extraction'),
            onPressed: _busy || !ready ? null : () => _extract(),
            icon: const Icon(Icons.play_arrow),
            label: Text(_busy ? 'Working…' : 'Run extraction'),
          ),
          TextButton(
            onPressed: _busy || !ready ? null : () => _extract(demo: true),
            child: const Text('Try the synthetic demo'),
          ),
          OutlinedButton.icon(
            onPressed: _busy || !ready || _capabilities['live_ready'] != true
                ? null
                : () => _extract(liveSample: true),
            icon: const Icon(Icons.cloud_outlined),
            label: const Text('Test live VLM on sample plan'),
          ),
          if (_capabilities['endpoint'] != null)
            Text(
              'Endpoint: ${_capabilities['endpoint']}',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
        ],
      ),
    );
    final preview = _panel(
      '02 / MAP PREVIEW',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Rooms'),
                selected: _showRooms,
                onSelected: (v) => setState(() => _showRooms = v),
              ),
              FilterChip(
                label: const Text('Walls'),
                selected: _showWalls,
                onSelected: (v) => setState(() => _showWalls = v),
              ),
              FilterChip(
                label: const Text('Routes'),
                selected: _showGraph,
                onSelected: (v) => setState(() => _showGraph = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_plan == null)
            const SizedBox(
              height: 320,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 56, color: _violet),
                    SizedBox(height: 16),
                    Text('Your extraction appears here'),
                    SizedBox(height: 8),
                    Text(
                      'Run the demo to inspect rooms, walls, doors and routes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 380,
              child: Center(
                child: AspectRatio(
                  aspectRatio:
                      (_payload!['extraction']['width'] as num) /
                      (_payload!['extraction']['height'] as num),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(_plan!, fit: BoxFit.fill),
                      CustomPaint(
                        painter: PlanOverlay(
                          _payload!['extraction'] as Map<String, dynamic>,
                          _payload!['graph'] as Map<String, dynamic>?,
                          rooms: _showRooms,
                          walls: _showWalls,
                          graph: _showGraph,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Violet: rooms   •   Red: walls   •   Green: doors and candidate routes',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (_payload != null) ...[
            const Divider(height: 28),
            Text(
              _payload!['synthetic'] == true
                  ? (_payload!['inference_mode'] == 'databricks'
                        ? 'SYNTHETIC PLAN · live Databricks VLM'
                        : 'SYNTHETIC DEMO · recorded output')
                  : 'Candidate geometry · requires review',
              style: const TextStyle(
                color: _violet,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Preview checks geometry. It does not verify that every wall or connection was extracted.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
    final result = _payload?['result'] as Map<String, dynamic>?;
    final metrics = _payload?['metrics'] as Map<String, dynamic>?;
    final issues = result?['validation']?['issues'] as List? ?? [];
    return [
      if (wide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 350, child: input),
            const SizedBox(width: 20),
            Expanded(child: preview),
          ],
        )
      else ...[
        input,
        const SizedBox(height: 16),
        preview,
      ],
      const SizedBox(height: 20),
      _panel(
        '03 / QUALITY & VALIDATION',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              metrics == null
                  ? 'Accuracy: not measured'
                  : (_payload!['synthetic'] == true
                        ? 'Measured against synthetic reference annotations'
                        : 'Measured against your reference annotations'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Accuracy requires independent ground truth. Model confidence is a separate, uncalibrated estimate.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metric(
                  'Room detection F1',
                  _percent(metrics?['rooms']?['f1']),
                ),
                _metric(
                  'Category accuracy',
                  _percent(metrics?['rooms']?['matched_category_accuracy']),
                ),
                for (final category in ['bathroom', 'elevator', 'stairs'])
                  _metric(
                    '${categoryLabel(category)} F1',
                    _percent(
                      metrics?['features_by_category']?[category]?['f1'],
                    ),
                  ),
                _metric('Door recall', _percent(metrics?['doors']?['recall'])),
                _metric(
                  'Wall matched IoU',
                  _percent(metrics?['walls']?['matched_similarity_mean']),
                ),
                _metric(
                  'Matched text accuracy',
                  _percent(metrics?['rooms']?['matched_text_accuracy']),
                ),
                _metric(
                  'Model confidence',
                  _percent(_payload?['mean_confidence']),
                ),
                _metric(
                  'Total latency',
                  result == null
                      ? '—'
                      : '${(result['timings_s']['total'] as num).toStringAsFixed(2)} s',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (result != null)
              Text(
                '${result['validation']['candidate_valid'] == true ? 'Local geometry checks passed' : 'Review issues found'} · Human review required',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            for (final issue in issues)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '• $issue',
                  style: const TextStyle(color: Colors.deepOrange),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _benchmarkContent(bool ready) {
    final summary = _benchmark?['summary'] as Map<String, dynamic>?;
    final rows = _benchmark?['results'] as List? ?? [];
    return [
      _panel(
        'BENCHMARK WORKSPACE',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compare runs on the same labeled plans',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'The built-in benchmark repeats the synthetic recorded case three times. Import a real benchmark.json to inspect model performance.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy || !ready ? null : _runBenchmark,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run synthetic benchmark'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      _busy || !ready || _capabilities['live_ready'] != true
                      ? null
                      : () => _runBenchmark(live: true),
                  icon: const Icon(Icons.cloud_outlined),
                  label: const Text('Run live VLM benchmark'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _import('benchmark'),
                  icon: const Icon(Icons.file_open_outlined),
                  label: const Text('Import benchmark report'),
                ),
              ],
            ),
          ],
        ),
      ),
      if (summary != null) ...[
        const SizedBox(height: 20),
        _banner(
          'Dataset: ${_benchmark!['manifest']?['dataset'] ?? 'Imported report'} · ${summary['runs']} runs · ${_benchmark!['run_source'] ?? 'Imported report'}. Read quality scores alongside failures.',
          Icons.info_outline,
          _violet,
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metric('Room F1', _percent(summary['rooms']?['f1'])),
            for (final category in ['bathroom', 'elevator', 'stairs'])
              _metric(
                '${categoryLabel(category)} F1',
                _percent(summary['features_by_category']?[category]?['f1']),
              ),
            _metric('Door F1', _percent(summary['doors']?['f1'])),
            _metric('Failure rate', _percent(summary['failure_rate'])),
            _metric(
              'Reference route success',
              _percent(summary['reference_route_success_mean']),
            ),
            _metric(
              'Total p95 latency',
              summary['latency_total_p95_s'] == null
                  ? '—'
                  : '${(summary['latency_total_p95_s'] as num).toStringAsFixed(3)} s',
            ),
            _metric(
              'Inference retries',
              '${summary['inference_retries'] ?? '—'}',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _panel(
          'PER-RUN RESULTS',
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Case')),
                DataColumn(label: Text('Repeat')),
                DataColumn(label: Text('Result')),
                DataColumn(label: Text('Room F1')),
                DataColumn(label: Text('Latency')),
              ],
              rows: [
                for (final row in rows)
                  DataRow(
                    cells: [
                      DataCell(Text('${row['case_id']}')),
                      DataCell(Text('${row['repeat']}')),
                      DataCell(
                        Text(
                          row['evaluation_failed'] == true
                              ? 'evaluation failed'
                              : '${row['run']['status']}',
                        ),
                      ),
                      DataCell(Text(_percent(row['metrics']?['rooms']?['f1']))),
                      DataCell(
                        Text(
                          '${(row['run']['timings_s']['total'] as num).toStringAsFixed(3)} s',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _trainingContent(bool ready) => [
    _panel(
      '01 / REVIEW & DATASET',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Turn corrections into training examples',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Run an extraction, then draw or adjust annotations on the plan. Review room labels, wall polygons, doors and walkable areas before saving. Original model predictions and benchmark scores remain unchanged.',
          ),
          const SizedBox(height: 18),
          if (_annotations != null && _plan != null) ...[
            AnnotationEditor(
              document: _annotations!,
              image: _plan!,
              enabled: !_busy && !_jsonDirty,
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              key: const Key('annotation-json'),
              tilePadding: EdgeInsets.zero,
              title: const Text('Advanced: reviewed extraction JSON'),
              subtitle: Text(
                _jsonDirty
                    ? 'Apply or discard JSON edits to resume drawing.'
                    : 'Drawing updates this JSON automatically.',
              ),
              children: [
                TextField(
                  key: const Key('reviewed-json-field'),
                  controller: _correction,
                  minLines: 8,
                  maxLines: 16,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  onChanged: (_) => setState(() {
                    _reviewed = false;
                    _jsonDirty = true;
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Reviewed extraction JSON',
                    alignLabelWithHint: true,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: !_busy && _jsonDirty
                          ? _applyAnnotationJson
                          : null,
                      child: const Text('Apply JSON to drawing'),
                    ),
                    TextButton(
                      onPressed: !_busy && _jsonDirty
                          ? () => setState(() {
                              _correction.text = _annotations!.json;
                              _jsonDirty = false;
                            })
                          : null,
                      child: const Text('Discard JSON edits'),
                    ),
                  ],
                ),
              ],
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Run an extraction in the Extract tab to start drawing on your plan.',
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _group,
            decoration: const InputDecoration(
              labelText: 'Building / source group',
              helperText: 'Use the same group for all plans from one building.',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _split,
            decoration: const InputDecoration(labelText: 'Dataset split'),
            items: const [
              DropdownMenuItem(value: 'train', child: Text('Train')),
              DropdownMenuItem(value: 'validation', child: Text('Validation')),
              DropdownMenuItem(value: 'test', child: Text('Held-out test')),
            ],
            onChanged: _busy
                ? null
                : (value) => setState(() => _split = value!),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _reviewed,
            onChanged: _busy
                ? null
                : (value) => setState(() => _reviewed = value!),
            title: const Text('I checked these annotations against the plan'),
            subtitle: const Text(
              'Keep held-out test examples out of training. Synthetic examples are excluded by the training script.',
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed:
                    _busy ||
                        !ready ||
                        !_reviewed ||
                        _jsonDirty ||
                        _sourceJobId == null
                    ? null
                    : _saveReview,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save reviewed example'),
              ),
              OutlinedButton.icon(
                onPressed: _busy || !ready ? null : _export,
                icon: const Icon(Icons.download),
                label: const Text('Export dataset ZIP'),
              ),
            ],
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    _panel(
      '02 / DATABRICKS FINE-TUNING',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Train a LoRA adapter on GPU compute',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _capabilities['training_ready'] == true
                ? 'Training job configured. This action starts a paid Databricks job.'
                : 'Training job is not configured. Export your dataset, unpack it into a Unity Catalog Volume, and configure MADMAPS_TRAINING_JOB_ID on the server.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _manifest,
            decoration: const InputDecoration(
              labelText: 'Training manifest in a Unity Catalog Volume',
              hintText: '/Volumes/catalog/schema/volume/dataset/manifest.json',
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _epochs,
                  decoration: const InputDecoration(labelText: 'Epochs · 1–10'),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _rate,
                  decoration: const InputDecoration(labelText: 'Learning rate'),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _rank,
                  decoration: const InputDecoration(labelText: 'LoRA rank'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed:
                  _busy || !ready || _capabilities['training_ready'] != true
                  ? null
                  : _train,
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('Launch Databricks fine-tune'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Training saves a candidate model. Evaluate it on held-out plans before manually deploying it; this lab never promotes a model automatically.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
  ];

  Widget _panel(String label, Widget child) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: _border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _violet,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );

  Widget _banner(String text, IconData icon, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );

  Widget _metric(String label, String value) => Container(
    width: 185,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xfff7f6fc),
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
      ],
    ),
  );

  String _percent(dynamic value) => value is num && value.isFinite
      ? '${(value * 100).toStringAsFixed(1)}%'
      : '—';
}

class PlanOverlay extends CustomPainter {
  PlanOverlay(
    this.extraction,
    this.candidate, {
    required this.rooms,
    required this.walls,
    required this.graph,
  });
  final Map<String, dynamic> extraction;
  final Map<String, dynamic>? candidate;
  final bool rooms, walls, graph;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / (extraction['width'] as num),
        sy = size.height / (extraction['height'] as num);
    Offset point(dynamic p) => Offset((p[0] as num) * sx, (p[1] as num) * sy);
    if (rooms) {
      for (final room in extraction['rooms'] as List) {
        final vertices = roomVertices(Map<String, dynamic>.from(room));
        final path = Path()
          ..addPolygon([
            for (final p in vertices) point([p.dx, p.dy]),
          ], true);
        canvas.drawPath(
          path,
          Paint()
            ..color = _violet
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        final label = TextPainter(
          text: TextSpan(
            text:
                '${categoryLabel(room['category'] as String)} · ${room['label']}',
            style: const TextStyle(
              color: _violet,
              fontSize: 11,
              backgroundColor: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: size.width);
        label.paint(canvas, point([vertices.first.dx, vertices.first.dy]));
      }
    }
    if (walls) {
      for (final wall in extraction['walls'] as List) {
        final vertices = wall['polygon'] as List;
        final path = Path()
          ..moveTo(point(vertices.first).dx, point(vertices.first).dy);
        for (final vertex in vertices.skip(1)) {
          final p = point(vertex);
          path.lineTo(p.dx, p.dy);
        }
        path.close();
        canvas.drawPath(
          path,
          Paint()..color = Colors.red.withValues(alpha: .3),
        );
      }
    }
    if (graph && candidate != null) {
      final nodes = {
        for (final n in candidate!['nodes'] as List)
          n['nodeId']: Offset((n['x'] as num) * sx, (n['y'] as num) * sy),
      };
      for (final edge in candidate!['edges'] as List) {
        canvas.drawLine(
          nodes[edge['fromNodeId']]!,
          nodes[edge['toNodeId']]!,
          Paint()
            ..color = _green.withValues(alpha: .35)
            ..strokeWidth = 1,
        );
      }
    }
    for (final door in extraction['doors'] as List) {
      canvas.drawCircle(point(door['point']), 4, Paint()..color = _green);
    }
  }

  @override
  bool shouldRepaint(covariant PlanOverlay oldDelegate) =>
      oldDelegate.extraction != extraction ||
      oldDelegate.candidate != candidate ||
      oldDelegate.rooms != rooms ||
      oldDelegate.walls != walls ||
      oldDelegate.graph != graph;
}
