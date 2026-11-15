import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/morgridge_mock_data.dart';
import '../data/morgridge_graph_data.dart';
import '../models/navigation_models.dart';

class MadMapsState extends ChangeNotifier {
  MadMapsState() {
    _loadPreferences();
    loadGraph();
  }

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final FlutterTts _tts = FlutterTts();
  bool _disposed = false;

  List<String> savedPlaces = List.of(seededSavedPlaces);
  List<String> visitOrder = List.of(seededVisitHistory);
  bool wheelchairMode = false;
  bool blindMode = false;
  bool highContrast = false;
  bool voiceGuidance = false;
  bool cameraPromptSeen = false;
  bool simulatedCameraAllowed = false;
  bool useFeet = true;
  bool isNavigating = false;
  bool isWalking = false;
  bool walkStarted = false;
  bool arrived = false;
  bool floorPromptPending = false;
  int? floorPromptTarget;
  Map<String, String> savedAliases = {};
  MorgridgeGraphData? graph;
  List<Place> places = List.of(morgridgePlaces);
  bool arrivalNoticePending = false;
  int floor = 2;
  int routeIndex = 0;
  int stepIndex = 0;
  Place? destination;
  LocationFix? currentLocation;
  List<RouteOption> routes = const [];
  Timer? _walkTimer;

  Future<void> loadGraph() async {
    try {
      graph = await MorgridgeGraphData.load();
      places = graph!.places;
      if (places.isNotEmpty && !_disposed) notifyListeners();
    } catch (_) {
      // The bundled fallback keeps the prototype usable if assets are missing.
    }
  }

  List<String> get recentPlaces => _unique(visitOrder).take(4).toList();

  List<String> get frequentPlaces {
    final counts = <String, int>{};
    for (final name in visitOrder) {
      counts.update(name, (count) => count + 1, ifAbsent: () => 1);
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => (counts[b]!).compareTo(counts[a]!));
    return sorted.take(4).toList();
  }

  RouteOption? get activeRoute => routes.isEmpty ? null : routes[routeIndex];
  String? get nextInstruction {
    final steps = activeRoute?.steps;
    if (steps == null || stepIndex >= steps.length) return null;
    return steps[stepIndex].instruction;
  }

  String displayName(Place place) => savedAliases[place.name] ?? place.name;
  Place? placeByName(String name) {
    for (final place in places) {
      if (place.name == name) return place;
    }
    return null;
  }

  LocationFix resolveDescription(String description) =>
      graph?.resolveDescription(
        description,
        preferredFloor: floor,
      ) ??
      _fallbackDescription(description);

  LocationFix _fallbackDescription(String description) {
    final text = description.toLowerCase();
    final selectedFloor = text.contains('first') || text.contains('floor 1')
        ? 1
        : 2;
    if (text.contains('elevator'))
      return LocationFix(
        label: 'By the elevator · Floor $selectedFloor',
        floor: selectedFloor,
        point: selectedFloor == 1
            ? const Offset(.48, .63)
            : const Offset(.55, .53),
      );
    if (text.contains('learning') || text.contains('study'))
      return const LocationFix(
        label: 'Outside the Learning Center',
        floor: 2,
        point: Offset(.47, .24),
      );
    return LocationFix(
      label: 'Main hall · Floor $selectedFloor',
      floor: selectedFloor,
      point: selectedFloor == 1
          ? const Offset(.48, .63)
          : const Offset(.43, .53),
    );
  }

  bool matchesPlace(Place place, String query) =>
      '${place.name} ${place.room} ${place.subtitle} ${place.category} ${displayName(place)}'
          .toLowerCase()
          .contains(query.toLowerCase());
  int get remainingMinutes => activeRoute == null
      ? 0
      : (activeRoute!.minutes - stepIndex ~/ 2).clamp(0, activeRoute!.minutes);
  int get remainingFeet {
    final route = activeRoute;
    if (route == null || route.steps.length < 2) return 0;
    final progress = stepIndex / (route.steps.length - 1);
    return (route.distanceFeet * (1 - progress)).round().clamp(
      0,
      route.distanceFeet,
    );
  }

  String distanceLabel(int feet) =>
      useFeet ? '$feet ft' : '${(feet / 3.28084).round()} m';
  bool takeArrivalNotice() {
    if (!arrivalNoticePending) return false;
    arrivalNoticePending = false;
    return true;
  }

