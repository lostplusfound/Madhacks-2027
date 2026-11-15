import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'annotation_document.dart';

enum AnnotationTool { select, wall, walkable, room, door, pan }

class AnnotationEditor extends StatefulWidget {
  const AnnotationEditor({
    super.key,
    required this.document,
    required this.image,
    this.enabled = true,
  });
  final AnnotationDocument document;
  final Uint8List image;
  final bool enabled;

  @override
  State<AnnotationEditor> createState() => _AnnotationEditorState();
}

class _AnnotationEditorState extends State<AnnotationEditor> {
  AnnotationTool _tool = AnnotationTool.select;
  final _transform = TransformationController();
  final _focus = FocusNode(debugLabel: 'Annotation canvas');
  final _draft = <Offset>[];
  String? _doorRoom, _error;
  String _newRoomCategory = 'other';
  bool _rotating = false;
  double? _rotationPreview, _rotationPolarStart;
  double _rotationBase = 0;
  Offset? _cursor, _panOrigin, _dragPoint;
  int? _handle;
  bool _dragging = false, _suppressTap = false;
  final _pointers = <int>{};
  int? _drawingPointer;
  Offset? _screenOrigin;
  Size _canvasSize = Size.zero;
  double get _zoom => _transform.value.getMaxScaleOnAxis();
  double get _tolerance =>
      12 * widget.document.width / math.max(1, _canvasSize.width * _zoom);

  @override
  void initState() {
    super.initState();
    widget.document.addListener(_changed);
    _transform.addListener(_changed);
  }

