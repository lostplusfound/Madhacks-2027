import 'dart:math' as math;
import 'dart:async';
import '../shell/navigation_session.dart';
import '../shell/app_state.dart';
import '../shell/name_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
import 'ar_adapter.dart';
import 'cloud_anchor_config.dart';
import 'map_data.dart';
import 'scan_guidance.dart';
import 'localization_controller.dart';
import '../navigation/floor_data.dart';
import '../navigation/map_repository.dart';
import '../navigation/floor_screen.dart';
import '../navigation/routing.dart';
import '../navigation/navigation_panel.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key, this.graph});
  final FloorGraph? graph;
  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final store = MapStore();
  List<AnchorMap>? maps;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final value = await store.load();
      if (mounted) {
        setState(() {
          maps = value;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Could not read saved maps: $e');
    }
  }

  Future<void> save() async {
    await store.save(maps!);
    if (mounted) setState(() {});
  }

  Future<void> guarded(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MadMaps • AR maps')),
    body: error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error!),
                TextButton(onPressed: load, child: const Text('Retry')),
              ],
            ),
          )
        : maps == null
        ? const Center(child: CircularProgressIndicator())
        : maps!.isEmpty
        ? const Center(
            child: Text(
              'Create a map, then tap a surface\nto place your first anchor.',
              textAlign: TextAlign.center,
            ),
          )
        : ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'New Cloud Anchors last $cloudAnchorTtlDays days. Internet is required.\nMap records stay on this phone.',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.my_location),
                  label: const Text('Find my location'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => MapSessionScreen(
                        maps: maps!,
                        save: save,
                        graph: widget.graph,
                      ),
                    ),
                  ),
                ),
              ),
              for (final map in maps!)
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(map.name),
                  subtitle: Text('${map.anchors.length} anchors'),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => MapSessionScreen(
                          map: map,
                          save: save,
                          graph: widget.graph,
                        ),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => guarded(() async {
                      if (value == 'floor') {
                        final graph =
                            widget.graph ?? await ServerMapRepository().load();
                        if (!context.mounted) return;
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => FloorSetupScreen(
                              map: map,
                              graph: graph,
                              save: save,
                            ),
                          ),
                        );
                        return;
                      }
                      if (value == 'rename') {
                        final name = await askName(
                          context,
                          'Rename map',
                          map.name,
                        );
                        if (name == null) return;
                        map.name = name;
                      } else {
                        maps!.remove(map);
                      }
                      await save();
                    }),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'floor',
                        child: Text('Floor 1 setup'),
                      ),
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete local map'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
    floatingActionButton: maps == null
        ? null
        : FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Create map'),
            onPressed: () => guarded(() async {
              final name = await askName(context, 'Create map');
              if (name == null) return;
              maps!.add(
                AnchorMap(
                  DateTime.now().microsecondsSinceEpoch.toString(),
                  name,
                  [],
                ),
              );
              await save();
            }),
          ),
  );
}

class MapSessionScreen extends StatefulWidget {
  const MapSessionScreen({
    super.key,
    this.map,
    this.maps = const [],
    this.adapter,
    this.session,
    this.appState,
    this.graph,
    required this.save,
  });

  /// Optional injected adapter is owned and disposed by this screen.
  final ArAdapter? adapter;
  final NavigationSession? session;
  final AppState? appState;
  final FloorGraph? graph;
  final AnchorMap? map;
  final List<AnchorMap> maps;
  final Future<void> Function() save;
  @override
  State<MapSessionScreen> createState() => _MapSessionScreenState();
}

