import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'lab_api.dart';
import '../features/navigation/place_maps.dart';

const _placeCategories = <String, String>{
  'other': 'Room',
  'bathroom': 'Restroom',
  'elevator': 'Elevator',
  'stairs': 'Stairs',
  'entrance': 'Entrance',
  'exit': 'Exit',
  'classroom': 'Classroom',
  'office': 'Office',
  'studySpace': 'Study space',
  'food': 'Food',
  'auditorium': 'Auditorium',
  'accessibilityService': 'Accessible amenity',
  'landmark': 'Landmark',
};

class RoomAmenityMapScreen extends StatefulWidget {
  const RoomAmenityMapScreen({
    super.key,
    this.api,
    this.pickPlan,
    this.onExport,
    this.onConnectionCheck,
    this.placeMapsApi,
    this.initialMap,
    this.onSaved,
  });
  final PlaceMapsApi? placeMapsApi;
  final SavedPlaceMap? initialMap;
  final VoidCallback? onSaved;
  final LabApi? api;
  final Future<XFile?> Function()? pickPlan;
  final Future<void> Function(String)? onExport;
  final VoidCallback? onConnectionCheck;

  @override
  State<RoomAmenityMapScreen> createState() => _RoomAmenityMapScreenState();
}

class _RoomAmenityMapScreenState extends State<RoomAmenityMapScreen> {
  late final LabApi _api = widget.api ?? ServerpodLabApi();
  late final PlaceMapsApi _mapsApi =
      widget.placeMapsApi ?? ServerpodPlaceMapsApi();
  SavedPlaceMap? _savedMap;
  final _canvasKey = GlobalKey();
  final _viewportKey = GlobalKey();
  Offset? _dragStartPoint, _dragOrigin;
  final _transform = TransformationController();
  bool _workerReady = false,
      _liveReady = false,
      _busy = false,
      _adding = false,
      _detected = false,
      _sample = false;
  String? _error, _notice, _name, _selected;
  Uint8List? _image, _upload;
  double _width = 0, _height = 0;
  List<Map<String, dynamic>> _places = [];

