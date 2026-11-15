import 'dart:convert';
import 'package:flutter/material.dart';
import '../features/navigation/place_maps.dart';
import 'room_amenity_map_screen.dart';

class SavedPlaceMapScreen extends StatefulWidget {
  const SavedPlaceMapScreen({
    super.key,
    required this.api,
    required this.mapId,
    this.destinationId,
    this.embedded = false,
    this.onDestinationSelected,
    this.onSaved,
  });
  final PlaceMapsApi api;
  final String mapId;
  final String? destinationId;
  final bool embedded;
  final ValueChanged<String>? onDestinationSelected;
  final VoidCallback? onSaved;
  @override
  State<SavedPlaceMapScreen> createState() => _SavedPlaceMapScreenState();
}

class _SavedPlaceMapScreenState extends State<SavedPlaceMapScreen> {
  late Future<SavedPlaceMap> _map = widget.api.get(widget.mapId);
  late String? _selected = widget.destinationId;
  final _transform = TransformationController();
  final _viewportKey = GlobalKey();
  @override
  void didUpdateWidget(covariant SavedPlaceMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapId != widget.mapId) {
      _map = widget.api.get(widget.mapId);
      _transform.value = Matrix4.identity();
    }
    if (oldWidget.destinationId != widget.destinationId) {
      _selected = widget.destinationId;
    }
  }

  void _select(String id) {
    setState(() => _selected = id);
    widget.onDestinationSelected?.call(id);
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final size =
        (_viewportKey.currentContext!.findRenderObject()! as RenderBox).size;
    final old = _transform.value, scale = _transform.value.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(1.0, 6.0), ratio = next / scale;
    final center = size.center(Offset.zero);
    _transform.value = Matrix4.identity()
      ..setEntry(0, 0, next)
      ..setEntry(1, 1, next)
      ..setEntry(
        0,
        3,
        (center.dx + (old.storage[12] - center.dx) * ratio).clamp(
          size.width * (1 - next),
          0.0,
        ),
      )
      ..setEntry(
        1,
        3,
        (center.dy + (old.storage[13] - center.dy) * ratio).clamp(
          size.height * (1 - next),
          0.0,
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.embedded
        ? null
        : AppBar(title: const Text('Destination map')),
    body: FutureBuilder<SavedPlaceMap>(
      future: _map,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load this map.'),
                TextButton(
                  onPressed: () => setState(() {
                    _map = widget.api.get(widget.mapId);
                  }),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final map = snapshot.data!;
        final document = jsonDecode(map.mapJson!) as Map<String, dynamic>;
        final pins = map.places;
        final selected = pins
            .where((p) => map.destinationId(p['id'] as String) == _selected)
            .firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                '${map.buildingName} · ${map.floorLabel}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Zoom in',
                    onPressed: () => _zoom(1.25),
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: 'Zoom out',
                    onPressed: () => _zoom(1 / 1.25),
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    tooltip: 'Fit map',
                    onPressed: () => _transform.value = Matrix4.identity(),
                    icon: const Icon(Icons.fit_screen),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit map'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => RoomAmenityMapScreen(
                            placeMapsApi: widget.api,
                            initialMap: map,
                            onSaved: widget.onSaved,
                          ),
                        ),
                      );
                      if (mounted)
                        setState(() => _map = widget.api.get(widget.mapId));
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRect(
                child: InteractiveViewer(
                  key: _viewportKey,
                  transformationController: _transform,
                  scaleEnabled: false,
                  minScale: 1,
                  maxScale: 6,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio:
                          (document['width'] as num) /
                          (document['height'] as num),
                      child: LayoutBuilder(
                        builder: (context, bounds) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Image.memory(
                                base64Decode(
                                  document['image_base64'] as String,
                                ),
                                fit: BoxFit.fill,
                              ),
                            ),
                            for (var i = 0; i < pins.length; i++)
                              Positioned(
                                left:
                                    (pins[i]['x'] as num) /
                                        (document['width'] as num) *
                                        bounds.maxWidth -
                                    16,
                                top:
                                    (pins[i]['y'] as num) /
                                        (document['height'] as num) *
                                        bounds.maxHeight -
                                    16,
                                child: Tooltip(
                                  message: pins[i]['label'] as String,
                                  child: GestureDetector(
                                    key: ValueKey(
                                      'destination-pin-${pins[i]['id']}',
                                    ),
                                    onTap: () => _select(
                                      map.destinationId(
                                        pins[i]['id'] as String,
                                      ),
                                    ),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            map.destinationId(
                                                  pins[i]['id'] as String,
                                                ) ==
                                                _selected
                                            ? Colors.deepOrange
                                            : Colors.indigo,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        '${i + 1}',
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
            if (selected != null)
              ListTile(
                leading: const Icon(Icons.place, color: Colors.deepOrange),
                title: Text(selected['label'] as String),
                subtitle: Text('${map.buildingName} · ${map.floorLabel}'),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Rooms and amenities map. Walking directions are not mapped for this floor yet.',
              ),
            ),
          ],
        );
      },
    ),
  );
}