class _MapSessionScreenState extends State<MapSessionScreen>
    with WidgetsBindingObserver {
  late final ArAdapter ar;
  late final LocalizationController localization;
  ARPlaneAnchor? nativeDraft;
  late AnchorMap map;
  bool identified = false;
  bool ready = false;
  String? discoveryMessage;
  AnchorMap? _recoveryMap;
  bool _autoDiscovery = false;
  Timer? _discoveryRetry;
  List<AnchorMap> get catalog => _recoveryMap != null
      ? [_recoveryMap!]
      : widget.maps.isEmpty
      ? [map]
      : widget.maps;

  void queueDiscovery([Duration delay = LocalizationTuning.refreshAfter]) {
    _discoveryRetry?.cancel();
    _discoveryRetry = null;
    if (!_autoDiscovery || !active) return;
    _discoveryRetry = Timer(delay, () {
      _discoveryRetry = null;
      if (!mounted ||
          !_autoDiscovery ||
          !active ||
          localization.nativeReference != null) {
        return;
      }
      if (!ready ||
          busy ||
          placing ||
          draftPose != null ||
          localization.refreshing) {
        queueDiscovery(const Duration(seconds: 1));
        return;
      }
      unawaited(discover(automatic: true));
    });
  }

  Future<void> discover({bool automatic = false}) async {
    if (busy || !active || !ready || localization.refreshing) return;
    _autoDiscovery = true;
    _discoveryRetry?.cancel();
    _discoveryRetry = null;
    if (localization.nativeReference != null &&
        localization.alignment != null) {
      updateState(() => discoveryMessage = null);
      await localization.refresh(explicit: true);
      return;
    }
    final candidates = liveAnchorCandidates(catalog);
    if (candidates.isEmpty) {
      updateState(
        () => discoveryMessage =
            'No live anchors saved. Create a map and save an anchor, or use a map with unexpired anchors.',
      );
      return;
    }
    localization.invalidate();
    final current = ++generation;
    updateState(() {
      busy = true;
      placing = false;
      draftPose = null;
      mapFromSession = null;
      identified = false;
      discoveryMessage =
          'Scan your surroundings slowly. Searching ${candidates.length} saved anchors...';
    });
    try {
      ARAnchor? found;
      final ids = candidates.keys.toList();
      for (var start = 0; start < ids.length; start += 20) {
        if (!mounted || !active || current != generation) return;
        try {
          found = await ar.resolveAny(
            ids.skip(start).take(20).toList(),
            retain: true,
            timeout: automatic ? LocalizationTuning.batchTimeout : null,
          );
          break;
        } catch (_) {
          if (current != generation || start + 20 >= ids.length) rethrow;
        }
      }
      final resolved = found!;
      if (!mounted || !active || current != generation) {
        await ar.release(resolved);
        return;
      }
      final cloudId = (resolved as ARPlaneAnchor).cloudanchorid;
      final match = candidates[cloudId];
      if (match == null) {
        throw StateError('Resolved anchor is not in this catalog');
      }
      await localization.adopt(
        match.map,
        match.anchor,
        resolved,
        match.alignment(resolved.transformation),
      );
      if (!mounted || !active || current != generation) return;
      updateState(() {
        if (map.id != match.map.id) {
          destination = null;
          roomName = null;
          guidance.target = null;
          guidance.reset();
          navigationMapId = null;
        }
        map = match.map;
        _recoveryMap = match.map;
        mapFromSession = match.alignment(resolved.transformation);
        identified = true;
        discoveryMessage = null;
      });
    } catch (error) {
      if (mounted && current == generation) {
        updateState(
          () => discoveryMessage = error is TimeoutException
              ? 'No anchor found. Retrying automatically; scan near a saved anchor.'
              : 'Could not localize: $error. Retrying automatically; check internet and scan nearby.',
        );
      }
    } finally {
      if (mounted && current == generation) updateState(() => busy = false);
    }
  }

  void cancelSearch() {
    _autoDiscovery = false;
    _discoveryRetry?.cancel();
    _discoveryRetry = null;
    generation++;
    unawaited(ar.cancelDiscovery());
    updateState(() {
      busy = false;
      discoveryMessage = 'Search cancelled. Tap Find my location to try again.';
    });
  }

  Matrix4? get mapFromSession => localization.alignment;
  set mapFromSession(Matrix4? value) => localization.alignment = value;
  Matrix4? draftPose;
  final scan = ScanGuidance();
  SavedAnchor? destination;
  FloorGraph? floorGraph;
  String? floorError, roomName;
  final guidance = GuidanceState(
    onDiagnostic: kDebugMode ? (message) => debugPrint(message) : null,
  );
  DateTime? navigationFix;
  String? navigationMapId;

  Future<void> loadFloor() async {
    try {
      final graph = widget.graph ?? await ServerMapRepository().load();
      if (mounted) setState(() => floorGraph = graph);
    } catch (e) {
      if (mounted) setState(() => floorError = 'Map data unavailable: $e');
    }
  }

  Future<void> openFloorSetup() async {
    if (floorGraph == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(floorError ?? 'Loading floor data…')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            FloorSetupScreen(map: map, graph: floorGraph!, save: widget.save),
      ),
    );
    guidance.reset();
    refresh();
  }

  int appliedRevision = -1;
  String? appliedMap;
  void requestChanged() {
    if (mounted && widget.session?.revision != appliedRevision) setState(() {});
  }

  void cancelTrip() {
    if (!mounted) return;
    updateState(() {
      roomName = null;
      destination = null;
      guidance.target = null;
      guidance.reset();
    });
  }

  void selectLocation(FloorLocation location) {
    final node = map.floor.locationNodes[location.id] ?? location.node;
    if (node == null || map.floor.calibration(map) == null) return;
    widget.session?.choose(location);
    updateState(() {
      destination = null;
      roomName = widget.appState?.label(location) ?? location.label;
      navigationMapId = map.id;
      guidance.select(node);
    });
  }

  Future<void> showRooms() async {
    if (floorGraph == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(floorError ?? 'Loading floor data…')),
      );
      return;
    }
    var search = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, rebuild) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .75,
            child: Column(
              children: [
                const ListTile(
                  title: Text('Floor 1 destinations • draft'),
                  subtitle: Text('Other floors are not supported yet.'),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search rooms or amenities',
                    ),
                    onChanged: (v) => rebuild(() => search = v.toLowerCase()),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final l in floorGraph!.locations.where(
                        (l) => '${l.label} ${l.aliases} ${l.id}'
                            .toLowerCase()
                            .contains(search),
                      ))
                        ListTile(
                          title: Text(l.label),
                          subtitle: Text(
                            (map.floor.locationNodes[l.id] ?? l.node) == null
                                ? 'Not mapped yet'
                                : map.floor.calibration(map) == null
                                ? 'Set up floor calibration first'
                                : 'Navigate to entrance',
                          ),
                          enabled:
                              (map.floor.locationNodes[l.id] ?? l.node) !=
                                  null &&
                              map.floor.calibration(map) != null,
                          onTap: () {
                            Navigator.pop(sheet);
                            selectLocation(l);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void updateGuidance() {
    final session = widget.session;
    final requested = session?.destination;
    if (session != null &&
        requested != null &&
        floorGraph != null &&
        map.floor.enabled &&
        map.floor.calibration(map) != null &&
        (appliedRevision != session.revision || appliedMap != map.id)) {
      appliedRevision = session.revision;
      appliedMap = map.id;
      final node = map.floor.locationNodes[requested.id] ?? requested.node;
      destination = null;
      roomName = widget.appState?.label(requested) ?? requested.label;
      navigationMapId = map.id;
      guidance.select(node ?? '');
    }
    if (navigationMapId != null && navigationMapId != map.id) {
      guidance.target = null;
      guidance.reset();
      roomName = null;
      destination = null;
    }
    final graph = floorGraph;
    if (graph == null) return;
    final calibration = map.floor.calibration(map), pose = camera;
    final relocalized = navigationFix != localization.lastConfirmed;
    navigationFix = localization.lastConfirmed;
    guidance.update(
      graph,
      map.floor,
      calibration,
      pose == null || calibration == null
          ? null
          : calibration.toImage(Offset(pose.entry(0, 3), pose.entry(2, 3))),
      DateTime.now(),
      relocalized: relocalized,
    );
    if (requested != null &&
        (map.floor.locationNodes[requested.id] ?? requested.node) == null) {
      guidance.status =
          'This destination has no mapped entrance yet. Choose another destination.';
    }
    if (session != null) {
      final revision = session.revision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || session.revision != revision) return;
        if (session.update(guidance, tracking: camera != null)) {
          final place = session.destination;
          if (place != null) {
            widget.appState?.recordVisit(place.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You have arrived near the entrance.'),
              ),
            );
          }
        }
      });
    }
  }

  bool busy = false, placing = false, expanded = false, active = true;
  bool arExpanded = false;
  String? operation;
  int generation = 0;
  Matrix4? get camera => active && ar.tracking ? localization.camera : null;

  void syncLocalizationMode() {
    localization.mapping = placing || draftPose != null;
    localization.suspended = busy || !active;
    if (_autoDiscovery &&
        active &&
        ready &&
        !busy &&
        !placing &&
        draftPose == null &&
        localization.nativeReference == null &&
        _discoveryRetry == null) {
      queueDiscovery();
    }
  }

  void updateState(VoidCallback change) {
    if (!mounted) return;
    setState(() {
      change();
      syncLocalizationMode();
    });
  }

  void discardDraft() {
    final draft = nativeDraft;
    nativeDraft = null;
    draftPose = null;
    if (draft != null) unawaited(ar.release(draft));
  }

  Future<void> beginPlacement() async {
    if (placing) {
      updateState(() => placing = false);
      return;
    }
    if (map.anchors.isNotEmpty && !localization.mappingRecommended) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location may have drifted. You can keep mapping; refreshing near a saved anchor is recommended.',
          ),
        ),
      );
    }
    updateState(() => placing = true);
    await ar.cancelDiscovery();
  }

  @override
  void initState() {
    super.initState();
    widget.session?.attached = true;
    widget.session?.onCancel = cancelTrip;
    widget.session?.addListener(requestChanged);
    widget.appState?.addListener(refresh);
    ar = widget.adapter ?? ArAdapter();
    localization = LocalizationController(ar)
      ..addListener(refresh)
      ..start();
    ready = ar.session != null;
    map = widget.map ?? AnchorMap('discovery', 'Find my location', []);
    loadFloor();
    identified = widget.map != null;
    _recoveryMap = widget.map;
    _autoDiscovery = widget.map == null || map.floor.enabled;
    if (_autoDiscovery) queueDiscovery(Duration.zero);
    if (ready && map.floor.enabled && map.anchors.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && active) unawaited(discover(automatic: true));
      });
    }
    WidgetsBinding.instance.addObserver(this);
    ar.addListener(refresh);
    ar.onTap = (hits) async {
      if (!placing || busy || !ar.tracking || !active) return;
      final planes = hits.where((h) => h.type == ARHitTestResultType.plane);
      if (planes.isEmpty) return;
      final pose = planes.first.worldTransform;
      if (map.anchors.isNotEmpty && !localization.placementRecommended(pose)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This placement may be less accurate. You can continue; refreshing near a saved anchor is recommended.',
            ),
          ),
        );
      }
      final current = generation;
      updateState(() => busy = true);
      try {
        final draft = await ar.createDraft(pose);
        if (!mounted || !active || current != generation) {
          await ar.release(draft);
          return;
        }
        updateState(() {
          nativeDraft = draft;
          placing = false;
          expanded = false;
          draftPose = pose.clone();
          scan.reset(pose.getTranslation());
        });
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not place anchor: $error')),
          );
        }
      } finally {
        if (mounted) updateState(() => busy = false);
      }
    };
  }

  Future<void> saveDraft() async {
    final draft = draftPose;
    if (draft == null || busy || !active || !ar.tracking) return;
    final tappedGeneration = generation;
    updateState(() => busy = true);
    final name = await askName(context, 'Save anchor');
    if (!mounted) return;
    if (name == null) {
      updateState(() => busy = false);
      return;
    }
    await runOperation(
      'Saving anchor to cloud? Keep the area in view.',
      () async {
        if (!active || tappedGeneration != generation) {
          throw StateError('Session interrupted; localize again');
        }
        final hosted = await ar.host(draft, existing: nativeDraft);
        if (!mounted || !active || tappedGeneration != generation) {
          throw StateError('Session interrupted; reopen the map');
        }
        final snapshot = await ar.captureFrame([
          hosted.name,
          if (localization.nativeReference != null)
            localization.nativeReference!.name,
        ]);
        final hostedSample = snapshot?.anchors[hosted.name];
        if (snapshot == null ||
            !snapshot.tracking ||
            hostedSample == null ||
            !hostedSample.tracking) {
          throw StateError(
            'Tracking unavailable after hosting; scan and retry',
          );
        }
        final hostedPose = hostedSample.pose;
        final frame = map.anchors.isEmpty
            ? Matrix4.translationValues(
                -hostedPose.entry(0, 3),
                -hostedPose.entry(1, 3),
                -hostedPose.entry(2, 3),
              )
            : (localization.alignmentFor(snapshot) ?? mapFromSession?.clone());
        if (frame == null) {
          throw StateError(
            'No map alignment available; localize once before extending this map',
          );
        }
        if (!mounted || !active || tappedGeneration != generation) {
          await ar.release(hosted);
          return;
        }
        final anchor = SavedAnchor(
          hosted.name,
          name,
          hosted.cloudanchorid!,
          frame * hostedPose,
          DateTime.now().add(cloudAnchorLifetime),
        );
        map.anchors.add(anchor);
        try {
          await widget.save();
        } catch (_) {
          map.anchors.remove(anchor);
          rethrow;
        }
        if (!mounted || !active || tappedGeneration != generation) {
          await ar.release(hosted);
          return;
        }
        await localization.adopt(map, anchor, hosted, frame);
        if (!mounted || !active || tappedGeneration != generation) return;
        nativeDraft = null;
        mapFromSession = frame;
        draftPose = null;
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved anchor: $name')));
        }
      },
    );
  }

  void refresh() {
    syncLocalizationMode();
    updateGuidance();
    if (draftPose != null && active && ar.tracking && ar.camera != null) {
      scan.sample(ar.camera!.getTranslation());
    }
    if (mounted) updateState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (!active) {
      _discoveryRetry?.cancel();
      _discoveryRetry = null;
      if (localization.nativeReference != null) {
        _recoveryMap = map;
        _autoDiscovery = true;
      }
      localization.invalidate();
      placing = false;
      discardDraft();
      generation++;
      unawaited(ar.cancelOperations());
      busy = false;
      operation = null;
      discoveryMessage = _autoDiscovery
          ? 'Tracking lost - relocalizing automatically.'
          : 'Search cancelled. Tap Locate to try again.';
    } else if (_autoDiscovery) {
      queueDiscovery(Duration.zero);
    }
    refresh();
  }

  Future<void> runOperation(
    String message,
    Future<void> Function() action,
  ) async {
    final current = generation;
    localization.suspended = true;
    updateState(() {
      busy = true;
      operation = message;
    });
    try {
      await action();
      if (current != generation) return;
    } catch (e) {
      if (mounted && current == generation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Operation failed: $e. Check internet, ARCore credentials, expiry and scan quality.',
            ),
          ),
        );
      }
    } finally {
      if (mounted && current == generation) {
        updateState(() {
          busy = false;
          operation = null;
        });
      }
    }
  }

  Future<void> resolve(SavedAnchor anchor) => runOperation(
    'Resolving ${anchor.name}: scan its surroundings…',
    () async {
      if (anchor.expired) throw StateError('Anchor expired');
      _autoDiscovery = true;
      _recoveryMap = map;
      final current = generation;
      final resolved = await ar.resolve(anchor.cloudId, retain: true);
      if (!mounted || !active || current != generation) {
        await ar.release(resolved);
        return;
      }
      await localization.adopt(
        map,
        anchor,
        resolved,
        alignMap(anchor.pose, resolved.transformation),
      );
      if (mounted && active && current == generation) discoveryMessage = null;
    },
  );
  Future<void> showAnchors() async {
    updateState(() => placing = false);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text('Anchors'),
              subtitle: Text('Tap a destination. Use its menu to localize.'),
            ),
            for (final a in map.anchors)
              ListTile(
                title: Text(a.name),
                subtitle: Text(
                  a.expired
                      ? 'Expired'
                      : 'Expires ${a.expiresAt.toLocal().toString().substring(0, 16)}',
                ),
                onTap: () {
                  Navigator.pop(sheet);
                  updateState(() {
                    destination = a;
                    roomName = null;
                    navigationMapId = map.id;
                    guidance.target = null;
                    guidance.reset();
                  });
                },
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    Navigator.pop(sheet);
                    if (value == 'resolve') {
                      await resolve(a);
                      return;
                    }
                    if (value == 'route') {
                      updateState(() {
                        destination = null;
                        roomName = a.name;
                        navigationMapId = map.id;
                        guidance.select(map.floor.anchorNodes[a.id]!);
                      });
                      return;
                    }
                    if (value == 'rename') {
                      final name = await askName(
                        context,
                        'Rename anchor',
                        a.name,
                      );
                      if (name == null) return;
                      a.name = name;
                    }
                    if (value == 'delete') {
                      map.anchors.remove(a);
                      map.floor.anchorPoints.remove(a.id);
                      map.floor.anchorNodes.remove(a.id);
                      if (map.floor.calibrationIds.contains(a.id)) {
                        map.floor.calibrationIds.clear();
                      }
                      if (localization.reference == a) {
                        localization.invalidate();
                      }
                      if (destination == a) destination = null;
                    }
                    if (!mounted) return;
                    await runOperation('Saving…', widget.save);
                  },
                  itemBuilder: (_) => [
                    if (map.floor.anchorNodes.containsKey(a.id) &&
                        map.floor.calibration(map) != null)
                      const PopupMenuItem(
                        value: 'route',
                        child: Text('Navigate via hallways'),
                      ),
                    if (!a.expired)
                      const PopupMenuItem(
                        value: 'resolve',
                        child: Text('Localize here'),
                      ),
                    const PopupMenuItem(value: 'rename', child: Text('Rename')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete locally'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    refresh();
  }

  @override
  void dispose() {
    widget.appState?.removeListener(refresh);
    widget.session?.removeListener(requestChanged);
    final session = widget.session;
    WidgetsBinding.instance.addPostFrameCallback((_) => session?.detach());
    _discoveryRetry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    ar.removeListener(refresh);
    discardDraft();
    localization.removeListener(refresh);
    localization.dispose();
    ar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supported =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final pose = camera, target = destination;
    updateGuidance();
    final calibration = map.floor.calibration(map);
    final distance = pose != null && target != null
        ? horizontalDistance(
            pose.getTranslation(),
            target.pose.getTranslation(),
          )
        : null;
    final mapFirst = map.floor.enabled && !placing && draftPose == null;
    final canPlace =
        supported &&
        identified &&
        active &&
        ar.tracking &&
        !busy &&
        (mapFromSession != null || map.anchors.isEmpty);
    return Scaffold(
      // Resizing the virtual-display AR view for the name keyboard destroys its
      // camera surfaces. Keep the native view size stable while dialogs type.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(identified ? map.name : 'Find my location'),
        actions: [
          if (mapFirst)
            PopupMenuButton<String>(
              tooltip: 'Mapping tools',
              onSelected: (value) {
                if (value == 'anchors') showAnchors();
                if (value == 'add') beginPlacement();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'anchors',
                  enabled: !busy,
                  child: const Text('Anchors'),
                ),
                PopupMenuItem(
                  value: 'add',
                  enabled: canPlace,
                  child: const Text('Add anchor'),
                ),
              ],
            ),
          if (identified || map.floor.enabled)
            IconButton(
              tooltip: 'Floor 1 setup',
              icon: const Icon(Icons.edit_location_alt),
              onPressed: busy || draftPose != null ? null : openFloorSetup,
            ),
          if (identified)
            IconButton(
              tooltip: 'Rooms',
              icon: const Icon(Icons.directions),
              onPressed: busy || draftPose != null ? null : showRooms,
            ),
          IconButton(
            tooltip: 'Find my location again',
            icon: const Icon(Icons.my_location),
            onPressed: busy || draftPose != null || !ready ? null : discover,
          ),
        ],
      ),
      body: supported
          ? Stack(
              children: [
                if (mapFirst && floorGraph != null)
                  Positioned.fill(
                    child: NavigationPanel(
                      graph: floorGraph!,
                      setup: map.floor,
                      pose: pose,
                      calibration: calibration,
                      guidance: guidance,
                      destination: roomName,
                      message: discoveryMessage ?? localization.status,
                      busy: busy,
                      estimated: localization.estimated,
                      onSearch: busy ? () {} : showRooms,
                      onNavigate: selectLocation,
                      onLocate: busy ? cancelSearch : discover,
                      onCancel: widget.session?.cancel ?? cancelTrip,
                      distanceLabel: widget.appState?.distance,
                    ),
                  ),
                Positioned(
                  key: const ValueKey('native-camera'),
                  top: mapFirst && !arExpanded ? 190 : 0,
                  right: mapFirst && !arExpanded ? 16 : 0,
                  left: mapFirst && !arExpanded ? null : 0,
                  bottom: mapFirst && !arExpanded ? null : 0,
                  width: mapFirst && !arExpanded ? 140 : null,
                  height: mapFirst && !arExpanded ? 170 : null,
                  child: ARView(
                    planeDetectionConfig:
                        PlaneDetectionConfig.horizontalAndVertical,
                    onARViewCreated: (s, o, a, l) async {
                      try {
                        await ar.attach(s, a);
                        if (!mounted) return;
                        updateState(() => ready = true);
                        if (mounted &&
                            active &&
                            (widget.map == null ||
                                (map.floor.enabled &&
                                    map.anchors.isNotEmpty))) {
                          await discover();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('AR initialization failed: $e'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                if (mapFirst)
                  Positioned(
                    right: 16,
                    top: 132,
                    child: IconButton.filled(
                      tooltip: arExpanded ? 'Collapse AR' : 'Expand AR',
                      onPressed: () =>
                          updateState(() => arExpanded = !arExpanded),
                      icon: Icon(
                        arExpanded
                            ? Icons.close_fullscreen
                            : Icons.open_in_full,
                      ),
                    ),
                  ),
                if (!mapFirst)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          discoveryMessage ??
                              (identified &&
                                      localization.nativeReference != null &&
                                      draftPose == null &&
                                      !placing &&
                                      operation == null
                                  ? '${ar.status}\n${localization.status}'
                                  : null) ??
                              (operation == null
                                  ? null
                                  : '$operation\n${ar.cloudStage ?? ""}') ??
                              (draftPose != null
                                  ? 'Anchor placed — scan, then press Save anchor.'
                                  : placing
                                  ? 'Tap a detected horizontal or vertical surface'
                                  : '${ar.status}\n${mapFromSession == null ? (map.anchors.isEmpty ? 'Place the first anchor to establish this map.' : 'Select Anchors → Localize here to align this map.') : 'Localized • Direct guidance ignores walls and obstacles.'}'),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                if (!mapFirst &&
                    identified &&
                    !busy &&
                    draftPose == null &&
                    !placing &&
                    localization.nativeReference != null)
                  Positioned(
                    top: 130,
                    left: 12,
                    right: 12,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: localization.refreshing
                              ? null
                              : () => localization.refresh(explicit: true),
                          child: const Text('Refresh location'),
                        ),
                      ],
                    ),
                  ),
                if (!identified)
                  Positioned(
                    top: 155,
                    left: 16,
                    right: 16,
                    child: Center(
                      child: FilledButton(
                        onPressed: !ready
                            ? null
                            : (busy ? cancelSearch : discover),
                        child: Text(
                          busy ? 'Cancel search' : 'Find my location / Retry',
                        ),
                      ),
                    ),
                  ),
                if (draftPose == null && target != null)
                  Positioned(
                    left: 16,
                    top: 190,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(target.name),
                            if (distance != null) ...[
                              Transform.rotate(
                                angle: relativeBearing(
                                  pose!,
                                  target.pose.getTranslation(),
                                ),
                                child: Icon(
                                  distance <= 1 && !localization.estimated
                                      ? Icons.check_circle
                                      : Icons.arrow_upward,
                                  size: 72,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                distance <= 1
                                    ? (localization.estimated
                                          ? 'Near destination (estimated)'
                                          : 'Arrived • ${distance.toStringAsFixed(1)} m')
                                    : '${distance.toStringAsFixed(1)} m',
                              ),
                            ] else
                              const Text('Guidance paused'),
                          ],
                        ),
                      ),
                    ),
                  ),
                if ((!mapFirst || arExpanded) &&
                    draftPose == null &&
                    roomName != null)
                  Positioned(
                    left: 16,
                    top: 190,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(roomName!),
                            if (guidance.next != null &&
                                pose != null &&
                                calibration != null)
                              Transform.rotate(
                                angle: relativeBearing(
                                  pose,
                                  Vector3(
                                    calibration.toMap(guidance.next!).dx,
                                    0,
                                    calibration.toMap(guidance.next!).dy,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_upward,
                                  size: 64,
                                  color: Colors.blue,
                                ),
                              ),
                            SizedBox(width: 220, child: Text(guidance.status)),
                            if (guidance.remainingMeters != null)
                              Text(
                                '${widget.appState?.distance(guidance.remainingMeters!) ?? '${guidance.remainingMeters!.round()} m'} remaining (estimated)',
                              ),
                            const Text(
                              'Draft hallway map',
                              style: TextStyle(color: Colors.deepOrange),
                            ),
                            TextButton(
                              onPressed: widget.session?.cancel ?? cancelTrip,
                              child: const Text('Stop navigation'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (draftPose != null)
                  Positioned(
                    top: 125,
                    left: 12,
                    right: 12,
                    child: ScanPanel(
                      scan: scan,
                      tracking: ar.tracking,
                      busy: busy,
                      onSave: ar.tracking && active && !busy ? saveDraft : null,
                      onCancel: busy ? null : () => updateState(discardDraft),
                    ),
                  ),
                if (identified && !mapFirst)
                  Positioned(
                    right: 12,
                    bottom: 90,
                    left: expanded ? 12 : null,
                    child: SizedBox(
                      width: expanded ? null : 190,
                      height: expanded
                          ? MediaQuery.sizeOf(context).height * .48
                          : 190,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 36,
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      map.floor.enabled
                                          ? 'Floor 1 • draft'
                                          : 'Map • up = −Z',
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () =>
                                        updateState(() => expanded = !expanded),
                                    icon: Icon(
                                      expanded
                                          ? Icons.close_fullscreen
                                          : Icons.open_in_full,
                                    ),
                                    tooltip: 'Expand map',
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  if (map.floor.enabled && floorGraph != null) {
                                    final p =
                                        pose == null || calibration == null
                                        ? null
                                        : calibration.toImage(
                                            Offset(
                                              pose.entry(0, 3),
                                              pose.entry(2, 3),
                                            ),
                                          );
                                    final h =
                                        pose == null || calibration == null
                                        ? null
                                        : calibration.toImage(
                                            Offset(
                                              pose.entry(0, 3) -
                                                  pose.entry(0, 2),
                                              pose.entry(2, 3) -
                                                  pose.entry(2, 2),
                                            ),
                                          );
                                    return FloorCanvas(
                                      graph: floorGraph!,
                                      setup: map.floor,
                                      camera: p,
                                      headingPoint: h,
                                      route: guidance.route?.points ?? [],
                                      showLabels: expanded,
                                    );
                                  }
                                  final size = Size(
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                  );
                                  final layout = MapLayout(
                                    map,
                                    pose,
                                    size,
                                  );
                                  return InteractiveViewer(
                                    minScale: 1,
                                    maxScale: 6,
                                    child: GestureDetector(
                                      onTapUp: (details) {
                                        SavedAnchor? closest;
                                        var best = 24.0;
                                        for (final a in map.anchors) {
                                          final d =
                                              (layout.point(a.pose) -
                                                      details.localPosition)
                                                  .distance;
                                          if (d < best) {
                                            best = d;
                                            closest = a;
                                          }
                                        }
                                        if (closest != null) {
                                          updateState(
                                            () {
                                              destination = closest;
                                              roomName = null;
                                              guidance.target = null;
                                              guidance.reset();
                                            },
                                          );
                                        }
                                      },
                                      child: CustomPaint(
                                        size: size,
                                        painter: BirdMapPainter(
                                          layout,
                                          destination,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (identified && !mapFirst)
                  Positioned(
                    bottom: 16,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FilledButton.icon(
                          onPressed: busy || draftPose != null
                              ? null
                              : showAnchors,
                          icon: const Icon(Icons.place),
                          label: const Text('Anchors'),
                        ),
                        FilledButton.icon(
                          onPressed: canPlace && draftPose == null
                              ? beginPlacement
                              : null,
                          icon: Icon(
                            placing ? Icons.close : Icons.add_location_alt,
                          ),
                          label: Text(placing ? 'Cancel' : 'Add anchor'),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          : const Center(
              child: Text(
                'This AR prototype requires an ARCore-compatible Android phone.',
              ),
            ),
    );
  }
}

class MapLayout {
  MapLayout(this.map, this.camera, this.size) {
    final positions = [
      ...map.anchors.map((a) => a.pose.getTranslation()),
      if (camera != null) camera!.getTranslation(),
    ];
    if (positions.isEmpty) return;
    var minX = positions.first.x,
        maxX = minX,
        minZ = positions.first.z,
        maxZ = minZ;
    for (final p in positions) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minZ = math.min(minZ, p.z);
      maxZ = math.max(maxZ, p.z);
    }
    cx = (minX + maxX) / 2;
    cz = (minZ + maxZ) / 2;
    scale = math.max(
      .001,
      math.min(
        math.max(1, size.width - 70) / math.max(4, maxX - minX),
        math.max(1, size.height - 50) / math.max(4, maxZ - minZ),
      ),
    );
  }
  final AnchorMap map;
  final Matrix4? camera;
  final Size size;
  double cx = 0, cz = 0, scale = 20;
  Offset point(Matrix4 pose) => Offset(
    size.width / 2 + (pose.entry(0, 3) - cx) * scale,
    size.height / 2 + (pose.entry(2, 3) - cz) * scale,
  );
}

class BirdMapPainter extends CustomPainter {
  BirdMapPainter(this.layout, this.destination);
  final MapLayout layout;
  final SavedAnchor? destination;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xffedf2f7),
    );
    for (final a in layout.map.anchors) {
      final p = layout.point(a.pose);
      canvas.drawCircle(
        p,
        a == destination ? 8 : 5,
        Paint()
          ..color = a == destination
              ? Colors.orange
              : (a.expired ? Colors.grey : Colors.teal),
      );
      final text = TextPainter(
        text: TextSpan(
          text: a.name,
          style: const TextStyle(color: Colors.black, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 90);
      text.paint(canvas, p + const Offset(8, -8));
    }
    final camera = layout.camera;
    if (camera != null) {
      final p = layout.point(camera), angle = heading(camera);
      canvas.drawLine(
        p,
        p + Offset(math.sin(angle) * 22, -math.cos(angle) * 22),
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 3,
      );
      canvas.drawCircle(p, 7, Paint()..color = Colors.blue);
      canvas.drawCircle(
        p,
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BirdMapPainter oldDelegate) => true;
}