  @override
  void didUpdateWidget(AnnotationEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document) {
      oldWidget.document.removeListener(_changed);
      widget.document.addListener(_changed);
      _draft.clear();
      _handle = null;
      _dragPoint = null;
      _doorRoom = null;
      _transform.value = Matrix4.identity();
    }
    if (!widget.enabled) {
      _draft.clear();
      _dragPoint = null;
      _dragging = false;
    }
  }

  @override
  void dispose() {
    widget.document.removeListener(_changed);
    _transform.removeListener(_changed);
    _transform.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _attempt(VoidCallback action) {
    try {
      action();
      if (mounted) setState(() => _error = null);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Offset _pixel(Offset local) => Offset(
    (local.dx * widget.document.width / _canvasSize.width).clamp(
      0,
      widget.document.width,
    ),
    (local.dy * widget.document.height / _canvasSize.height).clamp(
      0,
      widget.document.height,
    ),
  );
  void _setTool(AnnotationTool tool) => setState(() {
    _tool = tool;
    _rotating = false;
    _rotationPreview = null;
    if (tool == AnnotationTool.room) _newRoomCategory = 'other';
    _draft.clear();
    _dragPoint = null;
    _handle = null;
    _error = null;
  });
  void _startFeature(String category) {
    _setTool(AnnotationTool.room);
    setState(() => _newRoomCategory = category);
  }

  void _cancel() => setState(() {
    _rotating = false;
    _rotationPreview = null;
    _draft.clear();
    _dragPoint = null;
    _dragging = false;
    _error = null;
  });
  void _finish() {
    if (_draft.length < 3) {
      setState(() => _error = 'Click at least three corners before finishing.');
      return;
    }
    _attempt(() {
      widget.document.addPolygon(
        _tool == AnnotationTool.wall ? 'walls' : 'walkable_areas',
        List.of(_draft),
      );
      _draft.clear();
      _tool = AnnotationTool.select;
      _handle = null;
    });
  }

  AnnotationSelection? _hit(Offset p) {
    final data = widget.document.data;
    for (final group in ['doors', 'walls', 'rooms', 'walkable_areas']) {
      for (final item in (data[group] as List).reversed) {
        final s = AnnotationSelection(group, item['id'] as String);
        final vertices = widget.document.vertices(s);
        if (group == 'doors') {
          if ((vertices.first - p).distance <= _tolerance) return s;
          continue;
        }
        final path = Path()..addPolygon(vertices, true);
        if (path.contains(p)) return s;
        for (var i = 0; i < vertices.length; i++) {
          final a = vertices[i],
              b = vertices[(i + 1) % vertices.length],
              ab = b - a;
          final fraction = ab.distanceSquared == 0
              ? 0.0
              : (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / ab.distanceSquared)
                    .clamp(0.0, 1.0);
          if ((p - (a + ab * fraction)).distance <= _tolerance) return s;
        }
      }
    }
    return null;
  }

  int? _hitHandle(Offset p) {
    final selected = widget.document.selection;
    if (selected == null) return null;
    final vertices = widget.document.vertices(selected);
    for (var i = 0; i < vertices.length; i++) {
      if ((vertices[i] - p).distance <= _tolerance) return i;
    }
    return null;
  }

  void _tap(TapUpDetails details) {
    _focus.requestFocus();
    final point = _pixel(details.localPosition);
    setState(() => _error = null);
    switch (_tool) {
      case AnnotationTool.wall:
      case AnnotationTool.walkable:
        if (_draft.length >= 3 &&
            (point - _draft.first).distance <= _tolerance) {
          _finish();
        } else {
          setState(() => _draft.add(point));
        }
      case AnnotationTool.door:
        if (_doorRoom == null) {
          setState(
            () => _error = 'Choose the room this door belongs to first.',
          );
          return;
        }
        _attempt(() => widget.document.addDoor(point, _doorRoom!));
      case AnnotationTool.select:
        final handle = _hitHandle(point);
        if (handle != null) {
          setState(() => _handle = handle);
        } else {
          widget.document.select(_hit(point));
          setState(() => _handle = null);
        }
      case AnnotationTool.room:
      case AnnotationTool.pan:
        break;
    }
  }

  void _pointerDown(PointerDownEvent event) {
    if (!widget.enabled || event.buttons != 1) return;
    _pointers.add(event.pointer);
    _suppressTap = false;
    if (_pointers.length > 1) {
      _drawingPointer = null;
      setState(() {
        _dragging = false;
        _dragPoint = null;
      });
      return;
    }
    _focus.requestFocus();
    _drawingPointer = event.pointer;
    _screenOrigin = event.position;
    _panOrigin = _pixel(event.localPosition);
    _rotating = false;
    _rotationPreview = null;
    if (_tool == AnnotationTool.select) {
      final selected = widget.document.selection;
      if (selected?.group == 'rooms') {
        final item = widget.document.selected!, center = roomCenter(item);
        final handle = roomRotationHandle(item, _tolerance * 2.2);
        if ((handle - _panOrigin!).distance <= _tolerance) {
          _rotating = true;
          _handle = null;
          _rotationBase = (item['rotation_deg'] as num? ?? 0).toDouble();
          _rotationPolarStart = math.atan2(
            _panOrigin!.dy - center.dy,
            _panOrigin!.dx - center.dx,
          );
        }
      }
      if (!_rotating) _handle = _hitHandle(_panOrigin!);
    }
  }

  void _pointerMove(PointerMoveEvent event) {
    if (!widget.enabled ||
        event.pointer != _drawingPointer ||
        _screenOrigin == null)
      return;
    if ((event.position - _screenOrigin!).distance <= 3 && !_dragging) return;
    _suppressTap = true;
    if (_tool != AnnotationTool.room &&
        !_rotating &&
        !(_tool == AnnotationTool.select && _handle != null))
      return;
    setState(() {
      _dragging = true;
      _dragPoint = _pixel(event.localPosition);
      if (_rotating) {
        final center = roomCenter(widget.document.selected!);
        var angle = normalizedRotation(
          _rotationBase +
              (math.atan2(
                        _dragPoint!.dy - center.dy,
                        _dragPoint!.dx - center.dx,
                      ) -
                      _rotationPolarStart!) *
                  180 /
                  math.pi,
        );
        if (HardwareKeyboard.instance.isShiftPressed)
          angle = (angle / 15).round() * 15.0;
        _rotationPreview = angle;
      }
    });
  }

  void _pointerUp(PointerUpEvent event) {
    _pointers.remove(event.pointer);
    if (!widget.enabled || event.pointer != _drawingPointer) return;
    _drawingPointer = null;
    final origin = _panOrigin, end = _dragPoint;
    if (_dragging && origin != null && end != null) {
      _attempt(() {
        if (_rotating && _rotationPreview != null) {
          widget.document.rotateSelected(_rotationPreview!);
        } else if (_tool == AnnotationTool.room) {
          widget.document.addRoom(origin, end, category: _newRoomCategory);
          _tool = AnnotationTool.select;
        } else if (_tool == AnnotationTool.select && _handle != null) {
          widget.document.moveVertex(_handle!, end);
        }
      });
    } else if (!_suppressTap && _tool != AnnotationTool.pan) {
      _tap(
        TapUpDetails(
          localPosition: event.localPosition,
          globalPosition: event.position,
          kind: event.kind,
        ),
      );
    }
    setState(() {
      _dragging = false;
      _dragPoint = null;
      _panOrigin = null;
      _rotating = false;
      _rotationPreview = null;
    });
  }

  void _pointerCancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    if (event.pointer == _drawingPointer) {
      _drawingPointer = null;
      setState(() {
        _dragging = false;
        _dragPoint = null;
        _panOrigin = null;
        _rotating = false;
        _rotationPreview = null;
      });
    }
  }

  void _key(KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent) return;
    final modifier =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancel();
    } else if (event.logicalKey == LogicalKeyboardKey.enter &&
        _draft.isNotEmpty) {
      _finish();
    } else if (modifier && event.logicalKey == LogicalKeyboardKey.keyZ) {
      _cancel();
      if (HardwareKeyboard.instance.isShiftPressed) {
        widget.document.redo();
      } else {
        widget.document.undo();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_draft.isNotEmpty) {
        setState(() => _draft.removeLast());
      } else {
        widget.document.deleteSelected();
      }
    }
  }

  void _changeZoom(double multiplier) {
    final next = (_zoom * multiplier).clamp(1.0, 8.0);
    setState(() {
      _transform.value = Matrix4.diagonal3Values(next, next, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document, data = document.data;
    final rooms = (data['rooms'] as List).cast<Map<String, dynamic>>();
    if (_doorRoom != null && !rooms.any((r) => r['id'] == _doorRoom))
      _doorRoom = null;
    final s = document.selection;
    final polygon = s != null && {'walls', 'walkable_areas'}.contains(s.group);
    final instruction = switch (_tool) {
      AnnotationTool.wall =>
        'Click each wall corner. Click the first point or Finish polygon to close it. Leave door gaps open.',
      AnnotationTool.walkable =>
        'Click the corners of a traversable area, then Finish polygon. Exclude solid obstacles.',
      AnnotationTool.room =>
        'Drag a box around the room or feature footprint, then set its label and category below. Symbols do not need room numbers.',
      AnnotationTool.door =>
        'Choose a room, then click its doorway in free space.',
      AnnotationTool.select =>
        'Click a shape, then drag its corners. Drag the round handle above a box to rotate it; hold Shift to snap to 15°. You can also enter an angle below.',
      AnnotationTool.pan =>
        'Drag to move around the plan. Use +/− or pinch to zoom; Fit resets the view.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Draw reviewed annotations',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Red: walls · Teal: walkable areas · Violet: room boxes · Green: doors. These edits update the training target; original benchmark scores stay unchanged.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in [
              (AnnotationTool.select, Icons.near_me_outlined, 'Select'),
              (AnnotationTool.wall, Icons.polyline, 'Wall polygon'),
              (
                AnnotationTool.walkable,
                Icons.route_outlined,
                'Walkable polygon',
              ),
              (AnnotationTool.room, Icons.crop_square, 'Room / feature box'),
              (
                AnnotationTool.door,
                Icons.door_front_door_outlined,
                'Door point',
              ),
              (AnnotationTool.pan, Icons.pan_tool_outlined, 'Pan'),
            ])
              ChoiceChip(
                key: Key('annotation-tool-${entry.$1.name}'),
                selected: _tool == entry.$1,
                avatar: Icon(entry.$2, size: 17),
                label: Text(entry.$3),
                onSelected: widget.enabled ? (_) => _setTool(entry.$1) : null,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final feature in [
              ('bathroom', Icons.wc, 'Restroom'),
              ('elevator', Icons.elevator_outlined, 'Elevator'),
              ('stairs', Icons.stairs_outlined, 'Stairs'),
            ])
              OutlinedButton.icon(
                key: Key('annotation-add-${feature.$1}'),
                onPressed: widget.enabled
                    ? () => _startFeature(feature.$1)
                    : null,
                icon: Icon(feature.$2),
                label: Text(feature.$3),
              ),
          ],
        ),
        if (_tool == AnnotationTool.room)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: DropdownButtonFormField<String>(
              key: ValueKey('new-category-$_newRoomCategory'),
              initialValue: _newRoomCategory,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category for new box',
              ),
              items: [
                for (final category in annotationCategories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(categoryLabel(category)),
                  ),
              ],
              onChanged: widget.enabled
                  ? (value) => setState(() => _newRoomCategory = value!)
                  : null,
            ),
          ),
        const SizedBox(height: 10),
        if (_tool == AnnotationTool.door)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              key: ValueKey('door-room-$_doorRoom'),
              initialValue: _doorRoom,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Room for new door'),
              items: [
                for (final room in rooms)
                  DropdownMenuItem(
                    value: room['id'] as String,
                    child: Text('${room['label']} (${room['id']})'),
                  ),
              ],
              onChanged: widget.enabled
                  ? (value) => setState(() => _doorRoom = value)
                  : null,
            ),
          ),
        Text(instruction, style: const TextStyle(fontSize: 13)),
        if (!widget.enabled)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Drawing is paused while a job runs or JSON changes await Apply.',
              style: TextStyle(color: Colors.deepOrange),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              key: const Key('annotation-error'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 440,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fit = applyBoxFit(
                BoxFit.contain,
                Size(document.width, document.height),
                Size(constraints.maxWidth, 440),
              ).destination;
              _canvasSize = fit;
              var vertices = s == null ? <Offset>[] : document.vertices(s);
              Map<String, dynamic>? previewRoom = s?.group == 'rooms'
                  ? document.selected
                  : null;
              if (_rotating &&
                  _rotationPreview != null &&
                  previewRoom != null) {
                previewRoom = {
                  ...previewRoom,
                  'rotation_deg': _rotationPreview,
                };
                vertices = roomVertices(previewRoom);
              } else if (_dragging &&
                  _dragPoint != null &&
                  _handle != null &&
                  _tool == AnnotationTool.select) {
                if (s?.group == 'rooms') {
                  previewRoom = {
                    ...previewRoom!,
                    'bbox': resizedRoomBox(previewRoom, _handle!, _dragPoint!),
                  };
                  vertices = roomVertices(previewRoom);
                } else {
                  vertices[_handle!] = _dragPoint!;
                }
              }
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xfff0f0f5),
                  border: Border.all(color: const Color(0xffdedde8)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: InteractiveViewer(
                    transformationController: _transform,
                    panEnabled: widget.enabled && _tool == AnnotationTool.pan,
                    scaleEnabled: widget.enabled,
                    minScale: 1,
                    maxScale: 8,
                    boundaryMargin: const EdgeInsets.all(200),
                    child: KeyboardListener(
                      focusNode: _focus,
                      onKeyEvent: _key,
                      child: MouseRegion(
                        cursor: widget.enabled
                            ? (_tool == AnnotationTool.pan
                                  ? SystemMouseCursors.grab
                                  : SystemMouseCursors.precise)
                            : SystemMouseCursors.basic,
                        onHover: (event) {
                          if (mounted)
                            setState(
                              () => _cursor = _pixel(event.localPosition),
                            );
                        },
                        child: Listener(
                          key: const Key('annotation-canvas'),
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: _pointerDown,
                          onPointerMove: _pointerMove,
                          onPointerUp: _pointerUp,
                          onPointerCancel: _pointerCancel,
                          child: SizedBox(
                            width: fit.width,
                            height: fit.height,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(widget.image, fit: BoxFit.fill),
                                CustomPaint(
                                  painter: _AnnotationPainter(
                                    data,
                                    s,
                                    vertices,
                                    _draft,
                                    drawingRoom:
                                        _tool == AnnotationTool.room &&
                                            _dragging &&
                                            _panOrigin != null &&
                                            _dragPoint != null
                                        ? Rect.fromPoints(
                                            _panOrigin!,
                                            _dragPoint!,
                                          )
                                        : null,
                                    cursor: _cursor,
                                    drawingPolygon: {
                                      AnnotationTool.wall,
                                      AnnotationTool.walkable,
                                    }.contains(_tool),
                                    zoom: _zoom,
                                    rotationHandle: previewRoom == null
                                        ? null
                                        : roomRotationHandle(
                                            previewRoom,
                                            _tolerance * 2.2,
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
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${document.width.toInt()} × ${document.height.toInt()} px${_cursor == null ? '' : ' · x ${_cursor!.dx.toStringAsFixed(1)}, y ${_cursor!.dy.toStringAsFixed(1)}'}',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            IconButton(
              tooltip: 'Zoom in',
              onPressed: () => _changeZoom(1.5),
              icon: const Icon(Icons.add),
            ),
            IconButton(
              tooltip: 'Zoom out',
              onPressed: () => _changeZoom(1 / 1.5),
              icon: const Icon(Icons.remove),
            ),
            TextButton(
              onPressed: () =>
                  setState(() => _transform.value = Matrix4.identity()),
              child: const Text('Fit'),
            ),
            OutlinedButton.icon(
              key: const Key('annotation-undo'),
              onPressed:
                  widget.enabled && (document.canUndo || _draft.isNotEmpty)
                  ? () {
                      if (_draft.isNotEmpty) {
                        setState(() => _draft.removeLast());
                      } else {
                        document.undo();
                      }
                    }
                  : null,
              icon: const Icon(Icons.undo),
              label: const Text('Undo'),
            ),
            OutlinedButton.icon(
              onPressed: widget.enabled && document.canRedo && _draft.isEmpty
                  ? document.redo
                  : null,
              icon: const Icon(Icons.redo),
              label: const Text('Redo'),
            ),
            if ({
              AnnotationTool.wall,
              AnnotationTool.walkable,
            }.contains(_tool)) ...[
              FilledButton(
                key: const Key('finish-polygon'),
                onPressed: widget.enabled && _draft.length >= 3
                    ? _finish
                    : null,
                child: Text('Finish polygon (${_draft.length})'),
              ),
              TextButton(
                onPressed: _draft.isNotEmpty ? _cancel : null,
                child: const Text('Cancel drawing'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('shape-${s?.group}-${s?.id}-${document.revision}'),
          isExpanded: true,
          initialValue: s == null ? null : '${s.group}/${s.id}',
          decoration: const InputDecoration(labelText: 'Select an annotation'),
          items: [
            for (final group in annotationGroups)
              for (final item in data[group] as List)
                DropdownMenuItem(
                  value: '$group/${item['id']}',
                  child: Text('$group · ${item['label'] ?? item['id']}'),
                ),
          ],
          onChanged: widget.enabled
              ? (value) {
                  if (value != null) {
                    final parts = value.split('/');
                    document.select(AnnotationSelection(parts[0], parts[1]));
                    setState(() {
                      _handle = null;
                      _tool = AnnotationTool.select;
                      _draft.clear();
                    });
                  }
                }
              : null,
        ),
        if (s != null) ...[
          const SizedBox(height: 12),
          if (s.group == 'rooms')
            _RoomProperties(
              key: ValueKey(s.id),
              item: document.selected!,
              enabled: widget.enabled,
              onApply: (label, category) =>
                  _attempt(() => document.updateRoom(label, category)),
              onRotate: (degrees) =>
                  _attempt(() => document.rotateSelected(degrees)),
            ),
          if (s.group == 'doors')
            DropdownButtonFormField<String>(
              key: ValueKey('door-${s.id}-${document.selected!['room_id']}'),
              initialValue: document.selected!['room_id'] as String,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Door belongs to room',
              ),
              items: [
                for (final room in rooms)
                  DropdownMenuItem(
                    value: room['id'] as String,
                    child: Text('${room['label']} (${room['id']})'),
                  ),
              ],
              onChanged: widget.enabled
                  ? (value) => _attempt(() => document.updateDoorRoom(value!))
                  : null,
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (polygon) ...[
                TextButton(
                  onPressed: widget.enabled && _handle != null
                      ? () => _attempt(() {
                          document.insertVertex(_handle!);
                          _handle = _handle! + 1;
                        })
                      : null,
                  child: const Text('Insert vertex after handle'),
                ),
                TextButton(
                  onPressed:
                      widget.enabled &&
                          _handle != null &&
                          document.vertices(s).length > 3
                      ? () => _attempt(() {
                          document.removeVertex(_handle!);
                          _handle = null;
                        })
                      : null,
                  child: const Text('Remove vertex'),
                ),
              ],
              TextButton.icon(
                key: const Key('delete-annotation'),
                onPressed: widget.enabled
                    ? () {
                        document.deleteSelected();
                        setState(() => _handle = null);
                      }
                    : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete shape'),
              ),
            ],
          ),
          if (s.group == 'rooms')
            const Text(
              'Deleting a room also removes its linked doors. Undo restores them.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
        ],
      ],
    );
  }
}

class _RoomProperties extends StatefulWidget {
  const _RoomProperties({
    super.key,
    required this.item,
    required this.enabled,
    required this.onApply,
    required this.onRotate,
  });
  final Map<String, dynamic> item;
  final bool enabled;
  final void Function(String, String) onApply;
  final ValueChanged<double> onRotate;
  @override
  State<_RoomProperties> createState() => _RoomPropertiesState();
}

class _RoomPropertiesState extends State<_RoomProperties> {
  late final _label = TextEditingController(
    text: widget.item['label'] as String,
  );
  late String _category = widget.item['category'] as String;
  late final _rotation = TextEditingController(
    text: (widget.item['rotation_deg'] as num? ?? 0).toStringAsFixed(1),
  );
  @override
  void didUpdateWidget(_RoomProperties oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item['label'] != widget.item['label'])
      _label.text = widget.item['label'] as String;
    if (oldWidget.item['category'] != widget.item['category'])
      _category = widget.item['category'] as String;
    if (oldWidget.item['rotation_deg'] != widget.item['rotation_deg'])
      _rotation.text = (widget.item['rotation_deg'] as num? ?? 0)
          .toStringAsFixed(1);
  }

  @override
  void dispose() {
    _label.dispose();
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        key: const Key('annotation-room-label'),
        controller: _label,
        enabled: widget.enabled,
        decoration: const InputDecoration(labelText: 'Room / feature label'),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _category,
        key: ValueKey(_category),
        decoration: const InputDecoration(labelText: 'Place category'),
        items: [
          for (final value in annotationCategories)
            DropdownMenuItem(value: value, child: Text(categoryLabel(value))),
        ],
        onChanged: widget.enabled
            ? (value) => setState(() => _category = value!)
            : null,
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: widget.enabled
              ? () => widget.onApply(_label.text, _category)
              : null,
          child: const Text('Apply room label'),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('annotation-rotation'),
        controller: _rotation,
        enabled: widget.enabled,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        decoration: const InputDecoration(
          labelText: 'Rotation · degrees clockwise',
          helperText:
              '0° is horizontal. Drag the round rotation handle or enter an angle.',
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: widget.enabled
              ? () {
                  final angle = double.tryParse(_rotation.text);
                  if (angle == null || !angle.isFinite) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a finite rotation angle.'),
                      ),
                    );
                    return;
                  }
                  widget.onRotate(angle);
                }
              : null,
          child: const Text('Apply rotation'),
        ),
      ),
    ],
  );
}