  Future<void> _loadPreferences() async {
    try {
      savedPlaces =
          await _preferences.getStringList('savedPlaces') ??
          List.of(seededSavedPlaces);
      visitOrder =
          await _preferences.getStringList('visitOrder') ??
          List.of(seededVisitHistory);
      wheelchairMode = await _preferences.getBool('wheelchairMode') ?? false;
      blindMode = await _preferences.getBool('blindMode') ?? false;
      highContrast = await _preferences.getBool('highContrast') ?? false;
      voiceGuidance = await _preferences.getBool('voiceGuidance') ?? blindMode;
      cameraPromptSeen =
          await _preferences.getBool('cameraPromptSeen') ?? false;
      simulatedCameraAllowed =
          await _preferences.getBool('simulatedCameraAllowed') ?? false;
      useFeet = await _preferences.getBool('useFeet') ?? true;
      final aliasesJson = await _preferences.getString('savedAliases');
      if (aliasesJson != null) {
        savedAliases = Map<String, String>.from(jsonDecode(aliasesJson) as Map);
      }
    } catch (_) {
      // Keep useful in-memory defaults if local storage is unavailable.
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> _saveStringList(String key, List<String> value) async {
    try {
      await _preferences.setStringList(key, value);
    } catch (_) {
      // This prototype remains usable for the current session if storage fails.
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      await _preferences.setBool(key, value);
    } catch (_) {
      // This prototype remains usable for the current session if storage fails.
    }
  }

  void toggleSaved(Place place) {
    if (savedPlaces.contains(place.name)) {
      savedPlaces.remove(place.name);
    } else {
      savedPlaces.insert(0, place.name);
    }
    _saveStringList('savedPlaces', savedPlaces);
    notifyListeners();
  }

  void removeSaved(String name) {
    savedPlaces.remove(name);
    _saveStringList('savedPlaces', savedPlaces);
    notifyListeners();
  }

  void renameSavedPlace(String canonicalName, String newName) {
    final value = newName.trim();
    if (value.isEmpty) return;
    if (value == canonicalName) {
      savedAliases.remove(canonicalName);
    } else {
      savedAliases[canonicalName] = value;
    }
    _saveAliases();
    notifyListeners();
  }

  Future<void> _saveAliases() async {
    try {
      await _preferences.setString('savedAliases', jsonEncode(savedAliases));
    } catch (_) {}
  }

  void setWheelchairMode(bool value) {
    wheelchairMode = value;
    _refreshRoutes();
    _saveBool('wheelchairMode', value);
    notifyListeners();
  }

  void setBlindMode(bool value) {
    blindMode = value;
    if (value) voiceGuidance = true;
    _saveBool('blindMode', value);
    _saveBool('voiceGuidance', voiceGuidance);
    if (value && nextInstruction != null) speak(nextInstruction!);
    notifyListeners();
  }

  void setHighContrast(bool value) {
    highContrast = value;
    _saveBool('highContrast', value);
    notifyListeners();
  }

  void setVoiceGuidance(bool value) {
    voiceGuidance = value;
    _saveBool('voiceGuidance', value);
    if (!value) _tts.stop();
    notifyListeners();
  }

  void setUseFeet(bool value) {
    useFeet = value;
    _saveBool('useFeet', value);
    notifyListeners();
  }

  Future<void> setCameraChoice(bool allowed) async {
    cameraPromptSeen = true;
    simulatedCameraAllowed = allowed;
    await _saveBool('cameraPromptSeen', true);
    await _saveBool('simulatedCameraAllowed', allowed);
    notifyListeners();
  }

  void setDestination(Place place) {
    destination = place;
    routes = currentLocation == null
        ? const []
        : _buildRoutes(currentLocation!, place);
    routeIndex = 0;
    isNavigating = currentLocation != null;
    isWalking = false;
    walkStarted = false;
    arrived = false;
    floorPromptPending = false;
    floorPromptTarget = null;
    stepIndex = 0;
    floor = currentLocation?.floor ?? place.floor;
    notifyListeners();
  }

  void setCurrentLocation(LocationFix location) {
    final wasWalking = isWalking;
    final previousRoute = routeIndex;
    final previousStep = stepIndex;
    currentLocation = location;
    if (destination != null) {
      routes = _buildRoutes(location, destination!);
      routeIndex = previousRoute.clamp(0, routes.length - 1);
      stepIndex = walkStarted
          ? previousStep.clamp(0, routes[routeIndex].steps.length - 1)
          : 0;
      isNavigating = true;
      isWalking = wasWalking;
      floor = location.floor;
    }
    floorPromptPending = false;
    floorPromptTarget = null;
    notifyListeners();
    if (voiceGuidance && nextInstruction != null) speak(nextInstruction!);
  }

  void selectRoute(int index) {
    if (index < 0 || index >= routes.length) return;
    _walkTimer?.cancel();
    isWalking = false;
    routeIndex = index;
    stepIndex = 0;
    notifyListeners();
    if (voiceGuidance && nextInstruction != null) speak(nextInstruction!);
  }

  void setFloor(int value) {
    floor = value;
    notifyListeners();
  }

  void startWalking() {
    if (activeRoute == null || isWalking) return;
    _walkTimer?.cancel();
    isWalking = true;
    walkStarted = true;
    arrived = false;
    notifyListeners();
    _announceCurrentStep();
    _walkTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final route = activeRoute;
      if (route == null) {
        timer.cancel();
        return;
      }
      if (stepIndex + 1 >= route.steps.length) {
        timer.cancel();
        isWalking = false;
        arrived = remainingFeet <= 5;
        arrivalNoticePending = arrived;
        if (destination != null) _recordVisit(destination!.name);
        notifyListeners();
        return;
      }
      stepIndex++;
      final transition = route.steps[stepIndex].transitionToFloor;
      if (transition != null) {
        floor = transition;
        floorPromptTarget = transition;
        floorPromptPending = true;
      }
      final segment = route.floorSegments[floor];
      if (segment != null && segment.isNotEmpty) {
        final point = segment[(stepIndex).clamp(0, segment.length - 1)];
        currentLocation = LocationFix(
          label: 'Following route · Floor $floor',
          floor: floor,
          point: point,
        );
      }
      notifyListeners();
      _announceCurrentStep();
    });
  }