  @override
  void initState() {
    super.initState();
    _refresh();
    if (widget.initialMap != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _perform(() async {
          final map = widget.initialMap!;
          await _loadDocument(map.mapJson!, map.buildingName);
          _savedMap = map;
        });
      });
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final result = await _api.capabilities();
      if (!mounted) return;
      setState(() {
        _workerReady = result['worker_ready'] == true;
        _liveReady = result['live_ready'] == true;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Cannot reach the backend. Reconnect to load a floor plan.',
        );
      }
    }
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
      if (mounted) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<Map<String, dynamic>> _job(Map<String, dynamic> request) async {
    final id = await _api.start({
      'action': 'extract',
      'profile': 'places',
      ...request,
    });
    final deadline = DateTime.now().add(const Duration(seconds: 90));
    while (mounted && DateTime.now().isBefore(deadline)) {
      final result = await _api.getJob(id);
      if (result['status'] == 'completed') {
        return result['payload'] as Map<String, dynamic>;
      }
      if (result['status'] == 'failed') {
        throw StateError(
          result['error'] as String? ??
              'Could not find places. You can add pins manually.',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw StateError('Detection took too long. You can add pins manually.');
  }

  void _apply(
    Map<String, dynamic> payload, {
    required String name,
    Uint8List? upload,
    bool sample = false,
  }) {
    final result = payload['result'] as Map<String, dynamic>;
    final metadata = result['metadata'] as Map<String, dynamic>;
    final width = (metadata['width'] as num).toDouble(),
        height = (metadata['height'] as num).toDouble();
    final places = _readPlaces(payload['places'], width, height);
    final image = base64Decode(payload['plan_base64'] as String);
    if (!mounted) return;
    setState(() {
      _savedMap = null;
      _image = image;
      _width = width;
      _height = height;
      _places = places;
      _name = name;
      _upload = upload;
      _sample = sample;
      _selected = null;
      _adding = false;
      _detected = false;
      _transform.value = Matrix4.identity();
      _notice = sample
          ? 'Example plan with sample pins.'
          : 'Plan loaded. Find places automatically or add your own pins.';
    });
  }

  List<Map<String, dynamic>> _readPlaces(
    dynamic value,
    double width,
    double height,
  ) {
    if (!width.isFinite ||
        !height.isFinite ||
        width <= 0 ||
        height <= 0 ||
        value is! List ||
        value.length > 1000) {
      throw const FormatException('Invalid saved map.');
    }
    final result = <Map<String, dynamic>>[];
    final ids = <String>{};
    for (final item in value) {
      final row = Map<String, dynamic>.from(item as Map);
      final x = row['x'], y = row['y'];
      if (row['id'] is! String ||
          !ids.add(row['id'] as String) ||
          row['label'] is! String ||
          (row['label'] as String).trim().isEmpty ||
          !_placeCategories.containsKey(row['category']) ||
          x is! num ||
          y is! num ||
          !x.isFinite ||
          !y.isFinite ||
          x < 0 ||
          y < 0 ||
          x > width ||
          y > height) {
        throw const FormatException('Invalid place in saved map.');
      }
      result.add({
        'id': row['id'],
        'label': row['label'],
        'category': row['category'],
        'x': x.toDouble(),
        'y': y.toDouble(),
        'source': row['source'] ?? 'manual',
      });
    }
    return result;
  }

  Future<void> _choosePlan() => _perform(() async {
    final file =
        await (widget.pickPlan?.call() ??
            openFile(
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
            ));
    if (file == null) return;
    if (await file.length() > 8 * 1024 * 1024) {
      throw ArgumentError('Choose a plan of 8 MB or less.');
    }
    final bytes = await file.readAsBytes();
    final payload = await _job({
      'mode': 'manual',
      'file_name': file.name,
      'file_base64': base64Encode(bytes),
      'page': 0,
    });
    _apply(payload, name: file.name, upload: bytes);
  });

  Future<void> _example() => _perform(() async {
    final payload = await _job({'mode': 'demo'});
    _apply(payload, name: 'Example floor plan', sample: true);
  });

  Future<void> _detect() => _perform(() async {
    final payload = await _job({
      'mode': 'databricks',
      'sample_plan': _sample,
      if (!_sample) ...{
        'file_name': _name,
        'file_base64': base64Encode(_upload!),
        'page': 0,
      },
    });
    final result = payload['result'] as Map<String, dynamic>;
    final pins = _readPlaces(payload['places'], _width, _height);
    if (!mounted) return;
    setState(() {
      _places = pins;
      _detected = true;
      _adding = false;
      final seconds = ((result['timings_s'] as Map)['extraction'] as num)
          .toStringAsFixed(1);
      _notice =
          '${pins.length} places found in ${seconds}s. Tap a pin to edit. Drag a pin to move it.';
    });
  });

  Offset _imagePoint(Offset global) {
    final box = _canvasKey.currentContext!.findRenderObject()! as RenderBox;
    final point = box.globalToLocal(global);
    return Offset(
      (point.dx / box.size.width * _width).clamp(0, _width),
      (point.dy / box.size.height * _height).clamp(0, _height),
    );
  }

  void _zoom(double factor) {
    final box = _viewportKey.currentContext!.findRenderObject()! as RenderBox;
    final current = _transform.value;
    final scale = current.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(1.0, 6.0);
    final ratio = next / scale;
    final center = box.size.center(Offset.zero);
    // Keep the viewport center fixed, and keep the map inside its boundaries.
    final x = (center.dx + (current.storage[12] - center.dx) * ratio).clamp(
      box.size.width * (1 - next),
      0.0,
    );
    final y = (center.dy + (current.storage[13] - center.dy) * ratio).clamp(
      box.size.height * (1 - next),
      0.0,
    );
    _transform.value = Matrix4.identity()
      ..setEntry(0, 0, next)
      ..setEntry(1, 1, next)
      ..setEntry(0, 3, x)
      ..setEntry(1, 3, y);
  }

  Future<Map<String, dynamic>?> _editor(Map<String, dynamic>? place) async {
    final label = TextEditingController(text: place?['label'] as String? ?? '');
    var category = place?['category'] as String? ?? 'other';
    String? error;
    final route = DialogRoute<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(place == null ? 'Add place' : 'Edit place'),
          content: SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('place-label'),
                    controller: label,
                    autofocus: true,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: 'Name or room number',
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: _placeCategories.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => category = value!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (place != null)
              TextButton(
                onPressed: () => Navigator.pop(context, {'delete': true}),
                child: const Text('Delete'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('save-place'),
              onPressed: () {
                if (label.text.trim().isEmpty) {
                  update(() => error = 'Enter a name or room number.');
                  return;
                }
                Navigator.pop(context, {
                  'label': label.text.trim(),
                  'category': category,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    final result = await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
    label.dispose();
    return result;
  }

  Future<void> _edit(Map<String, dynamic> place) async {
    if (_busy) return;
    setState(() => _selected = place['id'] as String);
    final result = await _editor(place);
    if (result == null || !mounted) return;
    setState(() {
      if (result['delete'] == true) {
        _places.removeWhere((pin) => pin['id'] == place['id']);
        _selected = null;
      } else {
        place.addAll(result);
        place['source'] = 'manual';
      }
      _detected = true;
      _error = null;
      _notice = result['delete'] == true ? 'Place removed.' : 'Place updated.';
    });
  }

  Future<void> _placeAt(Offset global) async {
    if (!_adding || _busy) return;
    final point = _imagePoint(global);
    setState(() => _adding = false);
    final result = await _editor(null);
    if (result == null || !mounted) return;
    setState(() {
      _places.add({
        'id': 'manual-${DateTime.now().microsecondsSinceEpoch}',
        ...result,
        'x': point.dx,
        'y': point.dy,
        'source': 'manual',
      });
      _detected = true;
      _error = null;
      _notice = 'Place added.';
    });
  }

  String _mapJson() => const JsonEncoder.withIndent('  ').convert({
    'schema_version': 1,
    'profile': 'rooms-and-amenities-v1',
    'name': _name,
    'width': _width,
    'height': _height,
    'coordinate_origin': 'top-left',
    'coordinate_units': 'pixels',
    'image_base64': base64Encode(_image!),
    'image_mime_type': 'image/png',
    'places': _places,
  });

  Future<void> _export() => _perform(() async {
    final content = _mapJson();
    if (widget.onExport != null) {
      await widget.onExport!(content);
      return;
    }
    const name = 'madmaps-places.json';
    String path = name;
    if (!kIsWeb) {
      try {
        final location = await getSaveLocation(suggestedName: name);
        if (location == null) return;
        path = location.path;
      } on UnsupportedError {
        await Clipboard.setData(ClipboardData(text: content));
        if (mounted) {
          setState(() => _notice = 'Map JSON copied to the clipboard.');
        }
        return;
      }
    }
    await XFile.fromData(
      Uint8List.fromList(utf8.encode(content)),
      name: name,
      mimeType: 'application/json',
    ).saveTo(path);
    if (mounted) {
      setState(() => _notice = 'Saved map image and ${_places.length} places.');
    }
  });

  Future<void> _openSaved() => _perform(() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Saved map',
          extensions: ['json'],
          uniformTypeIdentifiers: ['public.json'],
        ),
      ],
    );
    if (file == null) return;
    if (await file.length() > 32 * 1024 * 1024) {
      throw ArgumentError('Saved map is too large.');
    }
    await _loadDocument(await file.readAsString(), file.name);
  });

  Future<void> _loadDocument(String content, String fallbackName) async {
    final value = jsonDecode(content) as Map<String, dynamic>;
    if (value['profile'] != 'rooms-and-amenities-v1' ||
        value['schema_version'] != 1) {
      throw const FormatException(
        'Choose an exported rooms-and-amenities map.',
      );
    }
    final width = (value['width'] as num).toDouble(),
        height = (value['height'] as num).toDouble();
    final places = _readPlaces(value['places'], width, height);
    final bytes = base64Decode(value['image_base64'] as String);
    // Saved maps always contain PNGs rendered by the upload worker.
    const signature = [
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      0,
      0,
      0,
      13,
      73,
      72,
      68,
      82,
    ];
    if (bytes.length < 33 ||
        List.generate(
          signature.length,
          (i) => bytes[i] == signature[i],
        ).contains(false) ||
        ByteData.sublistView(bytes).getUint32(16) != width ||
        ByteData.sublistView(bytes).getUint32(20) != height) {
      throw const FormatException(
        'Saved image dimensions do not match its pins.',
      );
    }
    if (!mounted) return;
    setState(() {
      _image = bytes;
      _width = width;
      _height = height;
      _places = places;
      _name = value['name'] as String? ?? fallbackName;
      _savedMap = null;
      _upload = null;
      _sample = false;
      _detected = true;
      _adding = false;
      _selected = null;
      _transform.value = Matrix4.identity();
      _notice =
          'Saved map opened. Review the pins, then save to app to add them to destination search.';
    });
  }

  Future<void> _saveToApp() async {
    final building = TextEditingController(text: _savedMap?.buildingName ?? '');
    final floor = TextEditingController(
      text: _savedMap?.floorLabel ?? 'Floor 1',
    );
    String? error;
    final route = DialogRoute<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Save to destination search'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Review the pins, then name the building and floor. Places will be visible in Home search.',
                ),
                TextField(
                  key: const Key('map-building-name'),
                  controller: building,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Building name'),
                ),
                TextField(
                  key: const Key('map-floor-name'),
                  controller: floor,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Floor name'),
                ),
                if (error != null) Text(error!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm-save-map'),
              onPressed: () {
                if (building.text.trim().isEmpty || floor.text.trim().isEmpty) {
                  update(() => error = 'Enter a building and floor name.');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Save to app'),
            ),
          ],
        ),
      ),
    );
    final confirmed = await Navigator.of(context).push(route);
    final buildingName = building.text.trim(), floorName = floor.text.trim();
    await route.completed;
    building.dispose();
    floor.dispose();
    if (confirmed != true || !mounted) return;
    await _perform(() async {
      final saved = await _mapsApi.save(
        _mapJson(),
        buildingName,
        floorName,
        mapId: _savedMap?.mapId,
        expectedVersion: _savedMap?.version,
      );
      if (!mounted) return;
      setState(() {
        _savedMap = saved;
        _notice =
            'Saved to app. Find ${saved.buildingName} and its places in Home search.';
      });
      widget.onSaved?.call();
    });
  }

  Widget _map() => SizedBox(
    height: 440,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: const Color(0xffeeeeF4),
        child: InteractiveViewer(
          key: _viewportKey,
          scaleEnabled: false,
          transformationController: _transform,
          minScale: 1,
          maxScale: 6,
          child: Center(
            child: AspectRatio(
              aspectRatio: _width / _height,
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  key: _canvasKey,
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _placeAt(details.globalPosition),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Image.memory(
                          _image!,
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                        ),
                      ),
                      for (var index = 0; index < _places.length; index++)
                        Positioned(
                          left:
                              (_places[index]['x'] as num) /
                                  _width *
                                  constraints.maxWidth -
                              14,
                          top:
                              (_places[index]['y'] as num) /
                                  _height *
                                  constraints.maxHeight -
                              14,
                          child: GestureDetector(
                            key: ValueKey('map-pin-${_places[index]['id']}'),
                            dragStartBehavior: DragStartBehavior.down,
                            onTap: () => _edit(_places[index]),
                            onPanStart: _busy
                                ? null
                                : (details) {
                                    _dragStartPoint = _imagePoint(
                                      details.globalPosition,
                                    );
                                    _dragOrigin = Offset(
                                      (_places[index]['x'] as num).toDouble(),
                                      (_places[index]['y'] as num).toDouble(),
                                    );
                                  },
                            onPanUpdate: _busy
                                ? null
                                : (details) {
                                    final point =
                                        _dragOrigin! +
                                        _imagePoint(details.globalPosition) -
                                        _dragStartPoint!;
                                    setState(() {
                                      _places[index]['x'] = point.dx.clamp(
                                        0,
                                        _width,
                                      );
                                      _places[index]['y'] = point.dy.clamp(
                                        0,
                                        _height,
                                      );
                                      _places[index]['source'] = 'manual';
                                      _selected =
                                          _places[index]['id'] as String;
                                      _detected = true;
                                    });
                                  },
                            child: Semantics(
                              label: _places[index]['label'] as String,
                              child: Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _selected == _places[index]['id']
                                      ? Colors.orange.shade800
                                      : Colors.indigo,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.initialMap == null ? 'Upload a new floor map' : 'Edit floor map',
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
        PopupMenuButton<String>(
          enabled: !_busy,
          onSelected: (_) => _openSaved(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'open', child: Text('Open saved map')),
          ],
        ),
      ],
    ),
    body: Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Turn a floor plan into a map of rooms and amenities.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('choose-place-plan'),
                  onPressed: _busy || !_workerReady ? null : _choosePlan,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload floor plan'),
                ),
                OutlinedButton(
                  key: const Key('example-place-plan'),
                  onPressed: _busy || !_workerReady ? null : _example,
                  child: const Text('Try example'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'PNG, JPEG, or the first page of a PDF · up to 8 MB',
              style: TextStyle(color: Colors.black54),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  key: const Key('places-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_notice != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_notice!),
              ),
            if (_image != null) ...[
              const SizedBox(height: 8),
              Text(
                _name ?? 'Floor plan',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const Key('find-places'),
                    onPressed: _busy || !_liveReady || _detected
                        ? null
                        : _detect,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Find rooms & amenities'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('add-map-place'),
                    onPressed: _busy
                        ? null
                        : () => setState(() => _adding = !_adding),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text(_adding ? 'Cancel placement' : 'Add a place'),
                  ),
                  FilledButton.icon(
                    key: const Key('save-place-map'),
                    onPressed: _busy || _places.isEmpty ? null : _saveToApp,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save to app'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('export-place-map'),
                    onPressed: _busy ? null : _export,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export map'),
                  ),
                  IconButton(
                    key: const Key('place-map-zoom-in'),
                    tooltip: 'Zoom in',
                    onPressed: () => _zoom(1.25),
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    key: const Key('place-map-zoom-out'),
                    tooltip: 'Zoom out',
                    onPressed: () => _zoom(1 / 1.25),
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    tooltip: 'Fit map',
                    onPressed: () =>
                        setState(() => _transform.value = Matrix4.identity()),
                    icon: const Icon(Icons.fit_screen),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _adding
                    ? 'Tap the image where you want to add a place.'
                    : 'Drag a pin to move it. Tap to edit. Use + and − to zoom.',
              ),
              const SizedBox(height: 10),
              _map(),
              const SizedBox(height: 16),
              Text(
                _places.length == 1 ? '1 place' : '${_places.length} places',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_places.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No pins yet. Find rooms automatically or add a place on the image.',
                  ),
                ),
              for (var index = 0; index < _places.length; index++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(_places[index]['label'] as String),
                  subtitle: Text(
                    _placeCategories[_places[index]['category']] ?? 'Room',
                  ),
                  trailing: IconButton(
                    tooltip: 'Edit ${_places[index]['label']}',
                    onPressed: _busy ? null : () => _edit(_places[index]),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  onTap: _busy ? null : () => _edit(_places[index]),
                ),
            ],
          ],
        ),
        if (_busy)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(),
          ),
      ],
    ),
  );
}