class _AnnotationPainter extends CustomPainter {
  _AnnotationPainter(
    this.data,
    this.selection,
    this.handles,
    this.draft, {
    this.drawingRoom,
    this.rotationHandle,
    this.cursor,
    required this.drawingPolygon,
    required this.zoom,
  });
  final Map<String, dynamic> data;
  final AnnotationSelection? selection;
  final List<Offset> handles, draft;
  final Rect? drawingRoom;
  final Offset? rotationHandle;
  final Offset? cursor;
  final bool drawingPolygon;
  final double zoom;
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / (data['width'] as num),
        sy = size.height / (data['height'] as num);
    Offset screen(Offset p) => Offset(p.dx * sx, p.dy * sy);
    Offset point(dynamic raw) =>
        Offset((raw[0] as num).toDouble(), (raw[1] as num).toDouble());
    for (final group in ['walkable_areas', 'rooms', 'walls', 'doors']) {
      final color = switch (group) {
        'walls' => Colors.red,
        'walkable_areas' => Colors.teal,
        'doors' => Colors.green,
        _ => const Color(0xff6655d6),
      };
      for (final item in data[group] as List) {
        final selected =
            selection?.group == group && selection?.id == item['id'];
        List<Offset> points;
        if (selected) {
          points = handles;
        } else if (group == 'rooms') {
          points = roomVertices(Map<String, dynamic>.from(item));
        } else if (group == 'doors') {
          points = [point(item['point'])];
        } else {
          points = [for (final p in item['polygon'] as List) point(p)];
        }
        if (group == 'doors') {
          canvas.drawCircle(
            screen(points.first),
            5 / zoom,
            Paint()..color = color,
          );
        } else {
          final path = Path()..addPolygon(points.map(screen).toList(), true);
          canvas.drawPath(
            path,
            Paint()..color = color.withValues(alpha: selected ? .25 : .12),
          );
          canvas.drawPath(
            path,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = (selected ? 2.5 : 1.3) / zoom,
          );
          if (group == 'rooms') {
            final text = TextPainter(
              text: TextSpan(
                text: item['label'] as String,
                style: TextStyle(
                  fontSize: 11 / zoom,
                  color: color,
                  backgroundColor: Colors.white,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: size.width);
            text.paint(canvas, screen(points.first));
          }
        }
      }
    }
    for (final p in handles) {
      canvas.drawCircle(screen(p), 6 / zoom, Paint()..color = Colors.white);
      canvas.drawCircle(
        screen(p),
        6 / zoom,
        Paint()
          ..color = const Color(0xff6655d6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / zoom,
      );
    }
    if (rotationHandle != null && handles.length == 4) {
      final handle = screen(rotationHandle!),
          top = screen((handles[0] + handles[1]) / 2);
      canvas.drawLine(
        top,
        handle,
        Paint()
          ..color = const Color(0xff6655d6)
          ..strokeWidth = 1.5 / zoom,
      );
      canvas.drawCircle(handle, 8 / zoom, Paint()..color = Colors.white);
      canvas.drawCircle(
        handle,
        8 / zoom,
        Paint()
          ..color = const Color(0xff6655d6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / zoom,
      );
    }
    if (draft.isNotEmpty) {
      final points = draft.map(screen).toList();
      final path = Path()..addPolygon(points, false);
      if (cursor != null && drawingPolygon)
        path.lineTo(screen(cursor!).dx, screen(cursor!).dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / zoom,
      );
      for (final p in points) {
        canvas.drawCircle(p, 4 / zoom, Paint()..color = Colors.orange);
      }
      canvas.drawCircle(
        points.first,
        8 / zoom,
        Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 / zoom,
      );
    }
    if (drawingRoom != null)
      canvas.drawRect(
        Rect.fromPoints(
          screen(drawingRoom!.topLeft),
          screen(drawingRoom!.bottomRight),
        ),
        Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / zoom,
      );
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}