  void dismissFloorPrompt() {
    floorPromptPending = false;
    floorPromptTarget = null;
    notifyListeners();
  }

  void stopWalking() {
    _walkTimer?.cancel();
    isWalking = false;
    notifyListeners();
  }

  void endNavigation() {
    _walkTimer?.cancel();
    destination = null;
    currentLocation = null;
    routes = const [];
    routeIndex = 0;
    stepIndex = 0;
    isNavigating = false;
    isWalking = false;
    walkStarted = false;
    arrived = false;
    floorPromptPending = false;
    floorPromptTarget = null;
    _tts.stop();
    notifyListeners();
  }

  void _refreshRoutes() {
    if (destination == null || currentLocation == null) return;
    routes = _buildRoutes(currentLocation!, destination!);
    routeIndex = 0;
    stepIndex = 0;
  }

  List<RouteOption> _buildRoutes(LocationFix origin, Place destination) {
    final path = graph?.findPath(origin, destination);
    if (path == null) {
      return buildMockRoutes(
        stepFree: wheelchairMode,
        originFloor: origin.floor,
        destinationFloor: destination.floor,
        originPoint: origin.point,
        destinationPoint: destination.point,
      );
    }
    final steps = <NavigationStep>[
      for (var index = 0; index < path.points.length; index++)
        NavigationStep(
          index == path.points.length - 1
              ? 'You have arrived'
              : index == 0
              ? 'Start along the mapped hallway'
              : 'Continue along the hallway',
          floor: origin.floor,
        ),
    ];
    final route = RouteOption(
      name: 'Quickest',
      minutes: (path.distanceFeet / 240).ceil().clamp(1, 30),
      distanceFeet: path.distanceFeet,
      stepFree: false,
      points: path.points,
      floorSegments: {origin.floor: path.points},
      steps: steps,
    );
    final accessible = RouteOption(
      name: 'Step-free',
      minutes: route.minutes + 1,
      distanceFeet: route.distanceFeet,
      stepFree: true,
      points: route.points,
      floorSegments: route.floorSegments,
      steps: route.steps,
    );
    return wheelchairMode ? [accessible] : [route, accessible];
  }

  void _recordVisit(String name) {
    visitOrder.insert(0, name);
    if (visitOrder.length > 24) visitOrder = visitOrder.take(24).toList();
    _saveStringList('visitOrder', visitOrder);
  }

  List<String> _unique(List<String> values) => values.toSet().toList();

  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (_) {
      // Text instructions remain visible if platform speech is unavailable.
    }
  }

  void _announceCurrentStep() {
    final instruction = nextInstruction;
    if (voiceGuidance && instruction != null) speak(instruction);
  }

  @override
  void dispose() {
    _disposed = true;
    _walkTimer?.cancel();
    _tts.stop();
    super.dispose();
  }
}
